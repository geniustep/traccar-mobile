import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/connection/app_connection_monitor.dart';
import '../../../../core/connection/app_connection_status.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../dashboard/domain/dashboard_refresh_policy.dart';
import '../../../dashboard/domain/entities/dashboard_summary.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/providers/fleet_live_provider.dart';
import '../../../dashboard/presentation/widgets/animated_live_number.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';
import '../../domain/fleet_dashboard_period.dart';
import '../../domain/fleet_admin_snapshot.dart';
import '../providers/fleet_intelligence_metrics_provider.dart';
import '../providers/fleet_intelligence_providers.dart';

/// Dashboard connection badge — now driven by the dual
/// [AppConnectionStatus] + [LiveSyncStatus] model.
enum _FleetConnectionBadge {
  live,
  liveDegraded,
  liveReconnecting,
  offline,
  serverUnavailable,
  sessionExpired,
  checking,
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;
  GoRouter? _router;
  bool _isDashboardVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.dashboard('Dashboard opened');
    _scheduleInitialRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_router == null) {
      _router = GoRouter.of(context);
      _router!.routerDelegate.addListener(_onRouteChanged);
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onRouteChanged() {
    final path =
        _router!.routerDelegate.currentConfiguration.uri.path;
    final nowOnDashboard =
        path == '/dashboard' || path == '/fleet-intelligence';

    if (nowOnDashboard && !_isDashboardVisible) {
      AppLogger.dashboard('Route resumed, returnedFrom: $_lastNonDashboardPath');
      ref.read(dashboardNotifierProvider.notifier).smartRefresh(
            reason: 'dashboard_route_resumed',
          );
    }

    if (!nowOnDashboard) _lastNonDashboardPath = path;
    _isDashboardVisible = nowOnDashboard;
  }

  String _lastNonDashboardPath = '';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _scheduleInitialRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(dashboardNotifierProvider.notifier);
      final hasCached = ref.read(dashboardNotifierProvider).hasCachedData;

      if (hasCached) {
        AppLogger.dashboard(
          'Cache displayed immediately, '
          'ageSeconds: ${ref.read(dashboardNotifierProvider).ageSeconds}',
        );
      }

      notifier.smartRefresh(reason: 'dashboard_opened');
    });
  }

  void _onAppResumed() {
    if (!mounted) return;
    final bgDuration = _pausedAt != null
        ? DateTime.now().difference(_pausedAt!)
        : Duration.zero;
    _pausedAt = null;

    AppLogger.dashboard(
      'App resumed from background, backgroundDurationSeconds: ${bgDuration.inSeconds}',
    );

    ref.read(dashboardNotifierProvider.notifier).smartRefresh(
          reason: 'app_resumed_after_background',
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final period = ref.watch(fleetDashboardPeriodProvider);
    final user = ref.watch(currentUserProvider);
    final merged = ref.watch(mergedDashboardSummaryProvider);
    final snapAsync = ref.watch(fleetAdminSnapshotProvider(period));
    final isLive = ref.watch(
      fleetLiveCountsProvider.select((c) => c.hasLiveData),
    );
    final appStatus = ref.watch(appConnectionStatusProvider);
    final liveStatus = ref.watch(liveSyncStatusProvider);
    final connectionBadge = _computeConnectionBadge(appStatus, liveStatus);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final refreshState = ref.watch(dashboardNotifierProvider);

    Future<void> doFullRefresh({required String source}) async {
      await ref
          .read(dashboardNotifierProvider.notifier)
          .refresh(source: source);
      ref.invalidate(fleetAdminSnapshotProvider(period));
      ref.invalidate(fleetIntelligenceMetricsProvider);
      await ref.read(fleetAdminSnapshotProvider(period).future);
    }

    final cachedSummary = merged.valueOrNull;
    final showCacheFirst = cachedSummary != null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => doFullRefresh(source: 'pull_to_refresh'),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      _DashboardPremiumHeader(
                        user: user,
                        l10n: l10n,
                        summary: cachedSummary,
                        unreadNotifications: unreadNotifications,
                        onNotifications: () => context.push('/notifications'),
                        onSettings: () => context.go('/settings'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PeriodRefreshRow(
                        period: period,
                        l10n: l10n,
                        onPeriodChanged: (p) => ref
                            .read(fleetDashboardPeriodProvider.notifier)
                            .state = p,
                        onRefresh: () => doFullRefresh(source: 'toolbar'),
                      ),
                      if (refreshState.isRefreshing &&
                          refreshState.lastRefreshMode !=
                              DashboardRefreshMode.full) ...[
                        const SizedBox(height: 4),
                        _SubtleSyncIndicator(l10n: l10n),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      if (showCacheFirst)
                        _DashboardDataBody(
                          summary: cachedSummary,
                          l10n: l10n,
                          connectionBadge: connectionBadge,
                          isLive: isLive,
                          period: period,
                          snapAsync: snapAsync,
                          onAlerts: () => context.go('/alerts'),
                          onMaintenance: () => context.push('/maintenance'),
                          onRetry: () => doFullRefresh(source: 'retry'),
                        )
                      else
                        merged.when(
                          data: (s) => _DashboardDataBody(
                            summary: s,
                            l10n: l10n,
                            connectionBadge: connectionBadge,
                            isLive: isLive,
                            period: period,
                            snapAsync: snapAsync,
                            onAlerts: () => context.go('/alerts'),
                            onMaintenance: () =>
                                context.push('/maintenance'),
                            onRetry: () => doFullRefresh(source: 'retry'),
                          ),
                          loading: () => const _SectionSkeleton(),
                          error: (_, __) => _InlineError(
                            message: l10n.adminDashboardLoadError,
                            onRetry: () => doFullRefresh(source: 'retry'),
                            l10n: l10n,
                          ),
                        ),
                      if (snapAsync.valueOrNull?.tripsEventsError !=
                          null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _SoftWarningBanner(
                          text: l10n.adminDashboardTripsPartialError,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              snapAsync.when(
                data: (s) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: _PeriodDetailSection(
                      snapshot: s,
                      l10n: l10n,
                      period: period,
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                ),
                error: (e, __) => SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppSpacing.screenPadding),
                    child: _InlineError(
                      message: l10n.adminDashboardLoadError,
                      onRetry: () => doFullRefresh(source: 'retry'),
                      l10n: l10n,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extracted so the data body can be shown from cache even while loading.
class _DashboardDataBody extends StatelessWidget {
  const _DashboardDataBody({
    required this.summary,
    required this.l10n,
    required this.connectionBadge,
    required this.isLive,
    required this.period,
    required this.snapAsync,
    required this.onAlerts,
    required this.onMaintenance,
    required this.onRetry,
  });

  final DashboardSummary summary;
  final AppLocalizations l10n;
  final _FleetConnectionBadge connectionBadge;
  final bool isLive;
  final FleetDashboardPeriod period;
  final AsyncValue<FleetAdminSnapshot> snapAsync;
  final VoidCallback onAlerts;
  final VoidCallback onMaintenance;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroSummaryCard(
          summary: summary,
          l10n: l10n,
          connectionBadge: connectionBadge,
          isLive: isLive,
        ),
        const SizedBox(height: AppSpacing.sm),
        _DashboardPremiumStatStrip(
          summary: summary,
          l10n: l10n,
          period: period,
          snap: snapAsync.valueOrNull,
          onAlerts: onAlerts,
          onMaintenance: onMaintenance,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PremiumQuickActionsRow(l10n: l10n),
        const SizedBox(height: AppSpacing.sm),
        _FleetIntelHomePromoTile(l10n: l10n),
      ],
    );
  }
}

/// Subtle sync indicator shown during silentLight / medium refresh.
class _SubtleSyncIndicator extends StatelessWidget {
  const _SubtleSyncIndicator({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.accent.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.dashboardSyncInProgress,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Computes the UI badge from the dual [AppConnectionStatus] + [LiveSyncStatus].
///
/// Rule: the app is "online" as long as REST calls succeed recently,
/// regardless of WebSocket health.
_FleetConnectionBadge _computeConnectionBadge(
  AppConnectionStatus appStatus,
  LiveSyncStatus liveStatus,
) {
  switch (appStatus) {
    case AppConnectionStatus.offline:
      return _FleetConnectionBadge.offline;
    case AppConnectionStatus.serverUnavailable:
      return _FleetConnectionBadge.serverUnavailable;
    case AppConnectionStatus.unauthorized:
      return _FleetConnectionBadge.sessionExpired;
    case AppConnectionStatus.checking:
      return _FleetConnectionBadge.checking;
    case AppConnectionStatus.error:
      return _FleetConnectionBadge.offline;
    case AppConnectionStatus.online:
      break;
  }

  return switch (liveStatus) {
    LiveSyncStatus.connected => _FleetConnectionBadge.live,
    LiveSyncStatus.degraded => _FleetConnectionBadge.liveDegraded,
    LiveSyncStatus.reconnecting => _FleetConnectionBadge.liveReconnecting,
    LiveSyncStatus.disconnected => _FleetConnectionBadge.liveDegraded,
    LiveSyncStatus.idle => _FleetConnectionBadge.live,
  };
}

String _dashboardAccountBrand(UserEntity? user, AppLocalizations l10n) {
  if (user == null) return l10n.appName;
  final org = user.organization?.trim();
  if (org != null && org.isNotEmpty) return org;
  final email = user.email.trim();
  final at = email.indexOf('@');
  if (at > 0) return email.substring(0, at);
  return user.name;
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DashboardPremiumHeader extends StatelessWidget {
  const _DashboardPremiumHeader({
    required this.user,
    required this.l10n,
    required this.unreadNotifications,
    required this.onNotifications,
    required this.onSettings,
    this.summary,
  });

  final UserEntity? user;
  final AppLocalizations l10n;
  final int unreadNotifications;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final DashboardSummary? summary;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = _dashboardAccountBrand(user, l10n);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // شعار Elmo GPS
            Image.asset(
              isDark ? 'assets/images/elmo-02.png' : 'assets/images/elmogps.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderRoundIconButton(
                      icon: Icons.notifications_outlined,
                      badgeCount: unreadNotifications,
                      onTap: onNotifications,
                    ),
                    const SizedBox(width: 8),
                    _HeaderRoundIconButton(
                      icon: Icons.manage_accounts_outlined,
                      onTap: onSettings,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.2,
                      color: cs.onSurface.withValues(alpha: 0.42),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      l10n.fleetSummaryBar(
                        summary!.totalVehicles - summary!.offlineVehicles,
                        summary!.totalVehicles,
                        summary!.movingVehicles,
                        summary!.idleVehicles,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: cs.onSurface.withValues(alpha: 0.50),
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
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.0),
                AppColors.accent.withValues(alpha: 0.55),
                AppColors.accent.withValues(alpha: 0.25),
                AppColors.accent.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderRoundIconButton extends StatelessWidget {
  const _HeaderRoundIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.52),
      shape: const CircleBorder(),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 21,
                color: cs.onSurface.withValues(alpha: 0.74),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.rose,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.surface.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 15, minHeight: 15),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
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

// ── Hero & premium strip ──────────────────────────────────────────────────────

class _FleetHeroConnectionBadge extends StatelessWidget {
  const _FleetHeroConnectionBadge({required this.badge});

  final _FleetConnectionBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final (label, dotColor, borderColor, bgAlpha) = switch (badge) {
      _FleetConnectionBadge.live => (
          l10n.dashboardConnectionLive,
          AppColors.statusMoving,
          AppColors.statusMoving.withValues(alpha: 0.45),
          AppColors.statusMoving.withValues(alpha: 0.14),
        ),
      _FleetConnectionBadge.liveDegraded => (
          l10n.dashboardConnectionDegraded,
          AppColors.amber,
          AppColors.amber.withValues(alpha: 0.45),
          AppColors.amber.withValues(alpha: 0.14),
        ),
      _FleetConnectionBadge.liveReconnecting => (
          l10n.dashboardConnectionLiveReconnecting,
          AppColors.amber,
          AppColors.amber.withValues(alpha: 0.5),
          AppColors.amber.withValues(alpha: 0.14),
        ),
      _FleetConnectionBadge.offline => (
          l10n.dashboardConnectionOffline,
          AppColors.statusOffline,
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.06),
        ),
      _FleetConnectionBadge.serverUnavailable => (
          l10n.dashboardConnectionServerUnavailable,
          AppColors.statusOffline,
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.06),
        ),
      _FleetConnectionBadge.sessionExpired => (
          l10n.dashboardConnectionSessionExpired,
          AppColors.statusOffline,
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.06),
        ),
      _FleetConnectionBadge.checking => (
          l10n.dashboardConnectionChecking,
          Colors.white70,
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.06),
        ),
    };

    final hasGlow = badge == _FleetConnectionBadge.live;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgAlpha,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: hasGlow
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.55),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.summary,
    required this.l10n,
    required this.connectionBadge,
    required this.isLive,
  });

  final DashboardSummary summary;
  final AppLocalizations l10n;
  final _FleetConnectionBadge connectionBadge;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    const Color(0xFF0B2345),
                    AppColors.accentDark.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            right: -36,
            top: -44,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.fleetIntelligenceTitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                      ),
                    ),
                    _FleetHeroConnectionBadge(badge: connectionBadge),
                  ],
                ),
                if (summary.totalVehicles > 0 &&
                    summary.offlineVehicles == summary.totalVehicles) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.55)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.dashboardNoActivityToday,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.2,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedLiveNumber(
                            value: summary.totalVehicles,
                            isLive: isLive,
                            flashColor: AppColors.accentLight,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 44,
                              height: 1.05,
                              letterSpacing: -1,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.totalVehicles.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _FleetHeroMiniStat(
                            label: l10n.moving,
                            value: summary.movingVehicles,
                            dotColor: AppColors.statusMoving,
                          ),
                          _FleetHeroMiniStat(
                            label: l10n.stopped,
                            value: summary.stoppedVehicles,
                            dotColor: AppColors.statusStopped,
                          ),
                          _FleetHeroMiniStat(
                            label: l10n.idle,
                            value: summary.idleVehicles,
                            dotColor: AppColors.statusIdle,
                          ),
                          _FleetHeroMiniStat(
                            label: l10n.offline,
                            value: summary.offlineVehicles,
                            dotColor: AppColors.statusOffline,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetHeroMiniStat extends StatelessWidget {
  const _FleetHeroMiniStat({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  final String label;
  final int value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.78),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPremiumStatStrip extends StatelessWidget {
  const _DashboardPremiumStatStrip({
    required this.summary,
    required this.l10n,
    required this.period,
    required this.snap,
    required this.onAlerts,
    required this.onMaintenance,
  });

  final DashboardSummary summary;
  final AppLocalizations l10n;
  final FleetDashboardPeriod period;
  final FleetAdminSnapshot? snap;
  final VoidCallback onAlerts;
  final VoidCallback onMaintenance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final snapOk = snap != null && snap!.tripsEventsError == null;

    final String distLabel;
    if (period == FleetDashboardPeriod.today) {
      distLabel = snapOk
          ? FormatUtils.distance(snap!.periodDistanceMeters)
          : FormatUtils.distance(summary.totalDistanceToday);
    } else {
      distLabel = snapOk
          ? FormatUtils.distance(snap!.periodDistanceMeters)
          : l10n.notAvailable;
    }

    final distQuiet = snapOk
        ? snap!.periodDistanceMeters <= 0
        : (period == FleetDashboardPeriod.today &&
            summary.totalDistanceToday <= 0);

    final String alertsVal;
    if (period == FleetDashboardPeriod.today) {
      alertsVal = snapOk
          ? '${snap!.periodImportantAlertsCount}'
          : '${summary.alertsToday}';
    } else {
      alertsVal =
          snapOk ? '${snap!.periodImportantAlertsCount}' : l10n.notAvailable;
    }

    final overdueCount = snap?.maintenanceOverdueVehicleCount ?? 0;
    final alertsQuiet = snapOk
        ? snap!.periodImportantAlertsCount == 0
        : (period == FleetDashboardPeriod.today && summary.alertsToday == 0);

    Widget tile({
      required IconData icon,
      required Color accent,
      required String title,
      required String value,
      String? subtitle,
      VoidCallback? onTap,
    }) {
      return Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withValues(alpha: 0.48),
                        ),
                        maxLines: 2,
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            color: cs.onSurface.withValues(alpha: 0.42),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: accent.withValues(alpha: 0.65)),
              ],
            ),
          ),
        ),
      );
    }

    final rowChildren = <Widget>[
      Expanded(
        child: tile(
          icon: Icons.notifications_active_outlined,
          accent: AppColors.amber,
          title: l10n.dashboardImportantAlertsLabel,
          value: alertsVal,
          subtitle: alertsQuiet ? l10n.dashboardNoImportantAlerts : null,
          onTap: onAlerts,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: tile(
          icon: Icons.route_rounded,
          accent: AppColors.accent,
          title: period == FleetDashboardPeriod.today
              ? l10n.distanceToday
              : l10n.periodTotalDistance,
          value: distLabel,
          subtitle: distQuiet ? l10n.dashboardDistanceQuietHint : null,
        ),
      ),
    ];

    final secondRow = <Widget>[];
    if (overdueCount > 0) {
      secondRow.add(
        Expanded(
          child: tile(
            icon: Icons.build_circle_outlined,
            accent: AppColors.rose,
            title: l10n.maintenanceOverdueCount,
            value: '$overdueCount',
            onTap: onMaintenance,
          ),
        ),
      );
    }
    if (period == FleetDashboardPeriod.today) {
      if (secondRow.isNotEmpty) secondRow.add(const SizedBox(width: 10));
      secondRow.add(
        Expanded(
          child: tile(
            icon: Icons.alt_route_rounded,
            accent: AppColors.purple.withValues(alpha: 0.85),
            title: l10n.tripsToday,
            value: '${summary.tripsToday}',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: secondRow,
          ),
        ],
      ],
    );
  }
}

