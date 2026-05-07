import 'package:flutter/material.dart';

/// Returns the best [IconData] for a Traccar device [category].
///
/// Covers every category defined in Traccar's `deviceCategories.js`:
/// animal, bicycle, boat, bus, camper, car, crane, helicopter,
/// motorcycle, offroad, person, pickup, plane, ship, tractor, train,
/// tram, trolleybus, truck, van, scooter — plus the implicit "default".
///
/// Returns [Icons.directions_car_rounded] when [category] is null, empty,
/// or not in the list.
IconData vehicleCategoryIcon(String? category) =>
    switch ((category ?? '').toLowerCase()) {
      'car'        => Icons.directions_car_rounded,
      'truck'      => Icons.local_shipping_rounded,
      'pickup'     => Icons.local_shipping_rounded,
      'van'        => Icons.airport_shuttle_rounded,
      'camper'     => Icons.rv_hookup_rounded,
      'bus'        => Icons.directions_bus_rounded,
      'trolleybus' => Icons.directions_bus_rounded,
      'motorcycle' || 'moto' => Icons.two_wheeler_rounded,
      'scooter'    => Icons.electric_scooter_rounded,
      'bicycle'    => Icons.pedal_bike_rounded,
      'person'     => Icons.directions_walk_rounded,
      'animal'     => Icons.pets_rounded,
      'boat'       => Icons.directions_boat_rounded,
      'ship'       => Icons.directions_boat_rounded,
      'plane'      => Icons.flight_rounded,
      'helicopter' => Icons.flight_rounded,
      'train'      => Icons.train_rounded,
      'tram'       => Icons.tram_rounded,
      'tractor'    => Icons.agriculture_rounded,
      'crane'      => Icons.construction_rounded,
      'offroad'    => Icons.terrain_rounded,
      _            => Icons.directions_car_rounded,
    };
