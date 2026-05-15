import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../data/datasources/traccar_groups_route_intel_datasource.dart';

/// Cached `GET /groups` attributes map (`groupId` → `attributes`) for route-intel merge.
///
/// Fetched once per provider scope; survives short autoDispose via [keepAlive].
/// Errors yield `{}` inside the datasource — no thrown exceptions here.
///
/// Watched **only when** a vehicle has a parsable non-null `groupId` so idle
/// map screens avoid the call.
final routeIntelGroupAttributesMapProvider =
    FutureProvider.autoDispose<Map<int, Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final ds = TraccarGroupsRouteIntelDataSource(ref.watch(traccarClientProvider));
  return ds.fetchGroupAttributesById();
});
