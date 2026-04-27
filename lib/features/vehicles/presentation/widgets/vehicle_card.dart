import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/entities/vehicle.dart';

class VehicleCard extends StatefulWidget {
  const VehicleCard({super.key, required this.vehicle, this.onTap});

  final VehicleEntity vehicle;
  final VoidCallback? onTap;

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
    final color = _statusColor;
    final status = StatusBadge.fromString(v.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withValues(alpha: 0.06),
        highlightColor: color.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.14), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left status bar ────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: v.isMoving
                            ? color
                                .withValues(alpha: 0.45 + 0.55 * _pulseAnim.value)
                            : color,
                      ),
                    ),
                  ),

                  // ── Card content ───────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 0, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Row 1: Icon + Name + Status ──────────────────
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
                                    // Name + badge
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            v.name,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
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
                                    const SizedBox(height: 5),
                                    // Plate + driver
                                    Row(
                                      children: [
                                        _PlateBadge(plate: v.plateNumber),
                                        if (v.driverName != null &&
                                            v.driverName!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.person_rounded,
                                            size: 11,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              v.driverName!,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Divider ───────────────────────────────────────
                          Container(height: 1, color: AppColors.divider),

                          const SizedBox(height: 11),

                          // ── Row 2: Telemetry ──────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Speed
                              _TelemetryItem(
                                icon: Icons.speed_rounded,
                                label: 'السرعة',
                                value: FormatUtils.speed(v.speed),
                                color: v.isMoving && v.speed > 0
                                    ? AppColors.statusMoving
                                    : AppColors.textSecondary,
                              ),
                              _dividerV(),
                              // Ignition
                              _TelemetryItem(
                                icon: Icons.power_settings_new_rounded,
                                label: 'المحرك',
                                value: v.ignition ? 'شغّال' : 'مطفأ',
                                color: v.ignition
                                    ? AppColors.statusMoving
                                    : AppColors.textMuted,
                              ),
                              if (v.fuelLevel != null) ...[
                                _dividerV(),
                                Expanded(
                                  child: _FuelBar(fuelLevel: v.fuelLevel!),
                                ),
                              ] else
                                const Spacer(),
                              if (v.batteryVoltage != null) ...[
                                _dividerV(),
                                _TelemetryItem(
                                  icon: Icons.battery_charging_full_rounded,
                                  label: 'البطارية',
                                  value: FormatUtils.voltage(v.batteryVoltage),
                                  color: _batteryColor(v.batteryVoltage),
                                ),
                              ],
                            ],
                          ),

                          // ── Row 3: Address + time ─────────────────────────
                          if ((v.address != null && v.address!.isNotEmpty) ||
                              v.lastUpdate != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (v.address != null &&
                                    v.address!.isNotEmpty) ...[
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      v.address!,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ] else
                                  const Spacer(),
                                if (v.lastUpdate != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormatter.toRelative(v.lastUpdate!),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Chevron ────────────────────────────────────────────────
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

  Widget _dividerV() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.divider,
      );

  Color _batteryColor(double? v) {
    if (v == null) return AppColors.textMuted;
    if (v >= 12.6) return AppColors.statusMoving;
    if (v >= 12.0) return AppColors.statusStopped;
    return AppColors.error;
  }
}

// ── Vehicle icon with pulse indicator ────────────────────────────────────────

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
                    color: AppColors.cardBackground,
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

// ── Plate badge ───────────────────────────────────────────────────────────────

class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Text(
        plate,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Telemetry item ────────────────────────────────────────────────────────────

class _TelemetryItem extends StatelessWidget {
  const _TelemetryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Fuel level bar ────────────────────────────────────────────────────────────

class _FuelBar extends StatelessWidget {
  const _FuelBar({required this.fuelLevel});

  final double fuelLevel;

  Color get _color {
    if (fuelLevel >= 60) return AppColors.statusMoving;
    if (fuelLevel >= 25) return AppColors.statusStopped;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (fuelLevel / 100).clamp(0.0, 1.0);
    final color = _color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.local_gas_station_rounded,
                size: 11, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            const Text(
              'الوقود',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            Text(
              '${fuelLevel.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