class _FleetIntelHomePromoTile extends StatelessWidget {
  const _FleetIntelHomePromoTile({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/fleet-intelligence'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.insights_outlined,
                      size: 18,
                      color: AppColors.accent.withValues(alpha: 0.92)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.fleetIntelTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumQuickActionsRow extends StatelessWidget {
  const _PremiumQuickActionsRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      (Icons.directions_car_rounded, l10n.vehicles, '/vehicles'),
      (Icons.map_outlined, l10n.liveMap, '/map'),
      (Icons.assessment_outlined, l10n.navReports, '/reports'),
      (Icons.insights_outlined, l10n.analytics, '/analytics'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: _QuickActionCell(
                  icon: items[i].$1,
                  label: items[i].$2,
                  onTap: () => context.go(items[i].$3),
                ),
              ),
              if (i < items.length - 1)
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: cs.outline.withValues(alpha: 0.12),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionCell extends StatelessWidget {
  const _QuickActionCell({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22, color: AppColors.accent.withValues(alpha: 0.92)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: cs.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period + Refresh row ──────────────────────────────────────────────────────

class _PeriodRefreshRow extends StatefulWidget {
  const _PeriodRefreshRow({
    required this.period,
    required this.l10n,
    required this.onPeriodChanged,
    required this.onRefresh,
  });

  final FleetDashboardPeriod period;
  final AppLocalizations l10n;
  final ValueChanged<FleetDashboardPeriod> onPeriodChanged;
  final VoidCallback onRefresh;

  @override
  State<_PeriodRefreshRow> createState() => _PeriodRefreshRowState();
}

class _PeriodRefreshRowState extends State<_PeriodRefreshRow> {
  DateTime _lastRefresh = DateTime.now();

  String _formattedTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: FleetDashboardPeriod.values.map((p) {
              final sel = p == widget.period;
              final label = switch (p) {
                FleetDashboardPeriod.today => widget.l10n.periodToday,
                FleetDashboardPeriod.week => widget.l10n.periodThisWeek,
                FleetDashboardPeriod.month => widget.l10n.periodThisMonth,
              };
              return ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: sel,
                onSelected: (_) => widget.onPeriodChanged(p),
                selectedColor: AppColors.accent.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: sel ? AppColors.accent : null,
                  fontWeight: sel ? FontWeight.w700 : null,
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                setState(() => _lastRefresh = DateTime.now());
                widget.onRefresh();
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: widget.l10n.refreshTooltip,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                foregroundColor: AppColors.accent,
              ),
            ),
            Text(
              _formattedTime(_lastRefresh),
              style: TextStyle(
                fontSize: 9.5,
                color: cs.onSurface.withValues(alpha: 0.42),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Period detail sections ────────────────────────────────────────────────────

class _PeriodDetailSection extends StatelessWidget {
  const _PeriodDetailSection({
    required this.snapshot,
    required this.l10n,
    required this.period,
  });

  final FleetAdminSnapshot snapshot;
  final AppLocalizations l10n;
  final FleetDashboardPeriod period;

  @override
  Widget build(BuildContext context) {
    final err = snapshot.tripsEventsError != null;
    final hasDriverData = snapshot.driverRows.isNotEmpty ||
        snapshot.driversLicenseAttention.isNotEmpty;
    final hasUtilizationData = !err && snapshot.utilizationRows.isNotEmpty;

    final quietFleet = !err &&
        snapshot.vehiclesActiveInPeriod == 0 &&
        snapshot.periodDistanceMeters <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!err) ...[
          const SizedBox(height: AppSpacing.sm),
          _ActivePeriodStat(
            quietFleet: quietFleet,
            period: period,
            vehiclesActiveInPeriod: snapshot.vehiclesActiveInPeriod,
            l10n: l10n,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // ── Vehicle activity ─────────────────────────────────────────────
        _SectionCard(
          title: l10n.vehicleActivitySection,
          child: err
              ? Text(
                  l10n.notAvailable,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final vehicleActivityPlaceholder = quietFleet ||
                        (snapshot.activityTop.isEmpty &&
                            snapshot.activityInactive.isEmpty);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!vehicleActivityPlaceholder) ...[
                          if (snapshot.activityTop.isNotEmpty) ...[
                            Text(l10n.mostActiveVehicles,
                                style: _subhead(context)),
                            ...snapshot.activityTop
                                .take(3)
                                .toList()
                                .asMap()
                                .entries
                                .map((e) {
                              final a = e.value;
                              return _ActivityLine(
                                rank: e.key + 1,
                                name: a.vehicleName,
                                distance:
                                    FormatUtils.distance(a.distanceMeters),
                                duration:
                                    DateFormatter.duration(a.movementSeconds),
                                offline: a.isOffline,
                                problem: a.hasIssue,
                                l10n: l10n,
                                onTap: () =>
                                    context.push('/vehicles/${a.deviceId}'),
                              );
                            }),
                          ],
                          if (snapshot.activityInactive.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(l10n.leastActiveVehicles,
                                style: _subhead(context)),
                            ...snapshot.activityInactive.take(2).map((a) {
                              return _ActivityLine(
                                rank: 0,
                                name: a.vehicleName,
                                distance:
                                    FormatUtils.distance(a.distanceMeters),
                                duration: a.isOffline ? l10n.offline : '—',
                                offline: a.isOffline,
                                problem: a.hasIssue,
                                l10n: l10n,
                                onTap: () =>
                                    context.push('/vehicles/${a.deviceId}'),
                              );
                            }),
                          ],
                        ] else
                          const _VehicleActivityEmptyRow(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go('/vehicles'),
                            style: _dashboardFooterLinkStyle(context),
                            child: Text(l10n.dashboardViewFullFleet),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 18),
        // ── Driver ranking (only if data exists) ─────────────────────────
        if (hasDriverData) ...[
          _SectionCard(
            title: l10n.driverRankingSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerLow
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.07),
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Text(
                      l10n.driverRankEstimatedNote,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.35,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...snapshot.driverRows
                    .take(3)
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  final r = e.value;
                  return _DriverRankRow(
                    rank: e.key + 1,
                    name: r.driver.name,
                    distance: FormatUtils.distance(r.distanceMeters),
                    alertCount: r.importantAlertCount,
                    overspeedCount: r.overspeedCount,
                    alertLabel: l10n.allAlerts,
                    overspeedLabel: l10n.overspeedEvents,
                    onTap: () => context.push('/drivers/${r.driver.id}'),
                  );
                }),
                if (snapshot.driverRows.length > 3)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/drivers'),
                      style: _dashboardFooterLinkStyle(context),
                      child: Text(l10n.viewAll),
                    ),
                  ),
                if (snapshot.driversLicenseAttention.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.08),
                    ),
                  ),
                  Text(l10n.licenseAttentionTitle, style: _subhead(context)),
                  ...snapshot.driversLicenseAttention.map((d) {
                    final st = d.licenseStatus(DateTime.now());
                    final isExpired = st == DriverLicenseStatus.expired;
                    final tag = isExpired
                        ? l10n.fleetAlertLicenseExpiredTitle
                        : l10n.fleetAlertLicenseSoonTitle;
                    return _LicenseBadgeRow(
                      name: d.name,
                      tag: tag,
                      isExpired: isExpired,
                      onTap: () => context.push('/drivers/${d.id}'),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        // ── Maintenance overview ──────────────────────────────────────────
        _SectionCard(
          title: l10n.maintenanceOverviewSection,
          onSectionTap: () => context.push('/maintenance'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshot.maintenanceUpcoming == 0 &&
                  snapshot.maintenanceSoon == 0 &&
                  snapshot.maintenanceOverdueRecords == 0)
                _PositiveEmptyState(text: l10n.dashboardNoUrgentMaintenance)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (snapshot.maintenanceUpcoming > 0)
                      _CountPill(
                        l10n.maintenanceUpcomingCount,
                        '${snapshot.maintenanceUpcoming}',
                        AppColors.statusMoving,
                      ),
                    if (snapshot.maintenanceSoon > 0)
                      _CountPill(
                        l10n.maintenanceSoonCount,
                        '${snapshot.maintenanceSoon}',
                        AppColors.amber,
                      ),
                    if (snapshot.maintenanceOverdueRecords > 0)
                      _CountPill(
                        l10n.maintenanceOverdueCount,
                        '${snapshot.maintenanceOverdueRecords}',
                        AppColors.rose,
                      ),
                  ],
                ),
              if (snapshot.nextMaintenances.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(l10n.nextMaintenances, style: _subhead(context)),
                ...snapshot.nextMaintenances.map((m) {
                  final days = m.daysUntilDue;
                  final isOverdue = (days ?? 0) < 0;
                  final dueStr = days == null
                      ? ''
                      : isOverdue
                          ? '${l10n.maintenanceOverdueCount} (${-days}d)'
                          : '${days}d';
                  return _MaintenanceRow(
                    title:
                        '${l10n.maintenanceTypeLocalized(m.record.maintenanceTypeCode ?? 'other')} — ${m.vehicleName}',
                    dueStr: dueStr,
                    isOverdue: isOverdue,
                  );
                }),
              ],
              if (snapshot.overdueMaintenanceVehicleNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(l10n.maintenanceOverdueVehicles, style: _subhead(context)),
                const SizedBox(height: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.rose.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Text(
                      snapshot.overdueMaintenanceVehicleNames
                          .take(5)
                          .join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        // ── Alerts overview ───────────────────────────────────────────────
        _SectionCard(
          title: l10n.alertsOverviewSection,
          onSectionTap: () => context.go('/alerts'),
          child: err
              ? Text(
                  l10n.notAvailable,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                )
              : snapshot.periodImportantAlertsCount == 0
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: AppColors.statusMoving.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.dashboardNoImportantAlerts,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.48),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.amber.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${snapshot.periodImportantAlertsCount}',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    color: AppColors.amberDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.alertsTotalPeriod,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.72),
                                          ),
                                        ),
                                        if (snapshot.overspeedCount > 0 ||
                                            snapshot.geofenceCount > 0)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              [
                                                if (snapshot.overspeedCount > 0)
                                                  '${l10n.alertsOverspeed}: ${snapshot.overspeedCount}',
                                                if (snapshot.geofenceCount > 0)
                                                  '${l10n.alertsGeofence}: ${snapshot.geofenceCount}',
                                              ].join('  ·  '),
                                              style: TextStyle(
                                                fontSize: 10,
                                                height: 1.25,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.48),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (snapshot.recentImportantEvents.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(l10n.lastImportantEvents,
                              style: _subhead(context)),
                          ...snapshot.recentImportantEvents.take(3).map((e) {
                            return _AlertEventRow(
                              type: e.type,
                              typeLabel: l10n.fleetEventTypeLabel(e.type),
                              vehicleName: e.vehicleName,
                              time: DateFormatter.toTime(e.eventTime),
                              onTap: () => context.push('/reports'),
                            );
                          }),
                          if (snapshot.recentImportantEvents.length > 3)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.go('/alerts'),
                                style: _dashboardFooterLinkStyle(context),
                                child: Text(l10n.viewAll),
                              ),
                            ),
                        ],
                      ],
                    ),
        ),
        // ── Vehicle utilization (only if data exists) ─────────────────────
        if (hasUtilizationData) ...[
          const SizedBox(height: 18),
          _SectionCard(
            title: l10n.vehicleUtilizationSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...snapshot.utilizationRows.take(3).map((u) {
                  return _UtilizationRow(
                    vehicleName: u.vehicleName,
                    distance: FormatUtils.distance(u.distanceMeters),
                    duration: DateFormatter.duration(u.movementSeconds),
                    score: u.utilizationScore,
                    isOffline: u.isOffline,
                    offlineLabel: l10n.offline,
                  );
                }),
                if (snapshot.utilizationRows.length > 3)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/vehicles'),
                      style: _dashboardFooterLinkStyle(context),
                      child: Text(l10n.dashboardViewFullFleet),
                    ),
                  ),
              ],
            ),
          ),
        ],
        SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.xl),
      ],
    );
  }

  TextStyle _subhead(BuildContext context) => TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.15,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
      );
}

