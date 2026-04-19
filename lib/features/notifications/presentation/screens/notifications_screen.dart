import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/notifications_provider.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text('Notifications'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              message: 'You\'re all caught up!',
            );
          }

          // Group by date
          final groups = <String, List<AppNotification>>{};
          for (final n in notifications) {
            final key = DateFormatter.toDate(n.createdAt);
            groups.putIfAbsent(key, () => []).add(n);
          }

          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () async =>
                ref.read(notificationsProvider.notifier).load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final key = groups.keys.elementAt(i);
                final items = groups[key]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      child: Text(key, style: AppTextStyles.labelMedium),
                    ),
                    ...items.map((n) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: _NotificationItem(
                            notification: n,
                            onTap: () {
                              if (!n.isRead) {
                                ref
                                    .read(notificationsProvider.notifier)
                                    .markAsRead(n.id);
                              }
                              if (n.alertId != null) {
                                context.push('/alerts/${n.alertId}');
                              }
                            },
                          ),
                        )),
                  ],
                );
              },
            ),
          );
        },
        loading: () => const LoadingView(message: 'Loading notifications…'),
        error: (_, __) => const EmptyView(
          message: 'Failed to load notifications.',
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  static Color _categoryColor(String c) => switch (c.toLowerCase()) {
        'critical' => AppColors.severityCritical,
        'warning' => AppColors.warning,
        _ => AppColors.accent,
      };

  static IconData _categoryIcon(String c) => switch (c.toLowerCase()) {
        'critical' => Icons.error_rounded,
        'warning' => Icons.warning_amber_rounded,
        _ => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(notification.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.cardBackground
              : AppColors.accent.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : AppColors.accent.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(notification.category),
                  color: color, size: 18),
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
                          notification.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontSize: 13,
                            color: notification.isRead
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
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
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.toRelative(notification.createdAt),
                    style: AppTextStyles.labelSmall,
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
