import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/route_event_models.dart';
import '../../core/route_event_timeline_models.dart';

/// Chronological list of route intelligence events — shared by tracking / report / replay.
class RouteEventTimeline extends StatefulWidget {
  const RouteEventTimeline({
    super.key,
    required this.analysisKey,
    this.analysis,
    this.onItemTap,
    this.compact = false,
    this.reportStyle = false,
    this.showEmptyState = true,
    this.collapsedItemLimit,
    this.listHeightOverride,
    this.selectedItemKey,
    this.filter = RouteEventTimelineFilter.all,
    this.onFilterChanged,
    this.showFilters = true,
    this.supplementalTimelineItems = const [],
  });

  /// Memo key aligned with RouteEventAnalyzer (e.g. length_first_fix_last_fix); `'0'` = no trace.
  final String analysisKey;
  final RouteEventAnalysisResult? analysis;
  final ValueChanged<RouteEventTimelineItem>? onItemTap;

  /// Highlights the row matching [RouteEventTimelineItem.selectionKey] (Phase 7C).
  final String? selectedItemKey;

  /// Phase 7E — filter applied to displayed rows only (no re-analysis).
  final RouteEventTimelineFilter filter;
  final ValueChanged<RouteEventTimelineFilter>? onFilterChanged;
  final bool showFilters;

  /// Tighter layout and shorter list defaults (e.g. live tracking drawer).
  final bool compact;

  /// Report / replay styling (slightly taller list defaults).
  final bool reportStyle;

  /// When items are empty, show subtle placeholder when [showEmptyState] is true.
  final bool showEmptyState;

  /// Max rows before "see more"; defaults from [compact] / [reportStyle].
  final int? collapsedItemLimit;

  /// Optional fixed scroll area height (e.g. compact replay panel).
  final double? listHeightOverride;

  /// Extra rows merged with analyzer items (e.g. replay data gaps — Phase R1).
  final List<RouteEventTimelineItem> supplementalTimelineItems;

  /// Use with [GoogleMapController.animateCamera] when focusing an event row.
  static const double focusZoomHint = 16;

  static IconData iconForKind(RouteTimelineEntryKind k) => switch (k) {
        RouteTimelineEntryKind.stop => Icons.local_parking_rounded,
        RouteTimelineEntryKind.overspeed => Icons.speed_rounded,
        RouteTimelineEntryKind.ignitionOn => Icons.power_rounded,
        RouteTimelineEntryKind.ignitionOff => Icons.power_off_outlined,
        RouteTimelineEntryKind.dataGap => Icons.signal_cellular_connected_no_internet_0_bar_rounded,
      };

  static Color accentForKind(RouteTimelineEntryKind k, BuildContext context) =>
      switch (k) {
        RouteTimelineEntryKind.stop => const Color(0xFFFFC107),
        RouteTimelineEntryKind.overspeed => AppColors.error,
        RouteTimelineEntryKind.ignitionOn => Colors.green.shade600,
        RouteTimelineEntryKind.ignitionOff => const Color(0xFFFF9800),
        RouteTimelineEntryKind.dataGap => AppColors.textMutedOf(context),
      };

  @override
  State<RouteEventTimeline> createState() => _RouteEventTimelineState();
}

class _RouteEventTimelineState extends State<RouteEventTimeline> {
  String? _itemsKey;
  List<RouteEventTimelineItem>? _items;
  bool _expanded = false;

  void _ensureItems(AppLocalizations l10n) {
    final ak =
        '${widget.analysisKey}_${l10n.locale.languageCode}_${identityHashCode(widget.analysis)}';
    final a = widget.analysis;
    if (ak == _itemsKey && _items != null) return;
    _itemsKey = ak;
    final base = (a == null || widget.analysisKey == '0')
        ? <RouteEventTimelineItem>[]
        : buildRouteEventTimelineItems(a, l10n);
    _items = mergeRouteEventTimelineItems(
      base,
      widget.supplementalTimelineItems,
    );
    if (_items!.isEmpty) _expanded = false;
  }

  int get _effectiveLimit =>
      widget.collapsedItemLimit ??
      (widget.compact ? 6 : (widget.reportStyle ? 12 : 8));

  double get _listHeight =>
      widget.listHeightOverride ??
      (widget.compact ? 168 : (widget.reportStyle ? 236 : 200));