ButtonStyle _dashboardFooterLinkStyle(BuildContext context) {
  return TextButton.styleFrom(
    foregroundColor: AppColors.accent,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

Color _dashboardInsetFill(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? cs.surfaceContainerLow.withValues(alpha: 0.38)
      : cs.surface.withValues(alpha: 0.88);
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _VehicleActivityEmptyRow extends StatelessWidget {
  const _VehicleActivityEmptyRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car_outlined,
                    size: 17,
                    color: AppColors.accent.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardVehicleActivityEmpty,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: cs.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.dashboardNoActivityToday,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: cs.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.go('/vehicles'),
              icon: const Icon(Icons.directions_car_rounded, size: 14),
              label: Text(l10n.dashboardViewFullFleet),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.accent,
                backgroundColor: AppColors.accent.withValues(alpha: 0.07),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositiveEmptyState extends StatelessWidget {
  const _PositiveEmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 15,
            color: AppColors.statusMoving.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTypeIcon extends StatelessWidget {
  const _AlertTypeIcon({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'overspeed' || 'speeding' => (
          Icons.speed_rounded,
          AppColors.rose,
        ),
      'geofence' || 'geofenceEnter' || 'geofenceExit' => (
          Icons.fence_rounded,
          AppColors.purple
        ),
      'deviceOnline' || 'deviceOffline' => (
          Icons.wifi_rounded,
          AppColors.accent,
        ),
      _ => (Icons.warning_amber_rounded, AppColors.amber),
    };
    return Icon(icon, size: 18, color: color);
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({
    required this.rank,
    required this.name,
    required this.distance,
    required this.duration,
    required this.offline,
    required this.l10n,
    required this.problem,
    required this.onTap,
  });

  final int rank;
  final String name;
  final String distance;
  final String duration;
  final bool offline;
  final AppLocalizations l10n;
  final bool problem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? statusColor;
    String? statusLabel;
    if (offline) {
      statusColor = AppColors.statusOffline;
      statusLabel = l10n.offline;
    } else if (problem) {
      statusColor = AppColors.amber;
      statusLabel = l10n.fleetStatusProblem;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _dashboardInsetFill(context),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (rank > 0)
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$rank.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          if (statusColor != null && statusLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.11),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$distance — $duration',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.28)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SoftWarningBanner extends StatelessWidget {
  const _SoftWarningBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.onSectionTap,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSectionTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inner = Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent,
                      AppColors.accentDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    height: 1.15,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (onSectionTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: cs.onSurface.withValues(alpha: 0.38),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outline.withValues(alpha: isDark ? 0.14 : 0.085),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.048),
            blurRadius: isDark ? 18 : 14,
            offset: const Offset(0, 7),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.52 : 0.92),
            cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.26 : 0.5),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: onSectionTap != null
              ? InkWell(
                  onTap: onSectionTap,
                  child: inner,
                )
              : inner,
        ),
      ),
    );
  }
}

class _SectionSkeleton extends StatefulWidget {
  const _SectionSkeleton();

  @override
  State<_SectionSkeleton> createState() => _SectionSkeletonState();
}

class _SectionSkeletonState extends State<_SectionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero card skeleton
            Container(
              height: 116,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: base,
              ),
            ),
            const SizedBox(height: 10),
            // Stats strip skeleton
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: base.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: base.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Quick actions skeleton
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: base.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.error.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 24,
              color: AppColors.error.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: Text(l10n.retry),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.accent,
              backgroundColor: AppColors.accent.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Period detail — premium row widgets ──────────────────────────────────────

