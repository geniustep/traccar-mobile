import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/route_stop_address_resolver.dart';
import '../../core/stop_reverse_geocoder.dart';

/// Default: no outbound reverse-geocode calls. Override in tests or when wiring a backend/SDK.
final stopReverseGeocoderProvider = Provider<StopReverseGeocoder>((ref) {
  return const NoOpStopReverseGeocoder();
});

final routeStopAddressResolverProvider =
    Provider<RouteStopAddressResolver>((ref) {
  final geo = ref.watch(stopReverseGeocoderProvider);
  return RouteStopAddressResolver(geocoder: geo);
});
