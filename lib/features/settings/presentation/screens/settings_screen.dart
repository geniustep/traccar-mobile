import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../map/presentation/widgets/route_intelligence_thresholds_preview.dart';
import '../../../map/presentation/widgets/route_intelligence_thresholds_editor.dart';

// ── Notifications toggle provider ─────────────────────────────────────────────
final _notificationsEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user, l10n: l10n, isDark: isDark),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.xl),

                // ── Language ─────────────────────────────────────────────────
                _SectionLabel(l10n.language),
                const SizedBox(height: AppSpacing.sm),
                _LanguagePickerCard(isDark: isDark),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // ── Appearance ───────────────────────────────────────────────
                _SectionLabel(l10n.appearance),
                const SizedBox(height: AppSpacing.sm),
                _AppearanceCard(l10n: l10n, isDark: isDark),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // ── Fleet ────────────────────────────────────────────────────
                _SectionLabel(l10n.sectionFleet),
                const SizedBox(height: AppSpacing.sm),
                _SettingsGroup(isDark: isDark, children: [
                  _SettingsTile(
                    icon: Icons.directions_car_rounded,
                    iconColor: AppColors.accent,
                    label: l10n.vehicles,
                    isDark: isDark,
                    onTap: () => context.go('/vehicles'),
                  ),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.map_rounded,
                    iconColor: AppColors.emerald,
                    label: l10n.liveMap,
                    isDark: isDark,
                    onTap: () => context.go('/map'),
                  ),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.polyline_rounded,
                    iconColor: AppColors.accent,
                    label: l10n.geofencesTitle,
                    isDark: isDark,
                    onTap: () => context.push('/geofences'),
                  ),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.badge_rounded,
                    iconColor: AppColors.emerald,
                    label: l10n.driversTitle,
                    isDark: isDark,
                    onTap: () => context.push('/drivers'),
                  ),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.build_circle_outlined,
                    iconColor: AppColors.warning,
                    label: l10n.maintenanceTitle,
                    isDark: isDark,
                    onTap: () => context.push('/maintenance'),
                  ),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.purple,
                    label: l10n.analytics,
                    isDark: isDark,
                    onTap: () => context.go('/analytics'),
                  ),
                ]),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // ── Preferences ──────────────────────────────────────────────
                _SectionLabel(l10n.sectionPreferences),
                const SizedBox(height: AppSpacing.sm),
                _SectionLabel(l10n.routeIntelSettingsPreviewSection),
                const SizedBox(height: AppSpacing.xs),
                const RouteIntelligenceGlobalThresholdPreview(),
                const SizedBox(height: AppSpacing.md),
                const RouteIntelligenceLocalThresholdsEditor(),
                const SizedBox(height: AppSpacing.md),
                _SettingsGroup(isDark: isDark, children: [
                  _NotificationsTile(l10n: l10n, isDark: isDark),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.amber,
                    label: l10n.notifications,
                    isDark: isDark,
                    onTap: () => context.push('/notifications'),
                  ),
                ]),

                const SizedBox(height: AppSpacing.sectionSpacing),

                // ── Account ──────────────────────────────────────────────────
                _SectionLabel(l10n.sectionAccount),
                const SizedBox(height: AppSpacing.sm),
                _SettingsGroup(isDark: isDark, children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.accentLight,
                    label: l10n.aboutElmo,
                    subtitle: '${l10n.version} 1.0.0',
                    isDark: isDark,
                    onTap: () => _showAboutDialog(context, l10n),
                  ),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    iconColor: AppColors.textMuted,
                    label: l10n.privacyPolicy,
                    isDark: isDark,
                    onTap: () {},
                  ),
                  _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.textMuted,
                    label: l10n.helpSupport,
                    isDark: isDark,
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: AppSpacing.lg),

                // ── Sign out ─────────────────────────────────────────────────
                _SignOutButton(l10n: l10n, isDark: isDark),

                const SizedBox(height: AppSpacing.xxl),

                // ── Footer ───────────────────────────────────────────────────
                Center(
                  child: Text(
                    l10n.footerText,
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark ? AppColors.textMuted : AppColors.lightTextMuted)
                          .withValues(alpha: 0.7),
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Image.asset(
              isDark ? 'assets/images/elmo-02.png' : 'assets/images/elmogps.png',
              width: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            _AboutRow('${l10n.version}:', '1.0.0'),
            const SizedBox(height: 8),
            Text(
              l10n.aboutFleetTrackingSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(value),
          ],
        ],
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.l10n,
    required this.isDark,
  });

  final dynamic user;
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0E1521), Color(0xFF162030)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B2A), Color(0xFF1A3050)],
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: title + edit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // شعار Elmo GPS — long-press (debug) يفتح Debug Console الداخلي
                  GestureDetector(
                    onLongPress: kDebugMode
                        ? () => context.push('/debug-console')
                        : null,
                    child: Image.asset(
                      'assets/images/elmo-02.png',
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                  _GlassButton(
                    icon: Icons.edit_outlined,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // User info row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, AppColors.accentDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.initials ?? 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),

                  // Name + email + org
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? l10n.fleetManager,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (user?.email?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            user!.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB0C4D8),
                            ),
                          ),
                        ],
                        if (user?.organization != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              user!.organization!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentLight,
                              ),
                            ),
                          ),
                        ],
                      ],
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

