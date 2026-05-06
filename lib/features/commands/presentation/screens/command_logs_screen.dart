import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/command_log_entry.dart';
import '../../domain/entities/device_command.dart';
import '../providers/commands_provider.dart';

/// Displays the persistent history of sent commands for a single device.
class CommandLogsScreen extends ConsumerWidget {
  const CommandLogsScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  final int deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(commandLogsProvider(deviceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historique', style: AppTextStyles.headlineMedium),
            Text(
              deviceName,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          logsAsync.maybeWhen(
            data: (logs) => logs.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 22),
                    tooltip: 'Effacer l\'historique',
                    onPressed: () =>
                        _confirmClear(context, ref),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (logs) => logs.isEmpty
            ? _buildEmpty()
            : _buildList(logs),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Text(
            'Erreur de chargement: $e',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.history_rounded,
                color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Aucune commande envoyée',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'L\'historique apparaîtra ici après\nl\'envoi de la première commande.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<CommandLogEntry> logs) {
    return Consumer(
      builder: (context, ref, _) {
        final userRole = ref.watch(currentUserRoleProvider);
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: logs.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) =>
              _LogTile(entry: logs[i], userRole: userRole),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Effacer l\'historique',
            style: AppTextStyles.headlineSmall),
        content: Text(
          'Tous les journaux de commandes seront supprimés définitivement.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Effacer',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(commandLogsProvider(deviceId).notifier).clearAll();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry, required this.userRole});

  final CommandLogEntry entry;
  final UserRole userRole;

  bool get _isTechOrAdmin => userRole.isAtLeastTechnician;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(entry.status);
    final riskColor = _riskColor(entry.riskLevel);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withAlpha(100),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.labelFr,
                          style: AppTextStyles.labelLarge
                              .copyWith(fontSize: 13),
                        ),
                      ),
                      // Risk chip
                      if (entry.riskLevel != CommandRiskLevel.low)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.riskLevel == CommandRiskLevel.high
                                ? 'HIGH'
                                : 'MED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: riskColor,
                            ),
                          ),
                        ),
                      // Rejected badge
                      if (entry.status == CommandStatus.rejected)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REJETÉ',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_statusIcon(entry.status),
                          size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(entry.status),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      if (entry.errorMessage != null) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '· ${entry.errorMessage}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Metadata row: date, user, speed, online
                  Wrap(
                    spacing: 8,
                    children: [
                      Text(
                        DateFormatter.toDateTime(entry.sentAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      if (entry.sentByUserName != null)
                        _metaChip(
                            Icons.person_outline_rounded,
                            entry.sentByUserName!),
                      if (entry.vehicleSpeedAtExecution != null)
                        _metaChip(
                            Icons.speed_rounded,
                            '${entry.vehicleSpeedAtExecution!.toStringAsFixed(0)} km/h'),
                      if (entry.deviceOnlineAtExecution != null)
                        _metaChip(
                            entry.deviceOnlineAtExecution!
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            entry.deviceOnlineAtExecution!
                                ? 'En ligne'
                                : 'Hors ligne'),
                    ],
                  ),
                ],
              ),
            ),

            // Category icon + detail arrow
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry.category.icon,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 14, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: AppColors.textMuted),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _LogDetailSheet(
        entry: entry,
        isTechOrAdmin: _isTechOrAdmin,
      ),
    );
  }

  Color _statusColor(CommandStatus s) => switch (s) {
        CommandStatus.success => AppColors.success,
        CommandStatus.failed => AppColors.error,
        CommandStatus.timeout => AppColors.warning,
        CommandStatus.pending => AppColors.accent,
        CommandStatus.queued => AppColors.warning,
        CommandStatus.rejected => AppColors.error,
      };

  IconData _statusIcon(CommandStatus s) => switch (s) {
        CommandStatus.success => Icons.check_circle_rounded,
        CommandStatus.failed => Icons.error_rounded,
        CommandStatus.timeout => Icons.hourglass_empty_rounded,
        CommandStatus.pending => Icons.pending_rounded,
        CommandStatus.queued => Icons.schedule_rounded,
        CommandStatus.rejected => Icons.block_rounded,
      };

  String _statusLabel(CommandStatus s) => switch (s) {
        CommandStatus.success => 'Succès',
        CommandStatus.failed => 'Échec',
        CommandStatus.timeout => 'Timeout',
        CommandStatus.pending => 'En attente',
        CommandStatus.queued => 'En file d\'attente',
        CommandStatus.rejected => 'Rejeté (sécurité)',
      };

  Color _riskColor(CommandRiskLevel r) => r.color;
}

