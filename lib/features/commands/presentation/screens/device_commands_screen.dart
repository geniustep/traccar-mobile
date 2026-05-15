import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/traccar_device.dart';
import '../../../../shared/providers/traccar_providers.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../domain/entities/device_command.dart';
import '../../domain/entities/resolved_device_command.dart';
import '../../domain/services/command_execution_service.dart';
import '../providers/commands_provider.dart';
import '../widgets/command_card.dart';
import '../widgets/command_confirmation_dialog.dart';
import '../widgets/command_result_banner.dart';
import '../widgets/command_status_banner.dart';

class DeviceCommandsScreen extends ConsumerStatefulWidget {
  const DeviceCommandsScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  final int deviceId;
  final String deviceName;

  @override
  ConsumerState<DeviceCommandsScreen> createState() =>
      _DeviceCommandsScreenState();
}

class _DeviceCommandsScreenState extends ConsumerState<DeviceCommandsScreen> {
  final _expanded = <CommandCategory, bool>{};

  @override
  void initState() {
    super.initState();
    _expanded[CommandCategory.deviceInformation] = true;
    _expanded[CommandCategory.tracking] = true;
    AppLogger.commands('Commands screen opened: deviceId=${widget.deviceId} name=${widget.deviceName}');
  }

  @override
  Widget build(BuildContext context) {
    final liveDevices = ref.watch(liveDevicesProvider);
    final TraccarDevice? device = liveDevices[widget.deviceId];

    final livePositions = ref.watch(livePositionsProvider);
    final livePos = livePositions[widget.deviceId];

    // Fallback to REST API when WebSocket is unavailable (e.g. server 503)
    final vehicleFallback = ref
        .watch(vehicleDetailProvider(widget.deviceId.toString()))
        .valueOrNull;

    final isOnline = device?.isOnline ?? vehicleFallback?.isOnline ?? false;
    final currentSpeedKmh =
        livePos?.speedKmh ?? vehicleFallback?.speed ?? 0.0;

    final resolvedAsync = ref.watch(
      resolvedCommandsProvider((
        deviceId: widget.deviceId,
        model: device?.model,
        isOnline: isOnline,
        speedKmh: currentSpeedKmh,
      )),
    );

    final dispatchingKey =
        ref.watch(dispatchingCommandProvider(widget.deviceId));

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            CommandStatusBanner(
              deviceName: widget.deviceName,
              isOnline: isOnline,
              currentSpeedKmh: currentSpeedKmh,
              lastUpdate: device?.lastUpdate ?? vehicleFallback?.lastUpdate,
            ),
            Expanded(
              child: resolvedAsync.when(
                data: (byCategory) {
                  final total = byCategory.values.fold<int>(0, (sum, list) => sum + list.length);
                  AppLogger.commands('Commands loaded: count=$total deviceId=${widget.deviceId}');
                  return _buildSections(
                    context,
                    byCategory: byCategory,
                    dispatchingKey: dispatchingKey,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, __) {
                  AppLogger.commandsError('Commands load failed: deviceId=${widget.deviceId} error=$e');
                  return _buildError(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = context.l10n;
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.commandsTitle, style: AppTextStyles.headlineMedium),
          Text(
            widget.deviceName,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded,
              color: AppColors.accent, size: 22),
          tooltip: l10n.commandHistoryTooltip,
          onPressed: () => context.push(
            '/vehicles/${widget.deviceId}/commands/logs',
            extra: {'name': widget.deviceName},
          ),
        ),
      ],
    );
  }

  Widget _buildSections(
    BuildContext context, {
    required Map<CommandCategory, List<ResolvedDeviceCommand>> byCategory,
    required String? dispatchingKey,
  }) {
    if (byCategory.isEmpty) {
      return _buildEmpty(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          bottom: AppSpacing.screenPadding),
      itemCount: CommandCategory.values.length,
      itemBuilder: (context, i) {
        final category = CommandCategory.values[i];
        final commands = byCategory[category];
        if (commands == null || commands.isEmpty) {
          return const SizedBox.shrink();
        }

        return _CommandSection(
          category: category,
          commands: commands,
          dispatchingKey: dispatchingKey,
          isExpanded: _expanded[category] ?? false,
          onToggle: () => setState(
            () => _expanded[category] = !(_expanded[category] ?? false),
          ),
          onDispatch: _handleDispatch,
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedOf(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Icon(Icons.settings_remote_rounded,
                color: AppColors.textMutedOf(context), size: 32),
          ),
          const SizedBox(height: 16),
          Text(l10n.noCommandsAvailable,
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textSecondaryOf(context))),
          const SizedBox(height: 8),
          Text(
            l10n.noCommandsMessage,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMutedOf(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 32),
          ),
          const SizedBox(height: 16),
          Text(l10n.cmdLoadFailed,
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.textSecondaryOf(context))),
          const SizedBox(height: 8),
          Text(
            l10n.cmdErrorUnexpected,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMutedOf(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(supportedCommandTypesProvider);
              ref.invalidate(installationProfileProvider);
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.cmdRetry),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDispatch(ResolvedDeviceCommand resolved) async {
    if (!mounted) return;
    AppLogger.commands('Command selected: key=${resolved.commandKey} risk=${resolved.command.riskLevel.name} deviceId=${widget.deviceId}');

    if (resolved.command.requiresConfirmation) {
      AppLogger.commands('Confirmation dialog opened: key=${resolved.commandKey} risk=${resolved.command.riskLevel.name}');
      final confirmed = await showCommandConfirmationDialog(
        context,
        resolved: resolved,
        deviceName: widget.deviceName,
      );
      if (!confirmed || !mounted) return;
    }

    final result = await dispatchResolvedCommand(
      ref: ref,
      resolved: resolved,
      deviceId: widget.deviceId,
      deviceName: widget.deviceName,
      currentSpeedKmh:
          ref.read(livePositionsProvider)[widget.deviceId]?.speedKmh ?? 0.0,
      userConfirmed: resolved.command.requiresConfirmation,
    );

    if (!mounted) return;

    AppLogger.commands('Command result: key=${resolved.commandKey} result=${result.runtimeType} deviceId=${widget.deviceId}');

    if (result is CommandBlockedBySafety) {
      AppLogger.commands('Command blocked: key=${resolved.commandKey} reason=${result.reason}');
    }

    if (result is CommandNeedsConfirmation) {
      final confirmed = await showCommandConfirmationDialog(
        context,
        resolved: resolved,
        deviceName: widget.deviceName,
      );
      if (!confirmed || !mounted) return;
      final retry = await dispatchResolvedCommand(
        ref: ref,
        resolved: resolved,
        deviceId: widget.deviceId,
        deviceName: widget.deviceName,
        currentSpeedKmh:
            ref.read(livePositionsProvider)[widget.deviceId]?.speedKmh ?? 0.0,
        userConfirmed: true,
      );
      if (mounted) showCommandResultBanner(context, retry);
      return;
    }

    showCommandResultBanner(context, result);
  }
}

// ── Section widget ────────────────────────────────────────────────────────────

class _CommandSection extends StatelessWidget {
  const _CommandSection({
    required this.category,
    required this.commands,
    required this.dispatchingKey,
    required this.isExpanded,
    required this.onToggle,
    required this.onDispatch,
  });

  final CommandCategory category;
  final List<ResolvedDeviceCommand> commands;
  final String? dispatchingKey;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Future<void> Function(ResolvedDeviceCommand) onDispatch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabledCount = commands.where((r) => r.isExecutable).length;
    final totalCount = commands.length;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.08),
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : BorderRadius.circular(12),
                border: Border.all(
                    color: category.color.withValues(alpha: 0.2),
                    width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(category.icon,
                        size: 18, color: category.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label(l10n.locale),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: category.color,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          l10n.availableOf(enabledCount, totalCount),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMutedOf(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: category.color,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  left: BorderSide(
                      color: category.color.withValues(alpha: 0.2),
                      width: 0.5),
                  right: BorderSide(
                      color: category.color.withValues(alpha: 0.2),
                      width: 0.5),
                  bottom: BorderSide(
                      color: category.color.withValues(alpha: 0.2),
                      width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < commands.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                      child: CommandCard(
                        resolved: commands[i],
                        isLoading: dispatchingKey == commands[i].commandKey,
                        onTap: () => onDispatch(commands[i]),
                      ),
                    ),
                    if (i < commands.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.borderOf(context)
                            .withValues(alpha: 0.4),
                      ),
                  ],
                  const SizedBox(height: 6),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
