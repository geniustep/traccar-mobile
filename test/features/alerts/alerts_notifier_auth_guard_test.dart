import 'package:elmogps/features/alerts/domain/entities/alert.dart';
import 'package:elmogps/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:elmogps/features/alerts/presentation/providers/alerts_provider.dart';
import 'package:elmogps/features/auth/domain/entities/user_entity.dart';
import 'package:elmogps/features/auth/domain/repositories/auth_repository.dart';
import 'package:elmogps/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoOpAlertsRepository implements AlertsRepository {
  var getAlertsCalls = 0;
  var getUnreadCountCalls = 0;

  @override
  Future<List<AlertEntity>> getAlerts({
    String status = 'all',
    int limit = 50,
    int offset = 0,
    int? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    getAlertsCalls++;
    return [];
  }

  @override
  Future<int> getUnreadCount() async {
    getUnreadCountCalls++;
    return 0;
  }

  @override
  Future<AlertEntity> getAlertById(int id) =>
      throw UnimplementedError();

  @override
  Future<void> markAlertRead(int id) async {}

  @override
  Future<void> markAllAlertsRead({DateTime? before}) async {}

  @override
  Future<List<AlertEntity>> getSmartAlerts() => getAlerts();

  @override
  Future<List<AlertEntity>> getVehicleAlerts(String vehicleId) async => [];

  @override
  Future<void> markAsRead(String alertId) async {}
}

class _LoggedOutAuthRepository implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<UserEntity?> getCachedUser() async => null;

  @override
  Future<(UserEntity, String, String)> login({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> getMe() => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<void> ensureTraccarSocketSession() async {}
}

Future<void> _waitForAuthReady(ProviderContainer container) async {
  for (var i = 0; i < 50; i++) {
    if (!container.read(authProvider).isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Auth init did not complete');
}

void main() {
  test('AlertsNotifier.load does not call repository when unauthenticated', () async {
    final repo = _NoOpAlertsRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_LoggedOutAuthRepository()),
        alertsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await _waitForAuthReady(container);
    expect(container.read(authProvider).isAuthenticated, isFalse);

    await container.read(alertsProvider.notifier).load();

    expect(repo.getAlertsCalls, 0);
    expect(repo.getUnreadCountCalls, 0);
  });

  test('resetOnLogout clears state without repository calls', () async {
    final repo = _NoOpAlertsRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_LoggedOutAuthRepository()),
        alertsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await _waitForAuthReady(container);

    final notifier = container.read(alertsProvider.notifier);
    notifier.resetOnLogout();

    expect(repo.getAlertsCalls, 0);
    expect(container.read(alertsProvider).unreadCount, 0);
    expect(
      container.read(alertsProvider).alertsAsync.valueOrNull,
      isEmpty,
    );
  });
}
