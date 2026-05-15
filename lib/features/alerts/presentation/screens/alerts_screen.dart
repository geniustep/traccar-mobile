import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/alerts_provider.dart';
import '../../domain/entities/alert.dart';
import '../../../geofences/presentation/providers/geofences_providers.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _filters = ['all', 'unread', 'read'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.alerts('Screen opened');
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final filter = _filters[_tabController.index];
    ref.read(alertsProvider.notifier).setFilter(filter);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final alertsState = ref.watch(alertsProvider);
    final unread = alertsState.unreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        elevation: 0,
        title: Row(
          children: [
            Text(
              l10n.navAlerts,
              style: AppTextStyles.headlineSmall
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              _UnreadBadge(count: unread),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            IconButton(
              icon: const Icon(
                Icons.done_all_rounded,
                color: AppColors.accent,
              ),
              tooltip: l10n.markAllRead,
              onPressed: () =>
                  ref.read(alertsProvider.notifier).markAllAsRead(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Column(
            children: [
              if (alertsState.alertsAsync.hasValue) ...[
                _AlertsSummaryBar(
                  alerts: alertsState.alertsAsync.value!,
                  unreadCount: unread,
                ),
                const SizedBox(height: 4),
              ],
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor:
                    isDark ? Colors.white54 : Colors.black54,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Toutes'),
                  Tab(text: 'Non lues'),
                  Tab(text: 'Lues'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (alertsState.hasVehicleFilter)
              _VehicleAlertsFilterBanner(
                vehicleName: alertsState.vehicleNameFilter ?? '',
                onClear: () =>
                    ref.read(alertsProvider.notifier).setVehicleFilter(null),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AlertsList(
                    onRetry: () => ref.read(alertsProvider.notifier).load(),
                  ),
                  _AlertsList(
                    onRetry: () => ref.read(alertsProvider.notifier).load(),
                  ),
                  _AlertsList(
                    onRetry: () => ref.read(alertsProvider.notifier).load(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vehicle filter banner ───────────────────────────────────────────────────

class _VehicleAlertsFilterBanner extends StatelessWidget {
  const _VehicleAlertsFilterBanner({
    required this.vehicleName,
    required this.onClear,
  });

  final String vehicleName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = vehicleName.isNotEmpty
        ? l10n.alertsForVehicleName(vehicleName)
        : l10n.alertsForVehicle;

    return Material(
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: 10,
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_rounded,
                size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(l10n.allAlerts),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary bar ─────────────────────────────────────────────────────────────

class _AlertsSummaryBar extends StatelessWidget {
  const _AlertsSummaryBar({
    required this.alerts,
    required this.unreadCount,
  });

  final List<AlertEntity> alerts;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty && unreadCount == 0) return const SizedBox.shrink();

    final critical = alerts
        .where((a) => a.severity == 'critical' || a.severity == 'high')
        .length;
    final warnings = alerts.where((a) => a.severity == 'medium').length;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: 6),
      child: Row(
        children: [
          _SummaryChip(
            label: '${alerts.length}',
            sublabel: 'Total',
            color: AppColors.accent,
            icon: Icons.notifications_rounded,
          ),
          const SizedBox(width: 8),
          if (critical > 0) ...[
            _SummaryChip(
              label: '$critical',
              sublabel: 'Critiques',
              color: AppColors.severityCritical,
              icon: Icons.error_rounded,
            ),
            const SizedBox(width: 8),
          ],
          if (warnings > 0) ...[
            _SummaryChip(
              label: '$warnings',
              sublabel: 'Avert.',
              color: AppColors.warning,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(width: 8),
          ],
          if (unreadCount > 0)
            _SummaryChip(
              label: '$unreadCount',
              sublabel: 'Non lues',
              color: const Color(0xFFFF4757),
              icon: Icons.mark_email_unread_rounded,
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
  });

  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unread badge ─────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Alerts list ───────────────────────────────────────────────────────────────

class _AlertsList extends ConsumerWidget {
  const _AlertsList({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final alertsState = ref.watch(alertsProvider);
    final alertsAsync = alertsState.alertsAsync;

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return _AlertsEmptyState(l10n: l10n);
        }
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            AppLogger.alerts('Refresh requested: source=pull_to_refresh');
            await ref.read(alertsProvider.notifier).load();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: alerts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final alert = alerts[i];
              return AlertCard(
                alert: alert,
                onTap: () {
                  context.push('/alerts/${alert.id}');
                },
              );
            },
          ),
        );
      },
      loading: () => _AlertsLoadingSkeleton(),
      error: (e, _) => _AlertsErrorState(
        onRetry: onRetry,
        l10n: l10n,
      ),
    );
  }
}

// ── Empty / Error / Loading states ────────────────────────────────────────────

class _AlertsEmptyState extends StatelessWidget {
  const _AlertsEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined,
                  size: 34, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noAlerts,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noAlertsMessage,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMutedOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsErrorState extends StatelessWidget {
  const _AlertsErrorState({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 30, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger les alertes',
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Vérifiez votre connexion et réessayez.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMutedOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertsLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const _AlertSkeletonCard(),
    );
  }
}

class _AlertSkeletonCard extends StatefulWidget {
  const _AlertSkeletonCard();

  @override
  State<_AlertSkeletonCard> createState() => _AlertSkeletonCardState();
}

class _AlertSkeletonCardState extends State<_AlertSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.85).animate(
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
    final base = AppColors.textMutedOf(context);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundOf(context),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
                color: AppColors.borderOf(context), width: 0.6),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: base.withValues(alpha: _anim.value * 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: _anim.value * 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 11,
                      width: 180,
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: _anim.value * 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 10,
                      width: 120,
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: _anim.value * 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class AlertCard extends ConsumerWidget {
  const AlertCard({super.key, required this.alert, this.onTap});

  final AlertEntity alert;
  final VoidCallback? onTap;

  static Color _severityColor(AlertEntity alert, String severity) {
    if (alert.type == 'geofenceEnter') return const Color(0xFF1E88E5);
    if (alert.type == 'geofenceExit') return const Color(0xFFFF9800);
    return switch (severity.toLowerCase()) {
      'critical' => AppColors.severityCritical,
      'high' => AppColors.severityHigh,
      'medium' => AppColors.severityMedium,
      'low' => AppColors.severityLow,
      _ => AppColors.accent,
    };
  }

  static IconData _typeIcon(String type) => switch (type.toLowerCase()) {
        'overspeed' || 'deviceoverspeed' => Icons.speed_rounded,
        'geofenceenter' || 'geofenceexit' || 'geofence' =>
          Icons.fence_rounded,
        'idle' => Icons.timer_rounded,
        'maintenance' => Icons.build_rounded,
        'battery' => Icons.battery_alert_rounded,
        'offline' || 'deviceoffline' => Icons.signal_wifi_off_rounded,
        'alarm' => Icons.warning_rounded,
        _ => Icons.notifications_active_rounded,
      };

  String _title(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final names = ref.watch(geofenceNameMapProvider);
    switch (alert.type) {
      case 'geofenceEnter':
        final zn =
            alert.geofenceId != null ? names[alert.geofenceId!] : null;
        if (zn != null) return '${l10n.geofenceZoneEntry} · $zn';
        return l10n.geofenceZoneEntry;
      case 'geofenceExit':
        final zn =
            alert.geofenceId != null ? names[alert.geofenceId!] : null;
        if (zn != null) return '${l10n.geofenceZoneExit} · $zn';
        return l10n.geofenceZoneExit;
      default:
        return alert.title;
    }
  }

  String _description(AppLocalizations l10n) {
    switch (alert.type) {
      case 'geofenceEnter':
      case 'geofenceExit':
        return alert.vehicleName.isNotEmpty
            ? alert.vehicleName
            : l10n.vehicleLabel;
      default:
        return alert.description;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final color = _severityColor(alert, alert.severity);
    final icon = _typeIcon(alert.type);
    final title = _title(context, ref, l10n);
    final desc = _description(l10n);
    final isUnread = !alert.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnread
              ? color.withValues(alpha: 0.04)
              : AppColors.cardBackgroundOf(context),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isUnread
                ? color.withValues(alpha: 0.28)
                : AppColors.borderOf(context).withValues(alpha: 0.5),
            width: isUnread ? 1.1 : 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.cardRadius),
                    bottomLeft: Radius.circular(AppSpacing.cardRadius),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          if (isUnread)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4757),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SeverityBadge(severity: alert.severity),
                              ],
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isUnread
                                      ? AppColors.textSecondaryOf(context)
                                      : AppColors.textMutedOf(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (alert.vehicleName.isNotEmpty) ...[
                                  Icon(Icons.directions_car_outlined,
                                      size: 11,
                                      color: AppColors.textMutedOf(context)),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      alert.vehicleName,
                                      style: AppTextStyles.labelSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ] else
                                  const Spacer(),
                                const SizedBox(width: 6),
                                if (isUnread)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4757)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Non lue',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF4757),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(Icons.access_time_rounded,
                                    size: 10,
                                    color: AppColors.textMutedOf(context)),
                                const SizedBox(width: 2),
                                Text(
                                  DateFormatter.toRelative(alert.createdAt),
                                  style: AppTextStyles.labelSmall,
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}
