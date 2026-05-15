import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/route_event_timeline_models.dart';
import '../../core/route_event_timeline_sheet_details.dart';
import '../../core/route_stop_address_resolver.dart';

/// Lightweight modal bottom sheet with structured route event details.
class RouteEventDetailsSheet extends StatelessWidget {
  const RouteEventDetailsSheet({
    super.key,
    required this.presentation,
    this.onRecenter,
  });

  final RouteEventSheetPresentation presentation;
  final VoidCallback? onRecenter;

  static Future<void> show(
    BuildContext context, {
    required RouteEventTimelineItem item,
    VoidCallback? onRecenter,
    RouteStopAddressResolver? resolver,
    void Function(String selectionKey, String address)? onStopAddressCommitted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (ctx) => _RouteEventDetailsSheetLive(
        initialItem: item,
        onRecenter: onRecenter,
        resolver: resolver,
        onStopAddressCommitted: onStopAddressCommitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pres = presentation;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pres.pageTitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMutedOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pres.headline,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 10),
          ...pres.rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      r.label,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: AppColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.value,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pres.addressLine != null) ...[
            const SizedBox(height: 2),
            Text(
              pres.addressLine!,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ],
          if (onRecenter != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRecenter,
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: Text(AppLocalizations.of(context).routeEventDetailsRecenter),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteEventDetailsSheetLive extends StatefulWidget {
  const _RouteEventDetailsSheetLive({
    required this.initialItem,
    this.onRecenter,
    this.resolver,
    this.onStopAddressCommitted,
  });

  final RouteEventTimelineItem initialItem;
  final VoidCallback? onRecenter;
  final RouteStopAddressResolver? resolver;
  final void Function(String selectionKey, String address)? onStopAddressCommitted;

  @override
  State<_RouteEventDetailsSheetLive> createState() =>
      _RouteEventDetailsSheetLiveState();
}

class _RouteEventDetailsSheetLiveState extends State<_RouteEventDetailsSheetLive> {
  late RouteEventTimelineItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    final r = widget.resolver;
    if (r != null &&
        _item.kind == RouteTimelineEntryKind.stop &&
        (_item.stopAddress == null || _item.stopAddress!.trim().isEmpty)) {
      Future<void>.microtask(() => _resolveStopAddress(r));
    }
  }

  Future<void> _resolveStopAddress(RouteStopAddressResolver r) async {
    final addr = await r.resolveLatLng(
      _item.position.latitude,
      _item.position.longitude,
    );
    if (!mounted || addr == null || addr.isEmpty) return;
    setState(() {
      _item = _item.copyWith(stopAddress: addr);
    });
    widget.onStopAddressCommitted?.call(_item.selectionKey, addr);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pres = buildRouteEventSheetPresentation(_item, l10n);
    return RouteEventDetailsSheet(
      presentation: pres,
      onRecenter: pres.showRecenterAction ? widget.onRecenter : null,
    );
  }
}
