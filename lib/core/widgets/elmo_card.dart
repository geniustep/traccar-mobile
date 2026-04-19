import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ElmoCard extends StatelessWidget {
  const ElmoCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.borderWidth = 0.5,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;

  Gradient _resolveGradient(BuildContext context) {
    if (gradient != null) return gradient!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.cardGradient : AppColors.lightCardGradient;
  }

  Color _resolveBorder(BuildContext context) {
    if (borderColor != null) return borderColor!;
    return Theme.of(context).colorScheme.outline.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: _resolveGradient(context),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: _resolveBorder(context),
            width: borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ElmoAccentCard extends StatelessWidget {
  const ElmoAccentCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? AppColors.cardBackground : AppColors.lightCardBackground;
    return ElmoCard(
      onTap: onTap,
      padding: padding,
      borderColor: AppColors.accent.withOpacity(0.3),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accent.withOpacity(0.08),
          baseBg,
        ],
      ),
      child: child,
    );
  }
}
