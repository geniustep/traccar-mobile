import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../reports/presentation/providers/replay_controller.dart';
import 'multi_vehicle_replay_controller.dart';
import 'multi_vehicle_replay_formatters.dart';
import 'multi_vehicle_replay_marker_icons.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_provider.dart';
import 'multi_vehicle_replay_route_args.dart';
import 'multi_vehicle_replay_state.dart';
import 'multi_vehicle_replay_ui.dart';
import 'multi_vehicle_replay_widgets.dart';

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
  final MultiVehicleReplayMarkerIcons _markerIcons =
      MultiVehicleReplayMarkerIcons();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedDate = MultiVehicleReplayFormatters.startOfDay(_selectedDate);
  }

  MultiVehicleReplayRequest get _request => MultiVehicleReplayRequest(
        vehicleIds: widget.vehicleIds,
        date: _selectedDate,
      );

  void _resetReplaySession() {
    _timelineLoaded = false;
    _hasFitted = false;
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
        _fitBounds(
          load,
          ref.read(multiVehicleReplayControllerProvider),
        );
      });
    }
  }

  Set<Polyline> _buildPolylines(
    List<MultiVehicleReplayTrack> tracks,
    MultiVehicleReplayPlaybackState playback,
  ) {
    return tracks
        .where(
          (t) =>
              t.mapPoints.length >= 2 &&
              playback.vehicleVisible(t.vehicleId),
        )
        .map(
          (t) => Polyline(
            polylineId: PolylineId('route_${t.vehicleId}'),
            points: t.mapPoints.map((p) => p.position).toList(),
            color: t.color,
            width: 4,
            geodesic: true,
          ),
        )
        .toSet();
  }

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
          anchor: withLabels
              ? const Offset(0.5, 0.5)
              : const Offset(0.5, 0.5),
          icon: icon,
          zIndexInt: track.colorIndex + 1,
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
    final positions = <LatLng>[];
    for (final t in load.tracks) {
      if (!playback.vehicleVisible(t.vehicleId)) continue;
      for (final p in t.mapPoints) {
        positions.add(p.position);
      }
    }
    if (positions.isEmpty || _mapController == null) return;
    if (!force && _hasFitted) return;
    _hasFitted = true;

    if (positions.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 14),
      );
      return;
    }

    var minLat = positions.first.latitude;
    var maxLat = minLat;
    var minLng = positions.first.longitude;
    var maxLng = minLng;

    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    try {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          64,
        ),
      );
    } catch (_) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 12),
      );
    }
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
    ref.read(multiVehicleReplayControllerProvider.notifier).pause();
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
      next.whenData((load) {
        if (load.status == MultiVehicleReplayLoadStatus.success) {
          _onLoadSuccess(load);
        }
      });
    });

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
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _fitBounds(load, playback),
              );
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
          },
          onToggleLabels: () => _onToggleLabels(load),
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
    required this.onToggleLabels,
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
  final VoidCallback onToggleLabels;

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
          onVisibility: onVisibility,
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
