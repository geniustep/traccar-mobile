import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/alerts_provider.dart';
import '../../domain/entities/alert.dart';

final smartAlertsProvider = FutureProvider.autoDispose<List<AlertEntity>>((ref) {
  return ref.read(alertsRepositoryProvider).getSmartAlerts();
});

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);
    final unread = ref.watch(unreadAlertsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Alerts'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all read',
            onPressed: alertsAsync.hasValue
                ? () {
                    alertsAsync.value!.forEach(
                      (a) => ref.read(alertsProvider.notifier).markAsRead(a.id),
                    );
                  }
                : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          tabs: const [
            Tab(text: 'All Alerts'),
            Tab(text: 'Smart Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AlertsList(
            alertsAsync: alertsAsync,
            onRetry: () => ref.read(alertsProvider.notifier).load(),
          ),
          _SmartAlertsList(),
        ],
      ),
    );
  }
}

class _AlertsList extends ConsumerWidget {
  const _AlertsList({required this.alertsAsync, required this.onRetry});

  final AsyncValue<List<AlertEntity>> alertsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return const EmptyView(
            icon: Icons.notifications_off_outlined,
            title: 'No alerts',
            message: 'Your fleet has no active alerts.',
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => ref.read(alertsProvider.notifier).load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final alert = alerts[i];
              return AlertCard(
                alert: alert,
                onTap: () {
                  context.push('/alerts/${alert.id}');
                  if (!alert.isRead) {
                    ref.read(alertsProvider.notifier).markAsRead(alert.id);
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const LoadingView(message: 'Loading alerts…'),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: onRetry),
    );
  }
}

class _SmartAlertsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final smartAsync = ref.watch(smartAlertsProvider);

    return smartAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return const EmptyView(
            icon: Icons.lightbulb_outline_rounded,
            title: 'No smart alerts',
            message: 'Critical patterns will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => AlertCard(alert: alerts[i]),
        );
      },
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap});

  final AlertEntity alert;
  final VoidCallback? onTap;

  static Color _severityColor(String s) => switch (s.toLowerCase()) {
        'critical' => AppColors.severityCritical,
        'high' => AppColors.severityHigh,
        'medium' => AppColors.severityMedium,
        'low' => AppColors.severityLow,
        _ => AppColors.accent,
      };

  static IconData _typeIcon(String type) => switch (type.toLowerCase()) {
        'overspeed' => Icons.speed_rounded,
        'geofence' => Icons.fence_rounded,
        'idle' => Icons.timer_rounded,
        'maintenance' => Icons.build_rounded,
        'battery' => Icons.battery_alert_rounded,
        'offline' => Icons.signal_wifi_off_rounded,
        _ => Icons.warning_amber_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    final icon = _typeIcon(alert.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: alert.isRead
                ? Theme.of(context).colorScheme.outline.withOpacity(0.4)
                : color.withOpacity(0.35),
            width: alert.isRead ? 0.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (!alert.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
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
                          alert.title,
                          style: AppTextStyles.labelLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SeverityBadge(severity: alert.severity),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(alert.vehicleName,
                          style: AppTextStyles.labelSmall),
                      const Spacer(),
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
    );
  }
}
