import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elmogps/core/constants/route_intelligence_attribute_keys.dart';
import 'package:elmogps/core/constants/route_intelligence_local_preference_keys.dart';
import 'package:elmogps/features/auth/domain/entities/user_entity.dart';
import 'package:elmogps/features/auth/presentation/providers/auth_provider.dart'
    show currentUserProvider;
import 'package:elmogps/features/map/core/route_intelligence_threshold_resolution.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/presentation/providers/route_intel_group_attributes_map_provider.dart';
import 'package:elmogps/features/map/presentation/providers/route_intelligence_thresholds_provider.dart';
import 'package:elmogps/features/map/presentation/providers/tracking_provider.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:elmogps/features/vehicles/presentation/providers/vehicles_provider.dart';
import 'package:elmogps/shared/providers/core_providers.dart';

void main() {
  group('routeIntelligenceThresholdsProvider', () {
    test('reads without throwing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final th = container.read(routeIntelligenceThresholdsProvider);
      expect(th, isA<RouteIntelligenceThresholds>());
    });

    test('defaults match RouteIntelligenceThresholds.defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final th = container.read(routeIntelligenceThresholdsProvider);
      expect(th, equals(RouteIntelligenceThresholds.defaults));
    });

    test('override with ProviderContainer.overrides', () {
      const custom = RouteIntelligenceThresholds(overspeedThresholdKmh: 77);
      expect(custom.overspeedThresholdKmh, 77);

      final container = ProviderContainer(
        overrides: [
          routeIntelligenceThresholdsProvider.overrideWith(
            (ref) => custom,
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(routeIntelligenceThresholdsProvider),
        same(custom),
      );
    });
  });

  group('routeIntelligenceGlobalThresholdsProvider', () {
    List<Override> harness({UserEntity? user}) => [
          currentUserProvider.overrideWith((ref) => user),
          sharedPreferencesProvider.overrideWith((ref) async {
            SharedPreferences.setMockInitialValues({});
            return SharedPreferences.getInstance();
          }),
        ];

    test('no user + no local → defaults.normalized()', () async {
      final container = ProviderContainer(overrides: harness());
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      final th = container.read(routeIntelligenceGlobalThresholdsProvider);
      expect(th, RouteIntelligenceThresholds.defaults.normalized());
    });

    test('local only', () async {
      SharedPreferences.setMockInitialValues({
        RouteIntelligenceLocalPreferenceKeys.overspeedThresholdKmh: 52,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      final th = container.read(routeIntelligenceGlobalThresholdsProvider);
      expect(th.overspeedThresholdKmh, 52);
    });

    test('user only', () async {
      const u = UserEntity(
        id: '1',
        name: 'U',
        email: 'u@u.com',
        attributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 88,
        },
      );
      final container = ProviderContainer(overrides: harness(user: u));
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      final th = container.read(routeIntelligenceGlobalThresholdsProvider);
      expect(th.overspeedThresholdKmh, 88);
    });

    test('user beats local', () async {
      SharedPreferences.setMockInitialValues({
        RouteIntelligenceLocalPreferenceKeys.overspeedThresholdKmh: 40,
      });
      final prefs = await SharedPreferences.getInstance();
      const u = UserEntity(
        id: '2',
        name: 'U2',
        email: 'u2@u.com',
        attributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 73,
        },
      );
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => u),
          sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      final th = container.read(routeIntelligenceGlobalThresholdsProvider);
      expect(th.overspeedThresholdKmh, 73);
    });

    test('invalid local values do not throw', () async {
      SharedPreferences.setMockInitialValues({
        RouteIntelligenceLocalPreferenceKeys.overspeedThresholdKmh: 'nope',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      expect(
        () => container.read(routeIntelligenceGlobalThresholdsProvider),
        returnsNormally,
      );
      final th = container.read(routeIntelligenceGlobalThresholdsProvider);
      expect(
        th.overspeedThresholdKmh,
        RouteIntelligenceThresholds.defaults.overspeedThresholdKmh,
      );
    });

    test('invalid user attributes do not throw', () async {
      const u = UserEntity(
        id: '3',
        name: 'Bad',
        email: 'bad@bad.com',
        attributes: {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: Object(),
          RouteIntelligenceAttributeKeys.detectStops: <String, Object>{},
        },
      );
      final container = ProviderContainer(overrides: harness(user: u));
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      expect(
        () => container.read(routeIntelligenceGlobalThresholdsProvider),
        returnsNormally,
      );
    });

    test('resolution thresholds match legacy global provider', () async {
      const u = UserEntity(
        id: '4',
        name: 'U',
        email: 'u@u.com',
        attributes: const {
          RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 61,
          RouteIntelligenceAttributeKeys.detectStops: false,
        },
      );
      SharedPreferences.setMockInitialValues({
        RouteIntelligenceLocalPreferenceKeys.minStopDurationMinutes: 2,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => u),
          sharedPreferencesProvider.overrideWith((ref) async => prefs),
        ],
      );
      addTearDown(container.dispose);
      await container.read(sharedPreferencesProvider.future);
      final th = container.read(routeIntelligenceGlobalThresholdsProvider);
      final res =
          container.read(routeIntelligenceGlobalThresholdsResolutionProvider);
      expect(res.thresholds, th);
      expect(
        res.sources.overspeedThresholdKmhSource,
        RouteIntelligenceThresholdSource.user,
      );
      expect(
        res.sources.detectStopsSource,
        RouteIntelligenceThresholdSource.user,
      );
      expect(
        res.sources.minStopDurationSource,
        RouteIntelligenceThresholdSource.local,
      );
      expect(
        res.sources.detectOverspeedSource,
        RouteIntelligenceThresholdSource.defaults,
      );
    });
  });

  group('routeIntelligenceThresholdsForVehicleProvider', () {
    /// Avoid resolving real [authProvider] → [authRepositoryProvider] during map tests,
    /// and ensure [sharedPreferencesProvider] resolves for local layer reads.
    List<Override> routeIntelHarness({UserEntity? user}) => [
          currentUserProvider.overrideWith((ref) => user),
          sharedPreferencesProvider.overrideWith((ref) async {
            SharedPreferences.setMockInitialValues({});
            return SharedPreferences.getInstance();
          }),
        ];

    test('empty vehicleId yields defaults without network', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(routeIntelligenceThresholdsForVehicleProvider('')),
        RouteIntelligenceThresholds.defaults,
      );
    });

    VehicleEntity vehicle({
      required String id,
      String? groupId,
      Map<String, dynamic> deviceAttributes = const {},
    }) {
      return VehicleEntity(
        id: id,
        name: 'T',
        plateNumber: 'P',
        type: 'car',
        status: 'offline',
        speed: 0,
        latitude: 0,
        longitude: 0,
        address: null,
        lastUpdate: null,
        ignition: false,
        batteryVoltage: null,
        fuelLevel: null,
        driverName: null,
        groupId: groupId,
        deviceAttributes: deviceAttributes,
      );
    }

    test(
      'group + device merge: device overspeed overrides group',
      () async {
        final v = vehicle(
          id: '1',
          groupId: '10',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 75,
          },
        );
        final container = ProviderContainer(
          overrides: [
            ...routeIntelHarness(),
            liveVehicleProvider.overrideWith((ref, id) {
              if (id != '1') return const AsyncValue.loading();
              return AsyncValue.data(v);
            }),
            vehiclesListProvider.overrideWith((ref) async => [v]),
            routeIntelGroupAttributesMapProvider.overrideWith((ref) async {
              return {
                10: {
                  RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 90,
                  RouteIntelligenceAttributeKeys.minStopDurationMinutes: 5,
                },
              };
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(vehiclesListProvider.future);
        await container.read(sharedPreferencesProvider.future);
        await container.read(routeIntelGroupAttributesMapProvider.future);
        final th =
            container.read(routeIntelligenceThresholdsForVehicleProvider('1'));
        expect(th.overspeedThresholdKmh, 75);
        expect(th.minStopDuration, const Duration(minutes: 5));
      },
    );

    test(
      'no groupId does not require group map; device only',
      () async {
        final v = vehicle(
          id: '2',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 82,
          },
        );
        final container = ProviderContainer(
          overrides: [
            ...routeIntelHarness(),
            liveVehicleProvider.overrideWith((ref, id) {
              if (id != '2') return const AsyncValue.loading();
              return AsyncValue.data(v);
            }),
            vehiclesListProvider.overrideWith((ref) async => [v]),
          ],
        );
        addTearDown(container.dispose);
        await container.read(vehiclesListProvider.future);
        await container.read(sharedPreferencesProvider.future);
        final th =
            container.read(routeIntelligenceThresholdsForVehicleProvider('2'));
        expect(th.overspeedThresholdKmh, 82);
      },
    );

    test(
      'group missing in map → device + defaults for rest',
      () async {
        final v = vehicle(
          id: '3',
          groupId: '99',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 70,
          },
        );
        final container = ProviderContainer(
          overrides: [
            ...routeIntelHarness(),
            liveVehicleProvider.overrideWith((ref, id) {
              if (id != '3') return const AsyncValue.loading();
              return AsyncValue.data(v);
            }),
            vehiclesListProvider.overrideWith((ref) async => [v]),
            routeIntelGroupAttributesMapProvider.overrideWith(
              (ref) async => <int, Map<String, dynamic>>{},
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(vehiclesListProvider.future);
        await container.read(sharedPreferencesProvider.future);
        await container.read(routeIntelGroupAttributesMapProvider.future);
        final th =
            container.read(routeIntelligenceThresholdsForVehicleProvider('3'));
        expect(th.overspeedThresholdKmh, 70);
        expect(
          th.minStopDuration,
          RouteIntelligenceThresholds.defaults.minStopDuration,
        );
      },
    );

    test(
      'user.attributes apply when device and group sparse',
      () async {
        final v = vehicle(id: '4', deviceAttributes: const {});
        const u = UserEntity(
          id: '99',
          name: 'U',
          email: 'u@example.com',
          attributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 71,
          },
        );
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => u),
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
            liveVehicleProvider.overrideWith((ref, id) {
              if (id != '4') return const AsyncValue.loading();
              return AsyncValue.data(v);
            }),
            vehiclesListProvider.overrideWith((ref) async => [v]),
          ],
        );
        addTearDown(container.dispose);
        await container.read(vehiclesListProvider.future);
        await container.read(sharedPreferencesProvider.future);
        final th =
            container.read(routeIntelligenceThresholdsForVehicleProvider('4'));
        expect(th.overspeedThresholdKmh, 71);
      },
    );

    test(
      'device + group + user → device wins overspeed',
      () async {
        final v = vehicle(
          id: '5',
          groupId: '7',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 80,
          },
        );
        const u = UserEntity(
          id: '1',
          name: 'U',
          email: 'u@example.com',
          attributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 50,
          },
        );
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => u),
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
            liveVehicleProvider.overrideWith((ref, id) {
              if (id != '5') return const AsyncValue.loading();
              return AsyncValue.data(v);
            }),
            vehiclesListProvider.overrideWith((ref) async => [v]),
            routeIntelGroupAttributesMapProvider.overrideWith((ref) async {
              return {
                7: {
                  RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 120,
                  RouteIntelligenceAttributeKeys.minStopDurationMinutes: 3,
                },
              };
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(vehiclesListProvider.future);
        await container.read(sharedPreferencesProvider.future);
        await container.read(routeIntelGroupAttributesMapProvider.future);
        final th =
            container.read(routeIntelligenceThresholdsForVehicleProvider('5'));
        expect(th.overspeedThresholdKmh, 80);
        expect(th.minStopDuration, const Duration(minutes: 3));
      },
    );

    test(
      'local prefs weakest vs user on same vehicle',
      () async {
        final v = vehicle(id: '6', deviceAttributes: const {});
        const u = UserEntity(
          id: '2',
          name: 'U2',
          email: 'u2@example.com',
          attributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 65,
          },
        );
        SharedPreferences.setMockInitialValues({
          RouteIntelligenceLocalPreferenceKeys.overspeedThresholdKmh: 40,
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => u),
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
            liveVehicleProvider.overrideWith((ref, id) {
              if (id != '6') return const AsyncValue.loading();
              return AsyncValue.data(v);
            }),
            vehiclesListProvider.overrideWith((ref) async => [v]),
          ],
        );
        addTearDown(container.dispose);
        await container.read(vehiclesListProvider.future);
        await container.read(sharedPreferencesProvider.future);
        final th =
            container.read(routeIntelligenceThresholdsForVehicleProvider('6'));
        expect(th.overspeedThresholdKmh, 65);
      },
    );

    test(
      'resolution thresholds match vehicle provider; sources layer correctly',
      () async {
        final v = vehicle(
          id: 'r1',
          groupId: '20',
          deviceAttributes: const {
            RouteIntelligenceAttributeKeys.detectIgnition: false,
          },
        );
        const u = UserEntity(
          id: 'u-r1',
          name: 'U',
          email: 'u@example.com',
          attributes: const {
            RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 50,
          },
        );
        SharedPreferences.setMockInitialValues({
          RouteIntelligenceLocalPreferenceKeys.detectStops: false,
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => u),
            sharedPreferencesProvider.overrideWith((ref) async => prefs),
            liveVehicleProvider.overrideWith((ref, id) {
              if (id != 'r1') return const AsyncValue.loading();
              return AsyncValue.data(v);
            }),
            vehiclesListProvider.overrideWith((ref) async => [v]),
            routeIntelGroupAttributesMapProvider.overrideWith((ref) async {
              return {
                20: {
                  RouteIntelligenceAttributeKeys.minStopDurationMinutes: 6,
                  RouteIntelligenceAttributeKeys.overspeedThresholdKmh: 120,
                },
              };
            }),
          ],
        );
        addTearDown(container.dispose);
        await container.read(vehiclesListProvider.future);
        await container.read(sharedPreferencesProvider.future);
        await container.read(routeIntelGroupAttributesMapProvider.future);

        final th =
            container.read(routeIntelligenceThresholdsForVehicleProvider('r1'));
        final res = container.read(
          routeIntelligenceThresholdsResolutionForVehicleProvider('r1'),
        );
        expect(res.thresholds, th);
        expect(th.overspeedThresholdKmh, 120);
        expect(
          res.sources.overspeedThresholdKmhSource,
          RouteIntelligenceThresholdSource.group,
        );
        expect(
          res.sources.minStopDurationSource,
          RouteIntelligenceThresholdSource.group,
        );
        expect(
          res.sources.detectStopsSource,
          RouteIntelligenceThresholdSource.local,
        );
        expect(
          res.sources.detectIgnitionSource,
          RouteIntelligenceThresholdSource.device,
        );
      },
    );
  });

  group('routeIntelligenceThresholdsResolutionForVehicleProvider', () {
    test('empty vehicleId → defaults + all-default sources', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final r =
          container.read(routeIntelligenceThresholdsResolutionForVehicleProvider(''));
      expect(r.thresholds, RouteIntelligenceThresholds.defaults);
      expect(r.sources, RouteIntelligenceThresholdSources.allDefaults);
    });
  });
}
