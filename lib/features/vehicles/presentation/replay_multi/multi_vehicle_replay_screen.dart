import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../reports/presentation/providers/replay_controller.dart';
import 'multi_replay_comparison_sheet.dart';
import 'multi_replay_kpi.dart';
import 'multi_vehicle_replay_controller.dart';
import 'multi_vehicle_replay_formatters.dart';
import 'multi_vehicle_replay_map_helpers.dart';
import 'multi_vehicle_replay_marker_icons.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_polylines.dart';
import 'multi_vehicle_replay_provider.dart';
import 'multi_vehicle_replay_route_args.dart';
import 'multi_vehicle_replay_state.dart';
import 'multi_vehicle_replay_ui.dart';
import 'multi_vehicle_replay_widgets.dart';
import '../../../map/core/map_audit_logger.dart';

/// Opens multi-vehicle replay when [vehicleIds] count is 2–5.
void openMultiVehicleReplay(
  BuildContext context, {
  required List<String> vehicleIds,
  DateTime? date,
}) {
  final count = vehicleIds.length;
  AppLogger.replay('multi_replay_opened count=$count');
  context.push(
    '/vehicles/replay-multi',
    extra: MultiVehicleReplayRouteArgs(
      vehicleIds: vehicleIds,
      date: date,
    ),
  );
}

class MultiVehicleReplayScreen extends ConsumerStatefulWidget {
  const MultiVehicleReplayScreen({
    super.key,
    required this.vehicleIds,
    this.initialDate,
  });

  final List<String> vehicleIds;
  final DateTime? initialDate;

  @override
  ConsumerState<MultiVehicleReplayScreen> createState() =>
      _MultiVehicleReplayScreenState();
}

