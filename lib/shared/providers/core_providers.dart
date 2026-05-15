import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/connection/app_connection_monitor.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/traccar_client.dart';
import '../../core/storage/secure_storage_service.dart';

// ── Storage ───────────────────────────────────────────────────────────────────

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.read(flutterSecureStorageProvider));
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

// ── Connectivity ──────────────────────────────────────────────────────────────

final connectivityProvider = Provider<Connectivity>(
  (ref) => Connectivity(),
);

// ── HTTP Clients ──────────────────────────────────────────────────────────────

/// Legacy [DioClient] — retained only for [AuthRemoteDataSource] raw-response
/// access (JSESSIONID parsing). All other features use [traccarClientProvider].
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.read(secureStorageServiceProvider));
});

/// Main [TraccarClient] — use this for all API calls.
/// Now wired to [AppConnectionMonitor] so every REST response automatically
/// updates [AppConnectionStatus].
final traccarClientProvider = Provider<TraccarClient>((ref) {
  final monitor = ref.read(appConnectionMonitorProvider.notifier);
  return TraccarClient(
    storage: ref.read(secureStorageServiceProvider),
    connectivity: ref.read(connectivityProvider),
    connectionMonitor: monitor,
  );
});
