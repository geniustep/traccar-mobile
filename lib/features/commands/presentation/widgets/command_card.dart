import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/device_command.dart';
import '../../domain/entities/resolved_device_command.dart';

/// Displays a single [ResolvedDeviceCommand] as a tappable card.
///
/// Adapts its visual state based on [resolved.status]:
/// - Available: active button + risk chip
/// - Disabled: greyed-out with clear disable reason
/// - Queued: orange tinted with queue message
class CommandCard extends StatelessWidget {
  const CommandCard({
    super.key,
    required this.resolved,
    required this.isLoading,
    required this.onTap,
  });

  final ResolvedDeviceCommand resolved;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cmd = resolved.command;
    final status = resolved.status;
    final isExecutable = status.isExecutable;
    final isQueued = status.isQueueable;
    final isDisabled = status.isDisabled;

    final borderColor = _borderColor(cmd, status, isLoading);
    final bgColor = _bgColor(cmd, status, isLoading);

    return Opacity(
      opacity: isDisabled ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: (isExecutable || isQueued) && !isLoading ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border:
                Border.all(color: borderColor, width: isLoading ? 1.0 : 0.5),
          ),
          child: Row(
            children: [
              // ── Icon badge ──────────────────────────────────────────────
              _IconBadge(
                icon: cmd.icon,
                color: _iconColor(cmd, status),
                isLoading: isLoading,
              ),
              const SizedBox(width: AppSpacing.md),

              // ── Text content ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cmd.label(l10n.locale),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isDisabled
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        // Method badge (custom / saved)
                        if (isExecutable && !isLoading)
                          _MethodBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle(resolved, l10n.locale),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _subtitleColor(status),
                        fontStyle:
                            isDisabled ? FontStyle.italic : FontStyle.normal,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ── Right indicator ─────────────────────────────────────────
              _RightIndicator(
                resolved: resolved,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Color helpers ─────────────────────────────────────────────────────────

  Color _borderColor(
      DeviceCommand cmd, CommandCapabilityStatus status, bool loading) {
    if (loading) return cmd.riskLevel.color.withValues(alpha: 0.6);
    if (status.isDisabled) return AppColors.border;
    if (status == CommandCapabilityStatus.offlineQueued) {
      return AppColors.warning.withValues(alpha: 0.3);
    }
    return switch (cmd.riskLevel) {
      CommandRiskLevel.high => AppColors.error.withValues(alpha: 0.3),
      CommandRiskLevel.medium => AppColors.warning.withValues(alpha: 0.2),
      CommandRiskLevel.low => AppColors.border,
    };
  }

  Color _bgColor(
      DeviceCommand cmd, CommandCapabilityStatus status, bool loading) {
    if (loading) return cmd.riskLevel.color.withValues(alpha: 0.06);
    if (status == CommandCapabilityStatus.offlineQueued) {
      return AppColors.warning.withValues(alpha: 0.05);
    }
    return AppColors.cardBackground;
  }

  Color _iconColor(DeviceCommand cmd, CommandCapabilityStatus status) {
    if (status.isDisabled) return AppColors.textMuted;
    if (status == CommandCapabilityStatus.offlineQueued) {
      return  AppColors.warning;
    }
    return cmd.riskLevel.color;
  }

  Color _subtitleColor(CommandCapabilityStatus status) {
    if (status == CommandCapabilityStatus.offlineQueued) {
      return AppColors.warning;
    }
    if (status.isDisabled) return AppColors.textMuted;
    return AppColors.textSecondary;
  }

  String _subtitle(ResolvedDeviceCommand r, Locale locale) {
    if (r.disableReason != null) return r.disableReason!;
    if (r.queueMessage != null) return r.queueMessage!;
    return r.command.description(locale);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.isLoading,
  });

  final IconData icon;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 22, color: color),
    );
  }
}

class _RightIndicator extends StatelessWidget {
  const _RightIndicator({required this.resolved, required this.isLoading});

  final ResolvedDeviceCommand resolved;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();

    final status = resolved.status;
    final riskLevel = resolved.command.riskLevel;

    return switch (status) {
      CommandCapabilityStatus.available => riskLevel == CommandRiskLevel.high
          ? const _RiskChip(label: 'HIGH', color: AppColors.error)
          : riskLevel == CommandRiskLevel.medium
              ? const _RiskChip(label: 'MED', color: AppColors.warning)
              : const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textMuted),
      CommandCapabilityStatus.availableViaCustom =>
        const _RiskChip(label: 'CUSTOM', color: AppColors.accent),
      CommandCapabilityStatus.availableViaSaved =>
        const _RiskChip(label: 'SAVED', color: Color(0xFF9C27B0)),
      CommandCapabilityStatus.offlineQueued =>
        const _RiskChip(label: 'QUEUE', color: AppColors.warning),
      CommandCapabilityStatus.notInstalled =>
        const Icon(Icons.build_outlined, size: 16, color: AppColors.textMuted),
      CommandCapabilityStatus.permissionDenied => const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: AppColors.textMuted),
      CommandCapabilityStatus.offlineBlocked =>
        const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.error),
      CommandCapabilityStatus.blockedBySpeed =>
        const Icon(Icons.speed_rounded, size: 16, color: AppColors.warning),
      _ =>
        const Icon(Icons.block_rounded, size: 16, color: AppColors.textMuted),
    };
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.status});
  final CommandCapabilityStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == CommandCapabilityStatus.availableViaCustom) {
      return const _Chip(label: 'CUSTOM', color: AppColors.accent);
    }
    if (status == CommandCapabilityStatus.availableViaSaved) {
      return const _Chip(label: 'SAVED', color: Color(0xFF9C27B0));
    }
    return const SizedBox.shrink();
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => _Chip(label: label, color: color);
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