// ── Glass button ───────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder, width: 0.8),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

// ── Language Picker ────────────────────────────────────────────────────────────

class _LanguagePickerCard extends ConsumerWidget {
  const _LanguagePickerCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return _SettingsGroup(
      isDark: isDark,
      children: appSupportedLocales.asMap().entries.map((entry) {
        final index = entry.key;
        final info = entry.value;
        final isSelected = info.locale.languageCode == currentLocale.languageCode;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0) _GroupDivider(),
            _LanguageOption(
              info: info,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => ref.read(localeProvider.notifier).setLocale(info.locale),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.info,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final LocaleInfo info;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: isDark ? 0.1 : 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            // Flag emoji
            Text(info.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: AppSpacing.md),

            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.nativeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.accent
                          : (isDark
                              ? AppColors.textPrimary
                              : AppColors.lightTextPrimary),
                    ),
                  ),
                  Text(
                    info.englishName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appearance Card ────────────────────────────────────────────────────────────

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return _SettingsGroup(
      isDark: isDark,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _ThemeOption(
                label: l10n.themeLight,
                icon: Icons.light_mode_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                ),
                iconColor: const Color(0xFFF59E0B),
                selected: themeMode == ThemeMode.light,
                isDark: isDark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                label: l10n.themeDark,
                icon: Icons.dark_mode_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A2E44), Color(0xFF0D1B2A)],
                ),
                iconColor: AppColors.accentLight,
                selected: themeMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                label: l10n.themeSystem,
                icon: Icons.settings_suggest_rounded,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF00B4D8)],
                ),
                iconColor: Colors.white,
                selected: themeMode == ThemeMode.system,
                isDark: isDark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color iconColor;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.border
                      : AppColors.lightBorder),
              width: selected ? 1.5 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius - 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient preview
                Container(
                  height: 52,
                  decoration: BoxDecoration(gradient: gradient),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                // Label
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.1)
                      : (isDark
                          ? AppColors.cardBackground
                          : AppColors.lightCardBackground),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.accent
                            : (isDark
                                ? AppColors.textSecondary
                                : AppColors.lightTextSecondary),
                      ),
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

// ── Notifications Tile ─────────────────────────────────────────────────────────

class _NotificationsTile extends ConsumerWidget {
  const _NotificationsTile({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(_notificationsEnabledProvider);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: AppColors.amber, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notificationsEnabled,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  l10n.notificationsSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (val) =>
                ref.read(_notificationsEnabledProvider.notifier).state = val,
          ),
        ],
      ),
    );
  }
}

// ── Sign Out Button ────────────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _confirmLogout(context, ref, l10n),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.signOut,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(
              l10n.signOut,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: isDark
            ? AppColors.textMuted
            : AppColors.lightTextMuted,
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: 52,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.isDark, required this.children});
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 0.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: cs.onSurface.withValues(alpha: 0.3),
        size: 18,
      ),
      dense: true,
    );
  }
}