class _MultiVehicleReplayScreenState
    extends ConsumerState<MultiVehicleReplayScreen> {
  late DateTime _selectedDate;
  GoogleMapController? _mapController;
  bool _mapReady = false;
  bool _hasFitted = false;
  bool _timelineLoaded = false;
  int _lastFollowIndex = -1;
  DateTime? _lastFollowAt;
  final MultiVehicleReplayMarkerIcons _markerIcons =
      MultiVehicleReplayMarkerIcons();

  /// Cached in [initState] — do not use [ref] in [dispose] (Riverpod guard).
  late final MultiVehicleReplayController _playback;

  @override
  void initState() {
    super.initState();
    MapAuditLogger.screenOpened(
      'MultiVehicleReplay',
      extra: 'count=${widget.vehicleIds.length}',
    );
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedDate = MultiVehicleReplayFormatters.startOfDay(_selectedDate);
    _playback = ref.read(multiVehicleReplayControllerProvider.notifier);
  }

  MultiVehicleReplayRequest get _request => MultiVehicleReplayRequest(
        vehicleIds: widget.vehicleIds,
        date: _selectedDate,
      );

  void _resetReplaySession() {
    _timelineLoaded = false;
    _hasFitted = false;
    _lastFollowIndex = -1;
    _lastFollowAt = null;
    _markerIcons.clear();
    ref.read(multiVehicleReplayControllerProvider.notifier).reset();
  }

  Future<void> _loadMarkerIcons(
    MultiVehicleReplayLoadState load,
    bool withLabels,
  ) async {
    if (!mounted) return;
    await _markerIcons.loadForTracks(
      load.tracks,
      withLabels: withLabels,
    );
    if (!mounted) return;
    setState(() {});
  }

  void _onLoadSuccess(MultiVehicleReplayLoadState load) {
    final timeline = load.timeline;
    if (timeline == null || _timelineLoaded) return;
    if (!mounted) return;
    setState(() => _timelineLoaded = true);
    ref.read(multiVehicleReplayControllerProvider.notifier).loadTimeline(
          timeline,
        );
    final withLabels =
        ref.read(multiVehicleReplayControllerProvider).showMapLabels;
    _loadMarkerIcons(load, withLabels);
    if (_mapReady && !_hasFitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitBounds(
          load,
          ref.read(multiVehicleReplayControllerProvider),
          force: true,
        );
      });
    }
  }

  Set<Polyline> _buildPolylines(
    List<MultiVehicleReplayTrack> tracks,
    MultiVehicleReplayPlaybackState playback,
  ) =>
      MultiVehicleReplayPolylines.build(
        tracks: tracks,
        isVisible: playback.vehicleVisible,
        useSpeedColors: playback.useSpeedColors,
      );

  Set<Marker> _buildMarkers(
    MultiVehicleReplayPlaybackState playback,
    MultiVehicleReplayLoadState load,
  ) {
    final timeline = playback.timeline;
    if (timeline == null) return {};
    final time = playback.currentTime;
    if (time == null) return {};

    final atTime = timeline.markersAtTime(time);
    final markers = <Marker>{};
    final withLabels = playback.showMapLabels;

    for (final track in load.tracks) {
      if (!playback.vehicleVisible(track.vehicleId)) continue;
      final pt = atTime[track.vehicleId];
      if (pt == null) continue;

      final isActive = playback.activeVehicleId == track.vehicleId;
      final icon = _markerIcons.iconFor(
            track.colorIndex,
            withLabels: withLabels,
          ) ??
          BitmapDescriptor.defaultMarkerWithHue(
            MultiVehicleReplayMarkerIcons.fallbackHueForIndex(track.colorIndex),
          );

      final rotate = !withLabels &&
          MultiVehicleReplayUi.shouldRotateMarker(
            speedKmh: pt.speed,
            course: pt.course,
          );

      markers.add(
        Marker(
          markerId: MarkerId('mv_${track.vehicleId}'),
          position: pt.position,
          rotation: rotate ? pt.course : 0,
          flat: rotate,
          anchor: const Offset(0.5, 0.5),
          icon: icon,
          zIndexInt: isActive ? 20 : track.colorIndex + 1,
        ),
      );
    }
    return markers;
  }

  void _fitBounds(
    MultiVehicleReplayLoadState load,
    MultiVehicleReplayPlaybackState playback, {
    bool force = false,
  }) {
    if (_mapController == null) return;
    if (!force && _hasFitted && !playback.autoFollow) return;

    final time = playback.currentTime;
    final markersAtTime = time == null || playback.timeline == null
        ? null
        : playback.timeline!.markersAtTime(time);

    final positions = MultiVehicleReplayMapHelpers.positionsForFit(
      tracks: load.tracks,
      isVisible: playback.vehicleVisible,
      markersAtCurrentTime: markersAtTime,
      preferMarkersOnly: playback.autoFollow && time != null,
    );

    if (positions.isEmpty) {
      if (!force) return;
      return;
    }

    if (force || !playback.autoFollow) {
      _hasFitted = true;
    }

    final update = MultiVehicleReplayMapHelpers.cameraUpdateForFit(positions);
    if (update == null) return;
    _mapController!.animateCamera(update);
  }

  void _maybeAutoFollow(
    MultiVehicleReplayLoadState load,
    MultiVehicleReplayPlaybackState playback,
  ) {
    if (!playback.autoFollow || _mapController == null) return;
    if (!playback.isPlaying && _lastFollowIndex == playback.currentIndex) {
      return;
    }

    final now = DateTime.now();
    final throttled = _lastFollowAt != null &&
        now.difference(_lastFollowAt!) <
            MultiVehicleReplayMapHelpers.autoFollowThrottle;
    final index = playback.currentIndex;
    if (throttled && index == _lastFollowIndex) return;

    _lastFollowIndex = index;
    _lastFollowAt = now;
    _fitBounds(load, playback, force: true);
  }

  void _onRecenter(
    MultiVehicleReplayLoadState load,
    MultiVehicleReplayPlaybackState playback,
  ) {
    AppLogger.replay('replay_recenter');
    _hasFitted = false;
    _fitBounds(load, playback, force: true);
  }

  Future<void> _onToggleLabels(MultiVehicleReplayLoadState load) async {
    final controller =
        ref.read(multiVehicleReplayControllerProvider.notifier);
    final next = !ref.read(multiVehicleReplayControllerProvider).showMapLabels;
    controller.setShowMapLabels(next);
    AppLogger.replay('replay_labels_toggled enabled=$next');
    await _loadMarkerIcons(load, next);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MapAuditLogger.screenDisposed(
      'MultiVehicleReplay',
      timers: 'playback',
    );
    // Do not call [pause] here — updating provider state during unmount breaks tests.
    _playback.stopTimerOnly();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final l10n = context.l10n;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: l10n.chooseReplayDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = MultiVehicleReplayFormatters.startOfDay(picked);
    });
    _resetReplaySession();
    ref.invalidate(multiVehicleReplayLoaderProvider(_request));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loadAsync = ref.watch(multiVehicleReplayLoaderProvider(_request));
    final playback = ref.watch(multiVehicleReplayControllerProvider);

    ref.listen(multiVehicleReplayLoaderProvider(_request), (prev, next) {
      if (!mounted) return;
      next.whenData((load) {
        if (load.status == MultiVehicleReplayLoadStatus.success) {
          _onLoadSuccess(load);
        }
      });
    });

    ref.listen<int>(
      multiVehicleReplayControllerProvider.select((s) => s.currentIndex),
      (prev, next) {
        if (!mounted || prev == next) return;
        final load = loadAsync.valueOrNull;
        if (load == null || load.status != MultiVehicleReplayLoadStatus.success) {
          return;
        }
        _maybeAutoFollow(
          load,
          ref.read(multiVehicleReplayControllerProvider),
        );
      },
    );

    ref.listen<bool>(
      multiVehicleReplayControllerProvider.select((s) => s.autoFollow),
      (prev, next) {
        if (!mounted || prev == next || !next) return;
        final load = loadAsync.valueOrNull;
        if (load == null) return;
        _hasFitted = false;
        _maybeAutoFollow(
          load,
          ref.read(multiVehicleReplayControllerProvider),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.multiVehicleReplayTitle),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              MultiVehicleReplayFormatters.isSameCalendarDay(
                _selectedDate,
                DateTime.now(),
              )
                  ? l10n.replayToday
                  : MultiVehicleReplayFormatters.formatDayLabel(
                      _selectedDate,
                      isToday: false,
                    ),
            ),
          ),
        ],
      ),
      body: loadAsync.when(
        loading: () => LoadingView(message: l10n.multiReplayLoading),
        error: (e, _) => MultiVehicleReplayEmptyBody(
          message: l10n.multiReplayLoadFailed,
          showRetry: true,
          onRetry: () {
            _resetReplaySession();
            ref.invalidate(multiVehicleReplayLoaderProvider(_request));
          },
        ),
        data: (load) => _buildBody(context, l10n, load, playback),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    MultiVehicleReplayLoadState load,
    MultiVehicleReplayPlaybackState playback,
  ) {
    switch (load.status) {
      case MultiVehicleReplayLoadStatus.invalidSelection:
        return MultiVehicleReplayEmptyBody(
          message: load.invalidReason == 'too_many'
              ? l10n.multiReplayLimitMessage
              : l10n.selectAtLeastTwoVehiclesReplay,
        );
      case MultiVehicleReplayLoadStatus.error:
        return MultiVehicleReplayEmptyBody(
          message: l10n.multiReplayLoadFailed,
          showRetry: true,
          onRetry: () {
            _resetReplaySession();
            ref.invalidate(multiVehicleReplayLoaderProvider(_request));
          },
        );
      case MultiVehicleReplayLoadStatus.empty:
        return MultiVehicleReplayEmptyBody(message: l10n.multiReplayNoData);
      case MultiVehicleReplayLoadStatus.loading:
        return LoadingView(message: l10n.multiReplayLoading);
      case MultiVehicleReplayLoadStatus.success:
        if (!load.hasAnyRouteData) {
          return MultiVehicleReplayEmptyBody(message: l10n.multiReplayNoData);
        }
        return _ReplayMapBody(
          load: load,
          playback: playback,
          polylines: _buildPolylines(load.tracks, playback),
          markers: _buildMarkers(playback, load),
          onMapCreated: (c) {
            _mapController = c;
            _mapReady = true;
            if (!_hasFitted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _fitBounds(load, playback, force: true);
              });
            }
          },
          onRecenter: () => _onRecenter(load, playback),
          onPlay: () {
            AppLogger.replay('multi_replay_play');
            ref.read(multiVehicleReplayControllerProvider.notifier).play();
          },
          onPause: () {
            AppLogger.replay('multi_replay_pause');
            ref.read(multiVehicleReplayControllerProvider.notifier).pause();
          },
          onReset: () {
            ref.read(multiVehicleReplayControllerProvider.notifier).reset();
            _hasFitted = false;
            _fitBounds(load, playback, force: true);
          },
          onSeek: (p) => ref
              .read(multiVehicleReplayControllerProvider.notifier)
              .seekToProgress(p),
          onSpeed: (s) {
            AppLogger.replay('multi_replay_speed_changed speed=${s.label}');
            ref
                .read(multiVehicleReplayControllerProvider.notifier)
                .setPlaybackSpeed(s);
          },
          onVisibility: (id, visible) {
            AppLogger.replay(
              'multi_replay_vehicle_visibility_changed '
              'vehicleId=$id visible=$visible',
            );
            ref
                .read(multiVehicleReplayControllerProvider.notifier)
                .setVehicleVisible(id, visible);
            if (mounted) {
              setState(() {});
              _fitBounds(load, ref.read(multiVehicleReplayControllerProvider),
                  force: true);
            }
          },
          onActiveVehicle: (id) {
            ref
                .read(multiVehicleReplayControllerProvider.notifier)
                .setActiveVehicle(id);
            if (mounted) setState(() {});
          },
          onToggleLabels: () => _onToggleLabels(load),
          onToggleAutoFollow: () {
            final c = ref.read(multiVehicleReplayControllerProvider.notifier);
            final next =
                !ref.read(multiVehicleReplayControllerProvider).autoFollow;
            c.setAutoFollow(next);
            AppLogger.replay('multi_replay_autofollow enabled=$next');
            if (next) {
              _hasFitted = false;
              _maybeAutoFollow(
                load,
                ref.read(multiVehicleReplayControllerProvider),
              );
            }
          },
          onToggleSpeedColors: () {
            final c = ref.read(multiVehicleReplayControllerProvider.notifier);
            final next = !ref
                .read(multiVehicleReplayControllerProvider)
                .useSpeedColors;
            c.setUseSpeedColors(next);
            if (mounted) setState(() {});
          },
          comparisonSummary: load.comparisonSummary,
        );
    }
  }
}

