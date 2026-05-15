import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/notifications_provider.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text(
              l10n.notifications,
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
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 15),
              label: Text(
                l10n.markAllRead,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return _NotificationsEmptyState(l10n: l10n);
            }

            // Summary bar
            final unreadCount = notifications.where((n) => !n.isRead).length;

            final groups = <String, List<AppNotification>>{};
            for (final n in notifications) {
              final key = DateFormatter.toDate(n.createdAt);
              groups.putIfAbsent(key, () => []).add(n);
            }

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async =>
                  ref.read(notificationsProvider.notifier).load(),
              child: CustomScrollView(
                slivers: [
                  // Top summary
                  if (unreadCount > 0)
                    SliverToBoxAdapter(
                      child: _NotificationsSummaryBanner(
                        total: notifications.length,
                        unread: unreadCount,
                      ),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final key = groups.keys.elementAt(i);
                        final items = groups[key]!;
                        return _NotificationGroup(
                          dateLabel: key,
                          items: items,
                          onTap: (n) {
                            if (!n.isRead) {
                              ref
                                  .read(notificationsProvider.notifier)
                                  .markAsRead(n.id);
                            }
                            if (n.alertId != null) {
                              context.push('/alerts/${n.alertId}');
                            }
                          },
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            );
          },
          loading: () => _NotificationsLoadingSkeleton(),
          error: (_, __) => _NotificationsErrorState(l10n: l10n,
            onRetry: () => ref.read(notificationsProvider.notifier).load(),
          ),
        ),
      ),
    );
  }
}

// ── Summary banner ────────────────────────────────────────────────────────────

class _NotificationsSummaryBanner extends StatelessWidget {
  const _NotificationsSummaryBanner({
    required this.total,
    required this.unread,
  });

  final int total;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_rounded,
              size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            '$unread notification${unread > 1 ? 's' : ''} non lue${unread > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const Spacer(),
          Text(
            '$total au total',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification group ────────────────────────────────────────────────────────

class _NotificationGroup extends StatelessWidget {
  const _NotificationGroup({
    required this.dateLabel,
    required this.items,
    required this.onTap,
  });

  final String dateLabel;
  final List<AppNotification> items;
  final void Function(AppNotification) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, AppSpacing.md, AppSpacing.screenPadding, 6),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.borderOf(context), width: 0.6),
                ),
                child: Text(
                  dateLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map(
          (n) => Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.sm),
            child: _NotificationItem(
              notification: n,
              onTap: () => onTap(n),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Notification item ─────────────────────────────────────────────────────────

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

  static String _categoryLabel(String c) => switch (c.toLowerCase()) {
        'critical' => 'Critique',
        'warning' => 'Avertissement',
        _ => 'Info',
      };

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(notification.category);
    final isUnread = !notification.isRead;

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
                ? color.withValues(alpha: 0.25)
                : AppColors.borderOf(context).withValues(alpha: 0.5),
            width: isUnread ? 1.0 : 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color strip
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: isUnread ? color : color.withValues(alpha: 0.3),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                            _categoryIcon(notification.category),
                            color: color,
                            size: 18),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + unread dot
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontSize: 13,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isUnread
                                          ? AppColors.textPrimaryOf(context)
                                          : AppColors.textSecondaryOf(context),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              notification.body,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isUnread
                                    ? AppColors.textSecondaryOf(context)
                                    : AppColors.textMutedOf(context),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Footer
                            Row(
                              children: [
                                // Category chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _categoryLabel(notification.category),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                                if (isUnread) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4757)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
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
                                ],
                                const Spacer(),
                                Icon(Icons.access_time_rounded,
                                    size: 10,
                                    color: AppColors.textMutedOf(context)),
                                const SizedBox(width: 2),
                                Text(
                                  DateFormatter.toRelative(
                                      notification.createdAt),
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

// ── Unread badge ──────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState({required this.l10n});
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
              child: const Icon(Icons.notifications_none_rounded,
                  size: 34, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noNotifications,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.allCaughtUp,
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

// ── Error state ───────────────────────────────────────────────────────────────

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({
    required this.l10n,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final VoidCallback onRetry;

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
            Text(
              l10n.failedToLoadNotifications,
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center,
            ),
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
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _NotificationsLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const _NotificationSkeletonCard(),
    );
  }
}

class _NotificationSkeletonCard extends StatefulWidget {
  const _NotificationSkeletonCard();

  @override
  State<_NotificationSkeletonCard> createState() =>
      _NotificationSkeletonCardState();
}

class _NotificationSkeletonCardState extends State<_NotificationSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.8).animate(
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: base.withValues(alpha: _anim.value * 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: _anim.value * 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 150,
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: _anim.value * 0.2),
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
