import 'package:elmogps/features/auth/domain/entities/user_entity.dart';
import 'package:elmogps/features/map/core/route_intelligence_threshold_resolution.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/presentation/utils/route_intel_vehicle_central_edit_permission.dart';
import 'package:elmogps/features/map/domain/repositories/route_intelligence_thresholds_write_repository.dart';
import 'package:elmogps/features/map/presentation/providers/route_intelligence_thresholds_write_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWriteRepo implements RouteIntelligenceThresholdsWriteRepository {
  int saveCount = 0;
  int clearCount = 0;
  List<String> savedIds = [];
  Object? throwOnSave;
  Object? throwOnClear;

  @override
  Future<void> clearGroupThresholds({required int groupId}) =>
      throw UnimplementedError();

  @override
  Future<void> clearUserThresholds({required String userId}) =>
      throw UnimplementedError();

  @override
  Future<void> clearVehicleThresholds({required String vehicleId}) async {
    if (throwOnClear != null) throw throwOnClear!;
    clearCount++;
  }

  @override
  Future<void> saveGroupThresholds({
    required int groupId,
    required RouteIntelligenceThresholds thresholds,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> saveUserThresholds({
    required String userId,
    required RouteIntelligenceThresholds thresholds,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> saveVehicleThresholds({
    required String vehicleId,
    required RouteIntelligenceThresholds thresholds,
  }) async {
    if (throwOnSave != null) throw throwOnSave!;
    saveCount++;
    savedIds.add(vehicleId);
  }
}

void main() {
  group('routeIntelCanEditVehicleCentralThresholds', () {
    test('denies null, readonly, viewer', () {
      expect(routeIntelCanEditVehicleCentralThresholds(null), isFalse);
      expect(
        routeIntelCanEditVehicleCentralThresholds(
          const UserEntity(
            id: '1',
            name: 'a',
            email: 'a@a.com',
            readonly: true,
          ),
        ),
        isFalse,
      );
      expect(
        routeIntelCanEditVehicleCentralThresholds(
          const UserEntity(
            id: '1',
            name: 'a',
            email: 'a@a.com',
            readonly: false,
          ),
        ),
        isTrue,
      );
    });
  });

  group('routeIntelResolutionHasDeviceOverride', () {
    test('true when any source is device', () {
      const r = RouteIntelligenceThresholdResolution(
        thresholds: RouteIntelligenceThresholds.defaults,
        sources: RouteIntelligenceThresholdSources(
          stopSpeedEnterKmhSource: RouteIntelligenceThresholdSource.device,
          stopSpeedExitKmhSource: RouteIntelligenceThresholdSource.defaults,
          minStopDurationSource: RouteIntelligenceThresholdSource.defaults,
          overspeedThresholdKmhSource: RouteIntelligenceThresholdSource.defaults,
          detectStopsSource: RouteIntelligenceThresholdSource.defaults,
          detectOverspeedSource: RouteIntelligenceThresholdSource.defaults,
          detectIgnitionSource: RouteIntelligenceThresholdSource.defaults,
        ),
      );
      expect(routeIntelResolutionHasDeviceOverride(r), isTrue);
    });

    test('false when no device source', () {
      const r = RouteIntelligenceThresholdResolution(
        thresholds: RouteIntelligenceThresholds.defaults,
        sources: RouteIntelligenceThresholdSources.allDefaults,
      );
      expect(routeIntelResolutionHasDeviceOverride(r), isFalse);
    });
  });

  group('central write actions (smoke)', () {
    test('repository save/clear are invoked via ProviderContainer reads', () async {
      final fake = _FakeWriteRepo();
      final container = ProviderContainer(overrides: [
        routeIntelligenceThresholdsWriteRepositoryProvider
            .overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      await container
          .read(routeIntelligenceThresholdsWriteRepositoryProvider)
          .saveVehicleThresholds(
            vehicleId: '42',
            thresholds: RouteIntelligenceThresholds.defaults,
          );

      expect(fake.saveCount, 1);

      await container
          .read(routeIntelligenceThresholdsWriteRepositoryProvider)
          .clearVehicleThresholds(vehicleId: '7');

      expect(fake.clearCount, 1);
    });
  });
}
