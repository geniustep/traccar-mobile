import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              // Profile card
              _SettingsGroup(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
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
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                              if (user?.organization != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user!.organization!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: cs.onSurface.withOpacity(0.4)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              _SectionLabel('Fleet'),
              const SizedBox(height: AppSpacing.sm),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.directions_car_rounded,
                    label: 'Vehicles',
                    onTap: () => context.go('/vehicles'),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.map_rounded,
                    label: 'Live Map',
                    onTap: () => context.go('/map'),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    onTap: () => context.go('/analytics'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              _SectionLabel('Preferences'),
              const SizedBox(height: AppSpacing.sm),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  _Divider(),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                  _Divider(),
                  // ── Theme selector ────────────────────────────────────
                  _ThemePickerTile(isDark: isDark),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionSpacing),

              _SectionLabel('Account'),
              const SizedBox(height: AppSpacing.sm),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About ELMO',
                    subtitle: 'v1.0.0',
                    onTap: () {},
                  ),
                  _Divider(),
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
                  style: AppTextStyles.labelSmall.copyWith(
                    color: cs.onSurface.withOpacity(0.4),
                    height: 1.6,
                  ),
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
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

// ── Theme Picker Tile ────────────────────────────────────────────────────────

class _ThemePickerTile extends ConsumerWidget {
  const _ThemePickerTile({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  color: cs.onSurface.withOpacity(0.6), size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Appearance',
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                selected: themeMode == ThemeMode.light,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                selected: themeMode == ThemeMode.dark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                label: 'System',
                icon: Icons.settings_suggest_rounded,
                selected: themeMode == ThemeMode.system,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.12)
                : cs.surface,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : cs.outline.withOpacity(0.5),
              width: selected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accent : cs.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.accent
                      : cs.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: 48,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: cs.outline.withOpacity(0.4), width: 0.6),
      ),
      child: Column(children: children),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelColor = color ?? cs.onSurface;
    final iconColor = color ?? cs.onSurface.withOpacity(0.6);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(color: labelColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: cs.onSurface.withOpacity(0.5),
              ),
            )
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurface.withOpacity(0.35), size: 18),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 2),
    );
  }
}
