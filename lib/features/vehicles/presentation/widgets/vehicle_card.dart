import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../fleet/presentation/fleet_vehicle_brief_provider.dart';
import '../../domain/entities/vehicle.dart';
import '../utils/fleet_list_card_intel.dart';

class VehicleCard extends StatefulWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.fleetBrief,
  });

  final VehicleEntity vehicle;
  final VoidCallback? onTap;
  final FleetVehicleBrief? fleetBrief;

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.vehicle.isMoving) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(VehicleCard old) {
    super.didUpdateWidget(old);
    if (widget.vehicle.isMoving && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.vehicle.isMoving && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor => switch (widget.vehicle.status) {
        'moving' => AppColors.statusMoving,
        'stopped' => AppColors.statusStopped,
        'idle' => AppColors.statusIdle,
        _ => AppColors.statusOffline,
      };

  IconData get _vehicleIcon => switch (widget.vehicle.type.toLowerCase()) {
        'truck' => Icons.local_shipping_rounded,
        'van' => Icons.airport_shuttle_rounded,
        'bus' => Icons.directions_bus_rounded,
        'motorcycle' => Icons.two_wheeler_rounded,
        _ => Icons.directions_car_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final l10n = context.l10n;
    final color = _statusColor;
    final status = StatusBadge.fromString(v.status);
    final fb = widget.fleetBrief;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final driverName = FleetListCardIntel.driverDisplayName(
      brief: fb,
      vehicle: v,
      l10n: l10n,
    );
    final identifier = FleetListCardIntel.vehicleIdentifier(v);
    final summaryLine = FleetListCardIntel.buildSummaryLine(
      vehicle: v,
      l10n: l10n,
    );
    final alertBanner = FleetListCardIntel.pickAlertBanner(v, fb, l10n: l10n);
    final contextLines = FleetListCardIntel.contextDetailLines(
      vehicle: v,
      l10n: l10n,
    );
    final positionLine = FleetListCardIntel.lastPositionLine(v, l10n);
    final lastDataLine = FleetListCardIntel.lastDataFooterLine(v, l10n);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.06),
        highlightColor: color.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? color.withValues(alpha: 0.14)
                  : color.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? color.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isDark ? 14 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: v.isMoving
                            ? color.withValues(
                                alpha: 0.45 + 0.55 * _pulseAnim.value,
                              )
                            : color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _VehicleIconWidget(
                                icon: _vehicleIcon,
                                color: color,
                                isMoving: v.isMoving,
                                pulseAnim: _pulseAnim,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            v.name,
                                            style: TextStyle(
                                              color: AppColors.textPrimaryOf(
                                                context,
                                              ),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              height: 1.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusBadge(status: status),
                                      ],
                                    ),
                                    if (identifier.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        identifier,
                                        style: TextStyle(
                                          color: AppColors.textMutedOf(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (driverName != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_rounded,
                                            size: 11,
                                            color: AppColors.textMutedOf(
                                              context,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              driverName,
                                              style: TextStyle(
                                                color: AppColors.textMutedOf(
                                                  context,
                                                ),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            summaryLine,
                              style: TextStyle(
                                color: v.isOffline
                                    ? AppColors.textMutedOf(context)
                                    : AppColors.textSecondaryOf(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ...contextLines.map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                line,
                                style: TextStyle(
                                  color: AppColors.textMutedOf(context),
                                  fontSize: 10.5,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (positionLine != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: AppColors.textMutedOf(context),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    positionLine,
                                    style: TextStyle(
                                      color: AppColors.textMutedOf(context),
                                      fontSize: 10.5,
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (alertBanner != null) ...[
                            const SizedBox(height: 8),
                            _AlertBanner(banner: alertBanner),
                          ],
                          if (lastDataLine != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: AppColors.textMutedOf(context),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    lastDataLine,
                                    style: TextStyle(
                                      color: AppColors.textMutedOf(context),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: color.withValues(alpha: 0.4),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.banner});

  final FleetCardAlertBanner banner;

  @override
  Widget build(BuildContext context) {
    final tone = banner.isErrorTone ? AppColors.error : AppColors.statusStopped;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            banner.isErrorTone
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 14,
            color: tone,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              banner.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tone,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleIconWidget extends StatelessWidget {
  const _VehicleIconWidget({
    required this.icon,
    required this.color,
    required this.isMoving,
    required this.pulseAnim,
  });

  final IconData icon;
  final Color color;
  final bool isMoving;
  final Animation<double> pulseAnim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        if (isMoving)
          Positioned(
            bottom: -2,
            right: -2,
            child: AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, __) => Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppColors.statusMoving
                      .withValues(alpha: 0.5 + 0.5 * pulseAnim.value),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cardBackgroundOf(context),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusMoving
                          .withValues(alpha: 0.55 * pulseAnim.value),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
