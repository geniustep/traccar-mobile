import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';
import '../providers/fleet_live_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

DashboardSummary _mergeWithLiveFleet(
  DashboardSummary base,
  FleetLiveCounts live,
) {
  if (!live.hasLiveData || live.total == 0) return base;
  return DashboardSummary(
    totalVehicles: base.totalVehicles,
    movingVehicles: live.moving,
    stoppedVehicles: live.stopped,
    idleVehicles: live.idle,
    offlineVehicles: live.offline,
    alertsToday: base.alertsToday,
    criticalAlerts: base.criticalAlerts,
    tripsToday: base.tripsToday,
    totalDistanceToday: base.totalDistanceToday,
    lastUpdated: base.lastUpdated,
  );
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final liveFleet = ref.watch(fleetLiveCountsProvider);
    final socketAlertsToday = ref.watch(socketEventsTodayCountProvider);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          displacement: 20,
          onRefresh: () async {
            ref.read(dashboardNotifierProvider.notifier).refresh();
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // ── Header ─────────────────────────────────────
                      _DashboardHeader(
                        name: user?.name,
                        l10n: l10n,
                        onNotificationsTap: () =>
                            context.push('/notifications'),
                        onSettingsTap: () => context.go('/settings'),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Hero Fleet Card ────────────────────────────
                      Expanded(
                        flex: 27,
                        child: summaryAsync.when(
                          data: (s) => _HeroFleetCard(
                            summary: _mergeWithLiveFleet(s, liveFleet),
                            l10n: l10n,
                            isDark: isDark,
                          ),
                          loading: () => const _SkeletonCard(radius: 20),
                          error: (_, __) => _ErrorCard(
                            l10n: l10n,
                            onRetry: () =>
                                ref.read(dashboardNotifierProvider.notifier).refresh(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Status Stats Row ───────────────────────────
                      Expanded(
                        flex: 16,
                        child: summaryAsync.when(
                          data: (s) => _StatusStatsRow(
                            summary: _mergeWithLiveFleet(s, liveFleet),
                            l10n: l10n,
                            isDark: isDark,
                          ),
                          loading: () => const _SkeletonCard(radius: 14),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Metrics Row ────────────────────────────────
                      Expanded(
                        flex: 19,
                        child: summaryAsync.when(
                          data: (s) => _MetricsRow(
                            summary: _mergeWithLiveFleet(s, liveFleet),
                            l10n: l10n,
                            isDark: isDark,
                            socketAlertsToday: socketAlertsToday,
                          ),
                          loading: () => const _SkeletonCard(radius: 16),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Quick Actions ──────────────────────────────
                      Expanded(
                        flex: 15,
                        child: _QuickActionsRow(
                          l10n: l10n,
                          isDark: isDark,
                          onVehiclesTap: () => context.go('/vehicles'),
                          onMapTap: () => context.go('/map'),
                          onTripsTap: () => context.push('/vehicles'),
                          onAnalyticsTap: () => context.go('/analytics'),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Recent Alerts Header ───────────────────────
                      _SectionHeader(
                        title: l10n.recentAlerts,
                        actionLabel: l10n.viewAll,
                        onAction: () => context.go('/alerts'),
                      ),

                      const SizedBox(height: AppSpacing.xs + 2),

                      // ── Recent Alerts List ─────────────────────────
                      Expanded(
                        flex: 25,
                        child: alertsAsync.when(
                          data: (alerts) => _RecentAlertsList(
                            alerts: alerts.take(3).toList(),
                            isDark: isDark,
                          ),
                          loading: () => const _InlineLoader(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.name,
    required this.l10n,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });

  final String? name;
  final AppLocalizations l10n;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                name?.split(' ').first ?? l10n.fleetManager,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderBtn(
          icon: Icons.notifications_rounded,
          color: AppColors.amber,
          onTap: onNotificationsTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderBtn(
          icon: Icons.manage_accounts_rounded,
          color: AppColors.accent,
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25), width: 0.8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Fleet Card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroFleetCard extends StatelessWidget {
  const _HeroFleetCard({
    required this.summary,
    required this.l10n,
    required this.isDark,
  });

  final DashboardSummary summary;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF063354), Color(0xFF081525)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF005F8E), Color(0xFF013A6E)],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(isDark ? 0.25 : 0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(isDark ? 0.08 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient glow circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LIVE indicator ─────────────────────
                Row(
                  children: [
                    const _LiveIndicator(),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.fleetOverview.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Count + Legend ─────────────────────
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Big total number
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${summary.totalVehicles}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -2,
                                  height: 1.0,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8, left: 5),
                                child: Text(
                                  'VEH',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            l10n.totalVehicles.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Status legend
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _LegendItem(
                            color: AppColors.statusMoving,
                            label: l10n.moving,
                            count: summary.movingVehicles,
                          ),
                          const SizedBox(height: 7),
                          _LegendItem(
                            color: AppColors.statusStopped,
                            label: l10n.stopped,
                            count: summary.stoppedVehicles,
                          ),
                          const SizedBox(height: 7),
                          _LegendItem(
                            color: AppColors.statusIdle,
                            label: l10n.idle,
                            count: summary.idleVehicles,
                          ),
                          const SizedBox(height: 7),
                          _LegendItem(
                            color: AppColors.statusOffline,
                            label: l10n.offline,
                            count: summary.offlineVehicles,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Fleet status bar ───────────────────
                _FleetStatusBar(summary: summary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.statusMoving,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x7010B981), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'LIVE',
          style: TextStyle(
            color: AppColors.statusMoving,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 5)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _FleetStatusBar extends StatelessWidget {
  const _FleetStatusBar({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalVehicles;
    if (total == 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            if (summary.movingVehicles > 0)
              Expanded(
                flex: summary.movingVehicles,
                child: const ColoredBox(color: AppColors.statusMoving),
              ),
            if (summary.stoppedVehicles > 0)
              Expanded(
                flex: summary.stoppedVehicles,
                child: const ColoredBox(color: AppColors.statusStopped),
              ),
            if (summary.idleVehicles > 0)
              Expanded(
                flex: summary.idleVehicles,
                child: const ColoredBox(color: AppColors.statusIdle),
              ),
            if (summary.offlineVehicles > 0)
              Expanded(
                flex: summary.offlineVehicles,
                child: ColoredBox(
                    color: AppColors.statusOffline.withOpacity(0.4)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Stats Row  (4 chips: Moving | Stopped | Idle | Offline)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusStatsRow extends StatelessWidget {
  const _StatusStatsRow({
    required this.summary,
    required this.l10n,
    required this.isDark,
  });

  final DashboardSummary summary;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          count: summary.movingVehicles,
          label: l10n.moving,
          color: AppColors.statusMoving,
          icon: Icons.navigation_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          count: summary.stoppedVehicles,
          label: l10n.stopped,
          color: AppColors.statusStopped,
          icon: Icons.stop_circle_outlined,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          count: summary.idleVehicles,
          label: l10n.idle,
          color: AppColors.statusIdle,
          icon: Icons.timelapse_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          count: summary.offlineVehicles,
          label: l10n.offline,
          color: AppColors.statusOffline,
          icon: Icons.signal_wifi_off_rounded,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.25 : 0.18),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 3),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(isDark ? 0.65 : 0.75),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metrics Row  (Distance | Trips + Alerts)
// ─────────────────────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.summary,
    required this.l10n,
    required this.isDark,
    this.socketAlertsToday = 0,
  });

  final DashboardSummary summary;
  final AppLocalizations l10n;
  final bool isDark;
  final int socketAlertsToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Distance – tall card
        Expanded(
          flex: 5,
          child: _MetricCard(
            icon: Icons.route_rounded,
            value: FormatUtils.distance(summary.totalDistanceToday),
            label: l10n.distanceToday,
            darkGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A3D4D), Color(0xFF0C2535)],
            ),
            lightGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF006494), Color(0xFF0582CA)],
            ),
            accentColor: AppColors.accent,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        // Right column – two compact cards stacked
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.alt_route_rounded,
                  value: '${summary.tripsToday}',
                  label: l10n.tripsToday,
                  darkGradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D1B69), Color(0xFF1E1144)],
                  ),
                  lightGradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B21A8), Color(0xFF7C3AED)],
                  ),
                  accentColor: AppColors.purple,
                  isDark: isDark,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  icon: Icons.warning_amber_rounded,
                  value: '${summary.alertsToday}',
                  label: l10n.alertsToday,
                  footer: socketAlertsToday > 0
                      ? 'WebSocket · $socketAlertsToday (aujourd’hui)'
                      : null,
                  darkGradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D1515), Color(0xFF2A0F0F)],
                  ),
                  lightGradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
                  ),
                  accentColor: AppColors.rose,
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.darkGradient,
    required this.lightGradient,
    required this.accentColor,
    required this.isDark,
    this.compact = false,
    this.footer,
  });

  final IconData icon;
  final String value;
  final String label;
  final LinearGradient darkGradient;
  final LinearGradient lightGradient;
  final Color accentColor;
  final bool isDark;
  final bool compact;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? darkGradient : lightGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.1 : 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : AppSpacing.lg,
        vertical: 0,
      ),
      child: compact
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          footer!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Row
// ─────────────────────────────────────────────────────────────────────────────

class _QAItem {
  const _QAItem(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.l10n,
    required this.isDark,
    required this.onVehiclesTap,
    required this.onMapTap,
    required this.onTripsTap,
    required this.onAnalyticsTap,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onVehiclesTap;
  final VoidCallback onMapTap;
  final VoidCallback onTripsTap;
  final VoidCallback onAnalyticsTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QAItem(Icons.directions_car_rounded, l10n.vehicles, AppColors.accent, onVehiclesTap),
      _QAItem(Icons.map_rounded, l10n.liveMap, AppColors.emerald, onMapTap),
      _QAItem(Icons.alt_route_rounded, l10n.trips, AppColors.purple, onTripsTap),
      _QAItem(Icons.bar_chart_rounded, l10n.analytics, AppColors.amber, onAnalyticsTap),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: items[i].onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: items[i].color.withOpacity(isDark ? 0.1 : 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: items[i].color.withOpacity(isDark ? 0.24 : 0.18),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: items[i].color.withOpacity(isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(items[i].icon, color: items[i].color, size: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        color: items[i].color.withOpacity(isDark ? 0.85 : 1.0),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 0.1,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accent,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Alerts
// ─────────────────────────────────────────────────────────────────────────────

class _RecentAlertsList extends StatelessWidget {
  const _RecentAlertsList({
    required this.alerts,
    required this.isDark,
  });

  final List<AlertEntity> alerts;
  final bool isDark;

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.severityCritical;
      case 'high':
        return AppColors.severityHigh;
      case 'medium':
        return AppColors.severityMedium;
      case 'low':
        return AppColors.severityLow;
      default:
        return AppColors.severityInfo;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.emergency_rounded;
      case 'high':
        return Icons.warning_rounded;
      case 'medium':
        return Icons.info_rounded;
      case 'low':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
        child: Text(
          'No recent alerts',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
            fontSize: 13,
          ),
        ),
      );
    }
    final widgets = <Widget>[];
    for (int i = 0; i < alerts.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 6));
      widgets.add(
        Expanded(
          child: _AlertTile(
            alert: alerts[i],
            isDark: isDark,
            color: _severityColor(alerts[i].severity),
            icon: _severityIcon(alerts[i].severity),
          ),
        ),
      );
    }
    return Column(children: widgets);
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.isDark,
    required this.color,
    required this.icon,
  });

  final AlertEntity alert;
  final bool isDark;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.05) : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.2 : 0.12),
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 0,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  alert.vehicleName,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormatter.toRelative(alert.createdAt),
                style: TextStyle(
                  fontSize: 9,
                  color: cs.onSurface.withOpacity(0.35),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!alert.isRead) ...[
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1521) : const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? const Color(0xFF1A2A3A) : const Color(0xFFCDD8E3),
          width: 0.8,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.l10n, required this.onRetry});
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error.withOpacity(0.5), size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Failed to load fleet data',
            style:
                TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                l10n.retry,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
      ),
    );
  }
}