  @override
  void didUpdateWidget(covariant RouteEventTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysisKey != widget.analysisKey ||
        !identical(oldWidget.analysis, widget.analysis) ||
        oldWidget.supplementalTimelineItems != widget.supplementalTimelineItems) {
      _itemsKey = null;
      _items = null;
      _expanded = false;
    } else if (oldWidget.filter != widget.filter) {
      _expanded = false;
    }
  }

  Widget _filterChip({
    required AppLocalizations l10n,
    required String label,
    required int count,
    required RouteEventTimelineFilter f,
    required double fontSize,
  }) {
    final selected = widget.filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 5 : 7,
          vertical: 0,
        ),
        onSelected: (v) {
          if (v) widget.onFilterChanged!(f);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _ensureItems(l10n);

    final items = _items ?? const <RouteEventTimelineItem>[];
    final filtered = routeEventTimelineItemsFiltered(items, widget.filter);
    final counts = routeEventTimelineFilterCounts(items);
    final showFilterRow = widget.showFilters &&
        widget.onFilterChanged != null &&
        items.isNotEmpty;

    final titleStyle = AppTextStyles.labelSmall.copyWith(
      fontSize: widget.compact ? 10 : 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondaryOf(context),
    );

    final limit = _effectiveLimit;
    final hasMore = filtered.length > limit;
    final visible =
        !hasMore || _expanded ? filtered : filtered.sublist(0, limit);

    final chipFont = widget.compact ? 9.5 : 10.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline_rounded,
              size: widget.compact ? 14 : 15,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(width: 6),
            Text(l10n.routeEventsTimelineTitle, style: titleStyle),
          ],
        ),
        SizedBox(height: widget.compact ? 6 : 8),
        if (showFilterRow) ...[
          SizedBox(
            height: widget.compact ? 30 : 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(
                  l10n: l10n,
                  label: l10n.routeEventFilterAll,
                  count: counts.all,
                  f: RouteEventTimelineFilter.all,
                  fontSize: chipFont,
                ),
                _filterChip(
                  l10n: l10n,
                  label: l10n.routeEventFilterStops,
                  count: counts.stops,
                  f: RouteEventTimelineFilter.stops,
                  fontSize: chipFont,
                ),
                _filterChip(
                  l10n: l10n,
                  label: l10n.routeEventFilterOverspeed,
                  count: counts.overspeed,
                  f: RouteEventTimelineFilter.overspeed,
                  fontSize: chipFont,
                ),
                _filterChip(
                  l10n: l10n,
                  label: l10n.routeEventFilterIgnition,
                  count: counts.ignition,
                  f: RouteEventTimelineFilter.ignition,
                  fontSize: chipFont,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (items.isEmpty) ...[
          if (widget.showEmptyState &&
              widget.analysis != null &&
              widget.analysisKey != '0')
            Text(
              l10n.routeEventsNoneDetected,
              style: TextStyle(
                fontSize: widget.compact ? 10 : 11,
                color: AppColors.textMutedOf(context),
              ),
            ),
        ] else if (filtered.isEmpty) ...[
          Text(
            l10n.routeEventsFilterNoMatches,
            style: TextStyle(
              fontSize: widget.compact ? 10 : 11,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ] else ...[
          SizedBox(
            height: _listHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Material(
                color: AppColors.surfaceElevatedOf(context),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final row = visible[i];
                    final accent =
                        RouteEventTimeline.accentForKind(row.kind, context);
                    final icon = RouteEventTimeline.iconForKind(row.kind);
                    final selected = widget.selectedItemKey != null &&
                        row.selectionKey == widget.selectedItemKey;
                    return InkWell(
                      onTap: widget.onItemTap == null
                          ? null
                          : () {
                              if (!routeEventTimelineValidPosition(
                                  row.position)) {
                                return;
                              }
                              widget.onItemTap!(row);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        decoration: selected
                            ? BoxDecoration(
                                color:
                                    AppColors.accent.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.42),
                                  width: 1,
                                ),
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 18, color: accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: widget.compact ? 11 : 12,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    row.primaryTimeLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondaryOf(
                                          context),
                                    ),
                                  ),
                                  if (row.detailLine.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      row.detailLine,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: widget.compact ? 9 : 10,
                                        color:
                                            AppColors.textMutedOf(context),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (widget.onItemTap != null)
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.textMutedOf(context),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (hasMore) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? l10n.routeEventsSeeLess : l10n.routeEventsSeeMore,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
