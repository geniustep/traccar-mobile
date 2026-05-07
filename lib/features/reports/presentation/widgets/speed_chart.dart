import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../map/data/datasources/route_datasource.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SpeedChartWidget
// Displays a speed-over-time line chart using fl_chart.
// ─────────────────────────────────────────────────────────────────────────────

class SpeedChartWidget extends StatelessWidget {
  const SpeedChartWidget({
    super.key,
    required this.points,
    this.highlightTime,
  });

  final List<RoutePoint> points;

  /// Optional time to highlight with a vertical indicator line (e.g. from replay).
  final DateTime? highlightTime;

  // Max chart points — sample if more.
  static const int _maxChartPoints = 400;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final valid = points.where((p) => p.speed >= 0).toList();

    if (valid.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart_rounded,
                  size: 48,
                  color: AppColors.textMutedOf(context)),
              const SizedBox(height: 12),
              Text(
                l10n.noSpeedData,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Compute stats from original (un-sampled) data.
    final maxSpeed = valid.map((p) => p.speed).reduce((a, b) => a > b ? a : b);
    final avgSpeed = valid.map((p) => p.speed).reduce((a, b) => a + b) /
        valid.length;

    // Sample for chart performance.
    final sampled = _samplePoints(valid, maxCount: _maxChartPoints);

    final origin = sampled.first.fixTime;
    final spots = sampled.asMap().entries.map((e) {
      final minutesOffset =
          e.value.fixTime.difference(origin).inSeconds / 60.0;
      return FlSpot(minutesOffset, e.value.speed);
    }).toList();

    // BUG FIX: guard against zero/tiny maxX (e.g. all points at same second).
    final maxX = math.max(spots.last.x, 0.1);

    // BUG FIX: guard against zero maxY (all speeds == 0, vehicle stopped).
    final maxY = maxSpeed > 0 ? (maxSpeed * 1.15).ceilToDouble() : 20.0;

    // Compute highlight X from the provided time.
    double? highlightX;
    if (highlightTime != null) {
      final offset = highlightTime!.difference(origin).inSeconds / 60.0;
      highlightX = offset.clamp(0.0, maxX);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              _StatBadge(
                icon: Icons.arrow_upward_rounded,
                label: l10n.speedChartMax,
                value: FormatUtils.speed(maxSpeed),
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                icon: Icons.av_timer_rounded,
                label: l10n.speedChartAvg,
                value: FormatUtils.speed(avgSpeed),
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              _StatBadge(
                icon: Icons.gps_fixed_rounded,
                label: l10n.speedChartGpsPoints,
                value: '${valid.length}',
                color: AppColors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Chart ──────────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 16, 16),
            child: LineChart(
              _buildChartData(
                context: context,
                spots: spots,
                maxX: maxX,
                maxY: maxY,
                origin: origin,
                highlightX: highlightX,
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData({
    required BuildContext context,
    required List<FlSpot> spots,
    required double maxX,
    required double maxY,
    required DateTime origin,
    double? highlightX,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final labelColor = AppColors.textSecondaryOf(context);

    return LineChartData(
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      clipData: const FlClipData.all(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppColors.accent,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accent.withValues(alpha: 0.3),
                AppColors.accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: _niceInterval(maxY, targetLines: 5),
        verticalInterval: _niceInterval(maxX, targetLines: 5),
        getDrawingHorizontalLine: (_) => FlLine(
          color: gridColor,
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: gridColor,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: _niceInterval(maxY, targetLines: 5),
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox.shrink();
              return Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 9, color: labelColor),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: _niceInterval(maxX, targetLines: 5),
            getTitlesWidget: (value, meta) {
              final dt =
                  origin.add(Duration(seconds: (value * 60).round()));
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat('HH:mm').format(dt),
                  style: TextStyle(fontSize: 9, color: labelColor),
                ),
              );
            },
          ),
        ),
      ),
      extraLinesData: highlightX == null
          ? null
          : ExtraLinesData(
              verticalLines: [
                VerticalLine(
                  x: highlightX,
                  color: AppColors.error.withValues(alpha: 0.85),
                  strokeWidth: 2,
                  dashArray: [5, 4],
                  label: VerticalLineLabel(
                    show: false,
                  ),
                ),
              ],
            ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surfaceOf(context),
          getTooltipItems: (spots) => spots.map((s) {
            final dt =
                origin.add(Duration(seconds: (s.x * 60).round()));
            return LineTooltipItem(
              '${s.y.toStringAsFixed(0)} km/h\n${DateFormat('HH:mm:ss').format(dt)}',
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static List<RoutePoint> _samplePoints(
      List<RoutePoint> pts, {
      required int maxCount,
    }) {
    if (pts.length <= maxCount) return pts;
    final step = (pts.length - 1) / (maxCount - 1);
    final result = <RoutePoint>[pts.first];
    for (var i = 1; i < maxCount - 1; i++) {
      result.add(pts[(i * step).round().clamp(1, pts.length - 2)]);
    }
    result.add(pts.last);
    return result;
  }

  /// Standard "nice number" interval for chart axis labels.
  /// BUG FIX: previous version used multiplication instead of exponentiation
  /// (`base * exp` instead of `pow(base, exp)`), producing power=0 when
  /// exp=0 and causing an Infinity/NaN crash on .toInt().
  static double _niceInterval(double max, {required int targetLines}) {
    if (!max.isFinite || max <= 0 || targetLines <= 0) return 1;
    final raw = max / targetLines;
    if (!raw.isFinite || raw <= 0) return 1;
    final logVal = math.log(raw) / math.ln10;
    final magnitude = math.pow(10, logVal.floor()).toDouble();
    if (!magnitude.isFinite || magnitude <= 0) return 1;
    final normalized = raw / magnitude;
    final nice = normalized <= 1.5
        ? 1.0
        : normalized <= 3.5
            ? 2.0
            : normalized <= 7.5
                ? 5.0
                : 10.0;
    final result = nice * magnitude;
    return result.isFinite && result > 0 ? result : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatBadge
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge({
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
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textMutedOf(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
