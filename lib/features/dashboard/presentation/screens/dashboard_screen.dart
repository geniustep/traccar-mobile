import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/fleet_stats_row.dart';
import '../widgets/insight_card.dart';
import '../../domain/entities/insight.dart';
import '../../../alerts/domain/entities/alert.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final insightsAsync = ref.watch(dashboardInsightsProvider);
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.read(dashboardNotifierProvider.notifier).refresh();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                    AppSpacing.screenPadding,
                    0,
                  ),
                  child: _buildHeader(context, user?.name),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    children: [
                      // Fleet stats
                      summaryAsync.when(
                        data: (summary) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FleetStatsRow(summary: summary),
                            const SizedBox(height: AppSpacing.sm),
                            AlertSummaryRow(summary: summary),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Updated ${DateFormatter.toRelative(summary.lastUpdated)}',
                                style: AppTextStyles.labelSmall,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const LoadingView(message: 'Loading fleet data…'),
                        error: (e, _) => _buildSummaryError(context, ref),
                      ),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      // Quick actions
                      _buildQuickActions(context),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      // Weekly distance card
                      summaryAsync.whenOrNull(
                        data: (s) => _buildDistanceCard(s.totalDistanceToday),
                      ) ?? const SizedBox.shrink(),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      // Insights
                      SectionHeader(
                        title: 'Fleet Insights',
                        actionLabel: 'Analytics',
                        onAction: () => context.go('/analytics'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      insightsAsync.when(
                        data: (insights) => _buildInsightsList(insights),
                        loading: () => const InlineLoader(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      // Recent alerts
                      SectionHeader(
                        title: 'Recent Alerts',
                        actionLabel: 'View all',
                        onAction: () => context.go('/alerts'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      alertsAsync.when(
                        data: (alerts) {
                          final recent = alerts.take(3).toList();
                          return Column(
                            children: recent.map((alert) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _AlertTile(alert: alert),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const InlineLoader(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: AppTextStyles.bodySmall),
            Text(
              name?.split(' ').first ?? 'Manager',
              style: AppTextStyles.headlineLarge,
            ),
          ],
        ),
        Row(
          children: [
            _HeaderIconBtn(
              icon: Icons.notifications_outlined,
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _HeaderIconBtn(
              icon: Icons.person_outline_rounded,
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.directions_car_rounded,
          label: 'Vehicles',
          onTap: () => context.go('/vehicles'),
        ),
        _QuickAction(
          icon: Icons.map_rounded,
          label: 'Live Map',
          onTap: () => context.go('/map'),
        ),
        _QuickAction(
          icon: Icons.route_rounded,
          label: 'Trips',
          onTap: () => context.push('/vehicles'),
        ),
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'Analytics',
          onTap: () => context.go('/analytics'),
        ),
      ],
    );
  }

  Widget _buildDistanceCard(double meters) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00607A), Color(0xFF0D1B2A)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: AppColors.accent, size: 28),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distance today',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                FormatUtils.distance(meters),
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.accent,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(List<InsightEntity> insights) {
    if (insights.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'No insights yet',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return Column(
      children: insights.map((i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InsightCard(insight: i),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryError(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Failed to load fleet data', style: AppTextStyles.bodySmall),
          ),
          TextButton(
            onPressed: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.fromBorderSide(
            BorderSide(color: cs.outline.withOpacity(0.4), width: 0.6),
          ),
        ),
        child: Icon(icon, size: 20, color: cs.onSurface.withOpacity(0.65)),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.fromBorderSide(
                  BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                    width: 0.6,
                  ),
                ),
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertEntity alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                ),
                Text(
                  alert.vehicleName,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (!alert.isRead)
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
