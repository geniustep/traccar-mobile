import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/elmo_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;

    if (success) {
      context.go('/dashboard');
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(error,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final l10n = context.l10n;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────────────
          _Background(isDark: isDark),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(isDark: isDark),

                // Scrollable form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28),
                            _LogoSection(isDark: isDark),
                            const SizedBox(height: 40),
                            _WelcomeHeader(isDark: isDark, l10n: l10n),
                            const SizedBox(height: 36),
                            _FormSection(
                              formKey: _formKey,
                              emailCtrl: _emailCtrl,
                              passwordCtrl: _passwordCtrl,
                              isLoading: authState.isLoading,
                              onSubmit: _handleLogin,
                              l10n: l10n,
                            ),
                            const SizedBox(height: 8),

                            // Error message
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: authState.error != null
                                  ? _ErrorBanner(
                                      key: ValueKey(authState.error),
                                      message: authState.error!,
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 24),

                            // Sign in button
                            _SignInButton(
                              isLoading: authState.isLoading,
                              onPressed:
                                  authState.isLoading ? null : _handleLogin,
                              l10n: l10n,
                            ),

                            const SizedBox(height: 48),
                            _Footer(isDark: isDark),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background ─────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF060D1A), Color(0xFF091424), Color(0xFF0B1A30)],
                    stops: [0.0, 0.45, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF0F5FA)],
                  ),
          ),
        ),

        // Orb 1 — top right (electric blue)
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: isDark ? 0.10 : 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Orb 2 — bottom left (purple)
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.purple.withValues(alpha: isDark ? 0.08 : 0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Orb 3 — center subtle glow (dark only)
        if (isDark)
          Positioned(
            top: 160,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    IconData themeIcon;
    switch (themeMode) {
      case ThemeMode.light:
        themeIcon = Icons.light_mode_rounded;
      case ThemeMode.dark:
        themeIcon = Icons.dark_mode_rounded;
      default:
        themeIcon = Icons.settings_suggest_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
      child: Row(
        children: [
          // Language chip
          _TopBarChip(
            isDark: isDark,
            child: Text(
              _flagForLocale(locale),
              style: const TextStyle(fontSize: 16),
            ),
            onTap: () => _showLanguagePicker(context, ref, locale),
          ),
          const Spacer(),
          // Theme toggle
          _TopBarChip(
            isDark: isDark,
            child: Icon(themeIcon,
                size: 17,
                color: isDark ? AppColors.accent : AppColors.accentDark),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),
        ],
      ),
    );
  }

  String _flagForLocale(Locale locale) {
    return appSupportedLocales
            .firstWhere(
              (i) => i.locale.languageCode == locale.languageCode,
              orElse: () => appSupportedLocales.first,
            )
            .flag;
  }

  void _showLanguagePicker(
      BuildContext context, WidgetRef ref, Locale current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LanguageSheet(current: current, ref: ref),
    );
  }

  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ThemeSheet(current: current, ref: ref),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({
    required this.isDark,
    required this.child,
    required this.onTap,
  });

  final bool isDark;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.border.withValues(alpha: 0.5)
                : AppColors.lightBorder,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Logo Section ───────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Image.asset(
            isDark ? 'assets/images/elmo-02.png' : 'assets/images/elmogps.png',
            width: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Welcome Header ─────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isDark, required this.l10n});
  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeBack,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.signInSubtitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Form Section ───────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isLoading,
    required this.onSubmit,
    required this.l10n,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: formKey,
      child: Column(
        children: [
          ElmoTextField(
            controller: emailCtrl,
            label: l10n.emailLabel,
            hint: 'name@company.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.isEmpty) {
                return isDark ? 'Email is required' : 'Email is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElmoTextField(
            controller: passwordCtrl,
            label: l10n.passwordLabel,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => onSubmit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Forgot password (right-aligned, cosmetic)
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isNetwork = message.toLowerCase().contains('internet') ||
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('timeout') ||
        message.toLowerCase().contains('server');

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            color: AppColors.error,
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign In Button ─────────────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.isLoading,
    required this.onPressed,
    required this.l10n,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF0096FF), Color(0xFF0070CC)],
                )
              : null,
          color: onPressed == null
              ? AppColors.textMuted.withValues(alpha: 0.25)
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius + 2),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.signInButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                isDark
                    ? AppColors.divider.withValues(alpha: 0.6)
                    : AppColors.lightDivider,
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isDark ? 'assets/images/elmo-02.png' : 'assets/images/elmogps.png',
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 14,
              color: isDark
                  ? AppColors.border.withValues(alpha: 0.5)
                  : AppColors.lightBorder,
            ),
            const SizedBox(width: 10),
            Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Language Sheet ─────────────────────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.current, required this.ref});
  final Locale current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.selectLanguage,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...appSupportedLocales.map((info) {
            final isSelected =
                info.locale.languageCode == current.languageCode;
            return ListTile(
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(info.locale);
                Navigator.of(context).pop();
              },
              leading: Text(info.flag,
                  style: const TextStyle(fontSize: 24)),
              title: Text(
                info.nativeName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.accent : cs.onSurface,
                ),
              ),
              subtitle: Text(
                info.englishName,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              trailing: isSelected
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 13),
                    )
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
            );
          }),
        ],
      ),
    );
  }
}

// ── Theme Sheet ────────────────────────────────────────────────────────────────

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.current, required this.ref});
  final ThemeMode current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final options = [
      (
        ThemeMode.light,
        Icons.light_mode_rounded,
        'Light',
        'Bright & clear',
        const Color(0xFFF59E0B)
      ),
      (
        ThemeMode.dark,
        Icons.dark_mode_rounded,
        'Dark',
        'Easy on the eyes',
        AppColors.accentLight
      ),
      (
        ThemeMode.system,
        Icons.settings_suggest_rounded,
        'System',
        'Follows device',
        AppColors.purple
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.appearance,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...options.map((opt) {
            final (mode, icon, label, sub, color) = opt;
            final selected = current == mode;
            return ListTile(
              onTap: () {
                ref.read(themeProvider.notifier).setTheme(mode);
                Navigator.of(context).pop();
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.15)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 20, color: selected ? color : cs.onSurface.withValues(alpha: 0.45)),
              ),
              title: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? cs.onSurface : cs.onSurface,
                ),
              ),
              subtitle: Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 22)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
            );
          }),
        ],
      ),
    );
  }
}
