import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/widgets/elmo_button.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/analytics_provider.dart';
import '../../domain/entities/analytics_data.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(analyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (data) => _AnalyticsContent(data: data),
        loading: () => const LoadingView(message: 'Loading analytics…'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(analyticsProvider),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _PeriodHeader(),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Efficiency score
          _EfficiencyScoreCard(score: data.fleetEfficiencyScore),
          const SizedBox(height: AppSpacing.md),

          // Weekly bar chart
          Text('Weekly Distance', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _WeeklyBarChart(data: data),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Stats grid
          Text('Fleet KPIs', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _StatsGrid(data: data),
          const SizedBox(height: AppSpacing.sectionSpacing),

          // Highlights
          Text('Highlights', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _HighlightCard(
            icon: Icons.emoji_events_rounded,
            label: 'Most active vehicle',
            value: data.mostActiveVehicle,
            color: AppColors.statusMoving,
          ),
          const SizedBox(height: AppSpacing.sm),
          _HighlightCard(
            icon: Icons.trending_down_rounded,
            label: 'Least efficient vehicle',
            value: data.leastEfficientVehicle,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          _HighlightCard(
            icon: Icons.warning_amber_rounded,
            label: 'Top alert category',
            value: data.topAlertCategory,
            color: AppColors.error,
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Report', style: AppTextStyles.headlineLarge),
            Text(
              'Week of ${DateFormatter.toDate(weekStart)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text('This Week', style: AppTextStyles.labelMedium),
        ),
      ],
    );
  }
}

class _EfficiencyScoreCard extends StatelessWidget {
  const _EfficiencyScoreCard({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.statusMoving
        : score >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), AppColors.cardBackground],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fleet Efficiency Score',
                  style: AppTextStyles.bodySmall),
              Text(
                '${score.toStringAsFixed(1)}%',
                style: AppTextStyles.displayMedium.copyWith(color: color),
              ),
              Text(
                score >= 80
                    ? 'Excellent performance'
                    : score >= 60
                        ? 'Good, room for improvement'
                        : 'Needs attention',
                style: AppTextStyles.bodySmall.copyWith(color: color),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: AppColors.surfaceElevated,
                  color: color,
                ),
                Center(
                  child: Text(
                    '${score.toInt()}',
                    style: AppTextStyles.headlineSmall.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final max = data.dailyDistances.fold(0.0, (a, b) => a > b ? a : b);

    return ElmoCard(
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.dailyDistances.length, (i) {
                final ratio = max > 0 ? data.dailyDistances[i] / max : 0.0;
                final isMax = data.dailyDistances[i] == max;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isMax)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              FormatUtils.distance(data.dailyDistances[i]),
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 9,
                                color: AppColors.accent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    isMax
                                        ? AppColors.accent
                                        : AppColors.accent.withOpacity(0.4),
                                    isMax
                                        ? AppColors.accentDark
                                        : AppColors.accent.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: data.dailyLabels.map((label) {
              return Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.6,
      ),
      children: [
        _KPICard(
          label: 'Total Distance',
          value: FormatUtils.distance(data.weeklyDistanceMeters),
          icon: Icons.route_rounded,
          color: AppColors.accent,
        ),
        _KPICard(
          label: 'Total Trips',
          value: '${data.weeklyTripCount}',
          icon: Icons.directions_car_rounded,
          color: AppColors.statusMoving,
        ),
        _KPICard(
          label: 'Idle Time',
          value: DateFormatter.duration(data.totalIdleSeconds),
          icon: Icons.timer_off_rounded,
          color: AppColors.warning,
        ),
        _KPICard(
          label: 'Overspeed Events',
          value: '${data.overspeedCount}',
          icon: Icons.speed_rounded,
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(color: color),
              ),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
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
    return ElmoCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(value, style: AppTextStyles.labelLarge),
            ],
          ),
        ],
      ),
    );
  }
}