class _ReplayMapBody extends StatelessWidget {
  const _ReplayMapBody({
    required this.load,
    required this.playback,
    required this.polylines,
    required this.markers,
    required this.onMapCreated,
    required this.onRecenter,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    required this.onSeek,
    required this.onSpeed,
    required this.onVisibility,
    required this.onActiveVehicle,
    required this.onToggleLabels,
    required this.onToggleAutoFollow,
    required this.onToggleSpeedColors,
    required this.comparisonSummary,
  });

  final MultiVehicleReplayLoadState load;
  final MultiVehicleReplayPlaybackState playback;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onRecenter;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final ValueChanged<double> onSeek;
  final ValueChanged<PlaybackSpeed> onSpeed;
  final void Function(String vehicleId, bool visible) onVisibility;
  final ValueChanged<String> onActiveVehicle;
  final VoidCallback onToggleLabels;
  final VoidCallback onToggleAutoFollow;
  final VoidCallback onToggleSpeedColors;
  final MultiReplayComparisonSummary? comparisonSummary;

  void _openComparison(BuildContext context) {
    final summary = comparisonSummary;
    if (summary == null) return;
    AppLogger.replay('multi_replay_comparison_opened');
    MultiReplayComparisonSheet.show(
      context,
      summary: summary,
      tracks: load.tracks,
      playback: playback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timeline = playback.timeline;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: MapConfig.defaultCameraPosition,
                polylines: polylines,
                markers: markers,
                style: isDark ? MapConfig.darkStyle : MapConfig.lightStyle,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: onMapCreated,
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    MultiVehicleReplayTimeCard(
                      currentTime: playback.currentTime,
                      playbackSpeed: playback.playbackSpeed,
                      isPlaying: playback.isPlaying,
                    ),
                    const Spacer(),
                    if (comparisonSummary != null)
                      _MapToolChip(
                        icon: Icons.compare_arrows_rounded,
                        tooltip: l10n.multiReplayComparison,
                        selected: false,
                        onPressed: () => _openComparison(context),
                      ),
                    if (comparisonSummary != null) const SizedBox(width: 6),
                    _MapToolChip(
                      icon: playback.autoFollow
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      tooltip: l10n.multiReplayAutoFollow,
                      selected: playback.autoFollow,
                      onPressed: onToggleAutoFollow,
                    ),
                    const SizedBox(width: 6),
                    _MapToolChip(
                      icon: Icons.speed_rounded,
                      tooltip: l10n.multiReplaySpeedColors,
                      selected: playback.useSpeedColors,
                      onPressed: onToggleSpeedColors,
                    ),
                    const SizedBox(width: 6),
                    MultiVehicleReplayRecenterButton(
                      onPressed: onRecenter,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        MultiVehicleReplayLegend(
          tracks: load.tracks,
          playback: playback,
          timeline: timeline,
          onVisibility: onVisibility,
          onActiveVehicle: onActiveVehicle,
          labelsEnabled: playback.showMapLabels,
          onToggleLabels: onToggleLabels,
        ),
        MultiVehicleReplayControlsBar(
          playback: playback,
          timeline: timeline,
          onPlay: onPlay,
          onPause: onPause,
          onReset: onReset,
          onSeek: onSeek,
          onSpeed: onSpeed,
          l10n: l10n,
        ),
      ],
    );
  }
}

class _MapToolChip extends StatelessWidget {
  const _MapToolChip({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.95)
          : scheme.surface.withValues(alpha: 0.94),
      child: IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
