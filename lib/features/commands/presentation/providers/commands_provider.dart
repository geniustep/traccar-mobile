import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/models/user_role.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/traccar_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/commands_remote_datasource.dart';
import '../../data/repositories/commands_repository_impl.dart';
import '../../domain/catalog/command_catalog.dart';
import '../../domain/entities/command_log_entry.dart';
import '../../domain/entities/device_command.dart';
import '../../domain/entities/device_installation_profile.dart';
import '../../domain/entities/resolved_device_command.dart';
import '../../domain/repositories/commands_repository.dart';
import '../../domain/services/command_capability_service.dart';
import '../../domain/services/command_execution_service.dart';
import '../../domain/services/device_installation_service.dart';

// ── Infrastructure ─────────────────────────────────────────────────────────────

final commandsRemoteDatasourceProvider =
    Provider<CommandsRemoteDatasource>((ref) {
  return CommandsRemoteDatasource(ref.read(traccarClientProvider));
});

final commandsRepositoryProvider =
    FutureProvider<CommandsRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return CommandsRepositoryImpl(
    remote: ref.read(commandsRemoteDatasourceProvider),
    prefs: prefs,
  );
});

final commandExecutionServiceProvider =
    FutureProvider<CommandExecutionService>((ref) async {
  final repo = await ref.watch(commandsRepositoryProvider.future);
  return CommandExecutionService(repository: repo);
});

final deviceInstallationServiceProvider =
    FutureProvider<DeviceInstallationService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return DeviceInstallationService(prefs);
});

const _capabilityService = CommandCapabilityService();

// ── User role ─────────────────────────────────────────────────────────────────

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return UserRole.viewer;
  return user.appRole;
});

// ── Installation profile ──────────────────────────────────────────────────────

/// Installation profile for a specific device.
final installationProfileProvider =
    FutureProvider.family<DeviceInstallationProfile, int>(
  (ref, deviceId) async {
    final svc = await ref.watch(deviceInstallationServiceProvider.future);
    return svc.getProfile(deviceId);
  },
);

// ── Supported command types from Traccar ─────────────────────────────────────

final supportedCommandTypesProvider =
    FutureProvider.family<List<String>, ({int deviceId, String? model})>(
  (ref, args) async {
    final repoAsync = await ref.watch(commandsRepositoryProvider.future);
    final result = await repoAsync.getSupportedCommandTypes(args.deviceId);
    return result.when(
      success: (types) => types.isNotEmpty ? types : _allTraccarTypes,
      failure: (_) => _allTraccarTypes,
    );
  },
);

final _allTraccarTypes = CommandCatalog.all
    .map((c) => c.traccarType)
    .whereType<String>()
    .toSet()
    .toList();

// ── Resolved commands (grouped by category) ───────────────────────────────────

typedef _ResolveArgs = ({
  int deviceId,
  String? model,
  bool isOnline,
  double speedKmh,
});

final resolvedCommandsProvider = FutureProvider.family<
    Map<CommandCategory, List<ResolvedDeviceCommand>>, _ResolveArgs>(
  (ref, args) async {
    final userRole = ref.watch(currentUserRoleProvider);
    final traccarTypes =
        await ref.watch(supportedCommandTypesProvider((
          deviceId: args.deviceId,
          model: args.model,
        )).future);
    final installation =
        await ref.watch(installationProfileProvider(args.deviceId).future);

    return _capabilityService.resolveByCategory(
      userRole: userRole,
      deviceOnline: args.isOnline,
      currentSpeedKmh: args.speedKmh,
      traccarSupportedTypes: traccarTypes,
      installation: installation,
      deviceModel: args.model,
    );
  },
);

// ── Command logs ───────────────────────────────────────────────────────────────

class CommandLogsNotifier
    extends FamilyAsyncNotifier<List<CommandLogEntry>, int> {
  late int _deviceId;

  @override
  Future<List<CommandLogEntry>> build(int arg) async {
    _deviceId = arg;
    return _loadLogs();
  }

  Future<List<CommandLogEntry>> _loadLogs() async {
    final svc = await ref.read(commandExecutionServiceProvider.future);
    return svc.getLogs(_deviceId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadLogs);
  }

  Future<void> clearAll() async {
    final svc = await ref.read(commandExecutionServiceProvider.future);
    await svc.clearLogs(_deviceId);
    state = const AsyncData([]);
  }
}

final commandLogsProvider =
    AsyncNotifierProvider.family<CommandLogsNotifier, List<CommandLogEntry>,
        int>(CommandLogsNotifier.new);

// ── Dispatch state ─────────────────────────────────────────────────────────────

/// Tracks the command key currently being dispatched for a device. Null = idle.
final dispatchingCommandProvider =
    StateProvider.family<String?, int>((ref, deviceId) => null);

// ── Dispatch helper ───────────────────────────────────────────────────────────

Future<CommandResult> dispatchResolvedCommand({
  required WidgetRef ref,
  required ResolvedDeviceCommand resolved,
  required int deviceId,
  required String deviceName,
  double currentSpeedKmh = 0.0,
  bool userConfirmed = false,
  Map<String, dynamic>? providedParams,
}) async {
  AppLogger.commands('Command dispatch started: key=${resolved.commandKey} deviceId=$deviceId');
  ref.read(dispatchingCommandProvider(deviceId).notifier).state =
      resolved.commandKey;

  try {
    final svc = await ref.read(commandExecutionServiceProvider.future);
    final user = ref.read(currentUserProvider);
    final userRole = ref.read(currentUserRoleProvider);
    final liveDevices = ref.read(liveDevicesProvider);
    final isOnline = liveDevices[deviceId]?.isOnline ?? false;
    final installation =
        await ref.read(installationProfileProvider(deviceId).future);

    final result = await svc.dispatch(
      resolved: resolved,
      deviceId: deviceId,
      deviceName: deviceName,
      userRole: userRole,
      userId: user?.id ?? 'unknown',
      userName: user?.name ?? 'Unknown',
      deviceOnline: isOnline,
      currentSpeedKmh: currentSpeedKmh,
      userConfirmed: userConfirmed,
      providedParams: providedParams,
      installation: installation,
    );

    AppLogger.commands('Command dispatch result: key=${resolved.commandKey} type=${result.runtimeType} deviceId=$deviceId');

    // Refresh logs so new entry appears in CommandLogsScreen.
    ref.read(commandLogsProvider(deviceId).notifier).refresh();

    return result;
  } catch (e) {
    AppLogger.commandsError('Command dispatch error: key=${resolved.commandKey} deviceId=$deviceId error=$e');
    rethrow;
  } finally {
    ref.read(dispatchingCommandProvider(deviceId).notifier).state = null;
  }
}
