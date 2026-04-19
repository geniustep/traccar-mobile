import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/elmo_button.dart';
import '../../../../core/widgets/elmo_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final error = authState.error;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 48),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(authState.isLoading),
                  const SizedBox(height: 12),
                  if (error != null) _buildError(error),
                  const SizedBox(height: 24),
                  ElmoButton(
                    label: 'Sign In',
                    onPressed: authState.isLoading ? null : _handleLogin,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: 40),
                  _buildFooter(),
                ],
              ),
            ),
          ),

          // زر الإعدادات في الزاوية العلوية اليمنى
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: AppSpacing.screenPadding,
            child: _ThemeToggleButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.route_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ELMO',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.accent,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Fleet Intelligence',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Sign in to your fleet dashboard',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool loading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          ElmoTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            hint: 'name@company.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !loading,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElmoTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            enabled: !loading,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _handleLogin(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'ELMO Fleet Intelligence Platform\nv1.0.0',
        style: AppTextStyles.labelSmall.copyWith(height: 1.6),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Theme toggle button ──────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final cs = Theme.of(context).colorScheme;

    IconData icon;
    String tooltip;
    switch (themeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode_rounded;
        tooltip = 'Light';
      case ThemeMode.dark:
        icon = Icons.dark_mode_rounded;
        tooltip = 'Dark';
      default:
        icon = Icons.settings_suggest_rounded;
        tooltip = 'System';
    }

    return GestureDetector(
      onTap: () => _showThemePicker(context, ref, themeMode),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outline.withOpacity(0.4),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 19, color: AppColors.accent),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ThemePickerSheet(current: current, ref: ref),
    );
  }
}

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet({required this.current, required this.ref});

  final ThemeMode current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final options = [
      (ThemeMode.light, Icons.light_mode_rounded, 'Light', 'Bright & clear'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark', 'Easy on the eyes'),
      (ThemeMode.system, Icons.settings_suggest_rounded, 'System', 'Follows device'),
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
                color: cs.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Appearance',
            style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          ...options.map((opt) {
            final (mode, icon, label, sub) = opt;
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
                      ? AppColors.accent.withOpacity(0.12)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.accent : cs.onSurface.withOpacity(0.5),
                ),
              ),
              title: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: cs.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              subtitle: Text(
                sub,
                style: AppTextStyles.bodySmall.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
              trailing: selected
                  ? Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 20)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
            );
          }),
        ],
      ),
    );
  }
}
