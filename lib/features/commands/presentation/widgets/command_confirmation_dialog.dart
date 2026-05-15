import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/device_command.dart';
import '../../domain/entities/resolved_device_command.dart';

/// Shows a risk-appropriate confirmation dialog before executing a command.
///
/// - [CommandRiskLevel.medium]: simple confirm/cancel dialog.
/// - [CommandRiskLevel.high]: full warning dialog with text input confirmation.
///
/// Returns `true` if the user confirmed, `false` otherwise.
Future<bool> showCommandConfirmationDialog(
  BuildContext context, {
  required ResolvedDeviceCommand resolved,
  required String deviceName,
}) async {
  final l10n = AppLocalizations.of(context);
  final riskLevel = resolved.command.riskLevel;

  if (riskLevel == CommandRiskLevel.high) {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _HighRiskDialog(
            resolved: resolved,
            deviceName: deviceName,
            requiredWord: l10n.cmdConfirmWord,
            l10n: l10n,
          ),
        ) ??
        false;
  }

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _MediumRiskDialog(
          resolved: resolved,
          deviceName: deviceName,
          l10n: l10n,
        ),
      ) ??
      false;
}

// ── Medium Risk ───────────────────────────────────────────────────────────────

class _MediumRiskDialog extends StatelessWidget {
  const _MediumRiskDialog({
    required this.resolved,
    required this.deviceName,
    required this.l10n,
  });

  final ResolvedDeviceCommand resolved;
  final String deviceName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.warning;
    final cmd = resolved.command;

    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DialogIcon(icon: Icons.info_outline_rounded, color: color),
            const SizedBox(height: 16),
            Text(
              l10n.cmdConfirmRequired,
              style: AppTextStyles.headlineSmall.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.cmdConfirmSendMessage}\n'
              '"${cmd.label(l10n.locale)}"\n'
              '${l10n.vehicle} $deviceName.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (cmd.warningMessage != null) ...[
              const SizedBox(height: 12),
              _WarningBox(message: cmd.warningMessage!, color: color),
            ],
            const SizedBox(height: 24),
            _DialogButtons(
              cancelLabel: l10n.cancel,
              confirmLabel: l10n.confirm,
              confirmColor: color,
              onCancel: () => Navigator.of(context).pop(false),
              onConfirm: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

// ── High Risk ────────────────────────────────────────────────────────────────

class _HighRiskDialog extends StatefulWidget {
  const _HighRiskDialog({
    required this.resolved,
    required this.deviceName,
    required this.requiredWord,
    required this.l10n,
  });

  final ResolvedDeviceCommand resolved;
  final String deviceName;
  final String requiredWord;
  final AppLocalizations l10n;

  @override
  State<_HighRiskDialog> createState() => _HighRiskDialogState();
}

class _HighRiskDialogState extends State<_HighRiskDialog> {
  final _ctrl = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final ok = _ctrl.text.trim().toUpperCase() ==
          widget.requiredWord.toUpperCase();
      if (ok != _canConfirm) setState(() => _canConfirm = ok);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final requiredWord = widget.requiredWord;
    const color = AppColors.error;
    final cmd = widget.resolved.command;

    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DialogIcon(
                icon: Icons.warning_amber_rounded, color: color, size: 36),
            const SizedBox(height: 16),
            Text(
              l10n.cmdCriticalAction,
              style: AppTextStyles.headlineSmall.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.cmdConfirmSendMessage}\n'
              '"${cmd.label(l10n.locale)}"\n'
              '${l10n.vehicle} ${widget.deviceName}.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Risk warning box
            _WarningBox(
              message:
                  cmd.warningMessage ?? l10n.cmdCriticalWarningDefault,
              color: color,
            ),

            const SizedBox(height: 16),

            // Confirmation text input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.cmdTypeToConfirm} $requiredWord',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ctrl,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _canConfirm ? color : AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: requiredWord,
                      hintStyle: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: color.withValues(alpha: 0.3), width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: color, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: AppColors.border, width: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _DialogButtons(
              cancelLabel: l10n.cancel,
              confirmLabel: l10n.cmdExecuteCommand,
              confirmColor: color,
              onCancel: () => Navigator.of(context).pop(false),
              onConfirm:
                  _canConfirm ? () => Navigator.of(context).pop(true) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({
    required this.icon,
    required this.color,
    this.size = 32,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.message, required this.color});
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButtons extends StatelessWidget {
  const _DialogButtons({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onCancel,
    required this.onConfirm,
  });
  final String cancelLabel;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border, width: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(cancelLabel,
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  onConfirm != null ? confirmColor : AppColors.border,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel,
                style: AppTextStyles.labelLarge
                    .copyWith(color: Colors.white, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
