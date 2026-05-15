import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../vehicles/domain/entities/vehicle.dart';

/// Shared vehicle status colors for map cards, lists, and markers.
Color vehicleStatusColor(String status) => switch (status) {
      'moving' => AppColors.statusMoving,
      'stopped' => AppColors.statusStopped,
      'idle' => AppColors.statusIdle,
      _ => AppColors.statusOffline,
    };

/// Resolves color from a [VehicleEntity] status string.
Color vehicleStatusColorFor(VehicleEntity vehicle) =>
    vehicleStatusColor(vehicle.status);