class _ActivePeriodStat extends StatelessWidget {
  const _ActivePeriodStat({
    required this.quietFleet,
    required this.period,
    required this.vehiclesActiveInPeriod,
    required this.l10n,
  });

  final bool quietFleet;
  final FleetDashboardPeriod period;
  final int vehiclesActiveInPeriod;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (quietFleet) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.nights_stay_outlined,
            size: 14,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 6),
          Text(
            period == FleetDashboardPeriod.today
                ? l10n.dashboardNoActivityToday
                : l10n.dashboardNoActivityPeriod,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface.withValues(alpha: 0.42),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 13,
            color: AppColors.accent.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 5),
          Text(
            '${l10n.vehiclesActiveInPeriod}: $vehiclesActiveInPeriod',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRankRow extends StatelessWidget {
  const _DriverRankRow({
    required this.rank,
    required this.name,
    required this.distance,
    required this.alertCount,
    required this.overspeedCount,
    required this.alertLabel,
    required this.overspeedLabel,
    required this.onTap,
  });

  final int rank;
  final String name;
  final String distance;
  final int alertCount;
  final int overspeedCount;
  final String alertLabel;
  final String overspeedLabel;
  final VoidCallback onTap;

  Color _rankColor() => switch (rank) {
        1 => const Color(0xFFFFB300),
        2 => const Color(0xFF9E9E9E),
        3 => const Color(0xFFBF7D44),
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rankColor = _rankColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _dashboardInsetFill(context),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rankColor.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rankColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InlineStatChip(
                            icon: Icons.route_rounded,
                            label: distance,
                            color: AppColors.accent,
                          ),
                          if (alertCount > 0)
                            _InlineStatChip(
                              icon: Icons.warning_amber_rounded,
                              label: '$alertCount $alertLabel',
                              color: AppColors.amber,
                            ),
                          if (overspeedCount > 0)
                            _InlineStatChip(
                              icon: Icons.speed_rounded,
                              label: '$overspeedCount $overspeedLabel',
                              color: AppColors.rose,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineStatChip extends StatelessWidget {
  const _InlineStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withValues(alpha: 0.75)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _LicenseBadgeRow extends StatelessWidget {
  const _LicenseBadgeRow({
    required this.name,
    required this.tag,
    required this.isExpired,
    required this.onTap,
  });

  final String name;
  final String tag;
  final bool isExpired;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isExpired ? AppColors.rose : AppColors.amber;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _dashboardInsetFill(context),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.22),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.badge_outlined, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.26)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({
    required this.title,
    required this.dueStr,
    required this.isOverdue,
  });

  final String title;
  final String dueStr;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? AppColors.rose : AppColors.amber;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _dashboardInsetFill(context),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child:
                    Icon(Icons.build_circle_outlined, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (dueStr.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    dueStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertEventRow extends StatelessWidget {
  const _AlertEventRow({
    required this.type,
    required this.typeLabel,
    required this.vehicleName,
    required this.time,
    required this.onTap,
  });

  final String type;
  final String typeLabel;
  final String vehicleName;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _dashboardInsetFill(context),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.08),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _AlertTypeIcon(type: type),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        vehicleName,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          color: cs.onSurface.withValues(alpha: 0.48),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.42),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilizationRow extends StatelessWidget {
  const _UtilizationRow({
    required this.vehicleName,
    required this.distance,
    required this.duration,
    required this.score,
    required this.isOffline,
    required this.offlineLabel,
  });

  final String vehicleName;
  final String distance;
  final String duration;
  final double score;
  final bool isOffline;
  final String offlineLabel;

  Color _scoreColor() => score >= 70
      ? AppColors.statusMoving
      : score >= 40
          ? AppColors.amber
          : AppColors.rose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scoreColor = _scoreColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _dashboardInsetFill(context),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vehicleName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isOffline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusOffline.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.statusOffline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        offlineLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.statusOffline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0.0, 1.0),
                        backgroundColor:
                            cs.surfaceContainerHighest.withValues(alpha: 0.55),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            scoreColor.withValues(alpha: 0.7)),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$distance · $duration',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.44),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
