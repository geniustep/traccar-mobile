import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/services/command_execution_service.dart';

/// Shows a SnackBar summarising the result of a command dispatch.
void showCommandResultBanner(
  BuildContext context,
  CommandResult result,
) {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  switch (result) {
    case CommandSuccess(:final entry):
      messenger.showSnackBar(
        _buildSnackBar(
          message: '✓  "${entry.labelFr}" ${l10n.cmdSentSuccess}',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
      );

    case CommandQueued(:final message):
      messenger.showSnackBar(
        _buildSnackBar(
          message: message,
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
          duration: const Duration(seconds: 5),
        ),
      );

    case CommandBlockedBySafety(:final reason):
      messenger.showSnackBar(
        _buildSnackBar(
          message: reason,
          color: AppColors.warning,
          icon: Icons.block_rounded,
          duration: const Duration(seconds: 5),
        ),
      );

    case CommandNeedsConfirmation():
      // Handled by the screen — no banner needed here.
      break;

    case CommandFailed(:final entry, :final friendlyMessage):
      messenger.showSnackBar(
        _buildSnackBar(
          message: '✗  "${entry.labelFr}" — $friendlyMessage',
          color: AppColors.error,
          icon: Icons.error_outline_rounded,
          duration: const Duration(seconds: 6),
        ),
      );
  }
}

SnackBar _buildSnackBar({
  required String message,
  required Color color,
  required IconData icon,
  Duration duration = const Duration(seconds: 3),
}) {
  return SnackBar(
    duration: duration,
    backgroundColor: Colors.transparent,
    elevation: 0,
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    ),
  );
}
