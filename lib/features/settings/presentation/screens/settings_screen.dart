import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Profile card
              ElmoCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.accent.withOpacity(0.15),
                      child: Text(
                        user?.initials ?? 'U',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Fleet Manager',
                            style: AppTextStyles.headlineSmall,
                          ),
                          Text(
                            user?.email ?? '',
                            style: AppTextStyles.bodySmall,
                          ),
                          if (user?.organization != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              user!.organization!,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.accent),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              Text('Fleet', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              _SettingsGroup(
                items: [
                  _SettingsTile(
                    icon: Icons.directions_car_rounded,
                    label: 'Vehicles',
                    onTap: () => context.go('/vehicles'),
                  ),
                  _SettingsTile(
                    icon: Icons.map_rounded,
                    label: 'Live Map',
                    onTap: () => context.go('/map'),
                  ),
                  _SettingsTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    onTap: () => context.go('/analytics'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              Text('Preferences', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              _SettingsGroup(
                items: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.push('/notifications'),
                    trailing: _Badge(
                      count: ref.watch(
                        Provider((ref) => ref.watch(
                              authProvider.select((_) => 0),
                            )),
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                  const _SwitchTile(
                    icon: Icons.dark_mode_rounded,
                    label: 'Dark Mode',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              Text('Account', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              _SettingsGroup(
                items: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About ELMO',
                    subtitle: 'v1.0.0',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: AppColors.error,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxxl),
              Center(
                child: Text(
                  'ELMO Fleet Intelligence\n© 2025 All rights reserved',
                  style: AppTextStyles.labelSmall.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out', style: AppTextStyles.headlineMedium),
        content: const Text(
          'Are you sure you want to sign out?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: List.generate(items.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(
              height: 0,
              thickness: 0.5,
              indent: 50,
            );
          }
          return items[i ~/ 2];
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.bodySmall)
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 18),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 2),
    );
  }
}

class _SwitchTile extends ConsumerWidget {
  const _SwitchTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: Switch(
        value: true,
        onChanged: (_) {},
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 2),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const Icon(Icons.chevron_right_rounded,
        color: AppColors.textMuted, size: 18);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.textMuted, size: 18),
      ],
    );
  }
}
