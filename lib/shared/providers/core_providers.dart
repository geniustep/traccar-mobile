import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(ref.read(flutterSecureStorageProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    ref.read(appConfigProvider),
    ref.read(secureStorageServiceProvider),
  );
});