// ── Detail bottom sheet ────────────────────────────────────────────────────────

class _LogDetailSheet extends StatelessWidget {
  const _LogDetailSheet({
    required this.entry,
    required this.isTechOrAdmin,
  });

  final CommandLogEntry entry;
  final bool isTechOrAdmin;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(entry.status);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ListView(
          controller: controller,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title row
            Row(
              children: [
                Icon(entry.category.icon,
                    color: entry.category.color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entry.labelFr,
                      style: AppTextStyles.headlineSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel(entry.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // General fields (visible to all)
            _section('Informations générales', [
              _row('Commande', entry.commandKey),
              _row('Type Traccar', entry.commandType),
              _row('Catégorie', entry.category.labelFr),
              _row('Risque', entry.riskLevel.labelFr),
              _row('Méthode', entry.sendMethod.name),
              _row('Date', DateFormatter.toDateTime(entry.sentAt)),
              if (entry.sentByUserName != null)
                _row('Envoyé par', entry.sentByUserName!),
              if (entry.sentByUserId != null)
                _row('ID utilisateur', entry.sentByUserId!),
            ]),
            const SizedBox(height: 16),

            // Execution context (visible to all)
            _section('Contexte d\'exécution', [
              if (entry.deviceOnlineAtExecution != null)
                _row(
                  'État connexion',
                  entry.deviceOnlineAtExecution!
                      ? '🟢 En ligne'
                      : '🔴 Hors ligne',
                ),
              if (entry.vehicleSpeedAtExecution != null)
                _row(
                  'Vitesse',
                  '${entry.vehicleSpeedAtExecution!.toStringAsFixed(1)} km/h',
                ),
              _row('Appareil', entry.deviceName),
            ]),

            // Error info (visible to all if failed/rejected)
            if (entry.errorMessage != null) ...[
              const SizedBox(height: 16),
              _section('Message d\'erreur', [
                _row('Message', entry.errorMessage!),
              ]),
            ],

            // Technical details — technician/admin only
            if (isTechOrAdmin) ...[
              const SizedBox(height: 16),
              _techSection(entry),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _techSection(CommandLogEntry e) {
    final hasRawResponse = e.rawResponse != null && e.rawResponse!.isNotEmpty;
    final hasFailureReason =
        e.failureReason != null && e.failureReason!.isNotEmpty;

    final rows = <Widget>[];

    if (hasFailureReason) {
      rows.add(_row('Raison technique', e.failureReason!));
    }
    if (e.attributes.isNotEmpty) {
      rows.add(_row('Attributs envoyés', e.attributes.toString()));
    }
    if (hasRawResponse) {
      rows.add(const Divider(height: 16, color: AppColors.border));
      rows.add(
        Row(
          children: [
            Expanded(
              child: Text(
                'Réponse brute (rawResponse)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14),
              color: AppColors.textMuted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Copier',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: e.rawResponse!)),
            ),
          ],
        ),
      );
      rows.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            e.rawResponse!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF8DD3C7),
            ),
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      rows.add(
        Text(
          'Aucune donnée technique disponible.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      );
    }

    return _section('Données techniques (Technicien/Admin)', rows);
  }

  Color _statusColor(CommandStatus s) => switch (s) {
        CommandStatus.success => AppColors.success,
        CommandStatus.failed => AppColors.error,
        CommandStatus.timeout => AppColors.warning,
        CommandStatus.pending => AppColors.accent,
        CommandStatus.queued => AppColors.warning,
        CommandStatus.rejected => AppColors.error,
      };

  String _statusLabel(CommandStatus s) => switch (s) {
        CommandStatus.success => 'Succès',
        CommandStatus.failed => 'Échec',
        CommandStatus.timeout => 'Timeout',
        CommandStatus.pending => 'En attente',
        CommandStatus.queued => 'En file d\'attente',
        CommandStatus.rejected => 'Rejeté (sécurité)',
      };
}
