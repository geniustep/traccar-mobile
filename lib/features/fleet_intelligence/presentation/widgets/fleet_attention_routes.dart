import 'package:flutter/foundation.dart';

/// روابط تنقّل اختيارية من ورقة **Phase 10G**؛ لا شبكة لا كتابة.
@immutable
class FleetAttentionRoutes {
  const FleetAttentionRoutes({
    this.openVehicleDetail,
    this.openMap,
    this.openTrips,
  });

  final void Function(String vehicleId)? openVehicleDetail;

  /// تتبّع / خريطة حيّة للمركبة.
  final void Function(String vehicleId)? openMap;

  /// قائمة رحلات المركبة.
  final void Function(String vehicleId)? openTrips;
}
