import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/driver_behavior_score_config.dart';

/// Phase **9G** — single injection point for driver score math params.
///
/// Returns [DriverBehaviorScoreConfig.defaults] only. Layered overrides
/// (device / group / user / local) are **not** merged here yet.
final driverBehaviorScoreConfigProvider =
    Provider<DriverBehaviorScoreConfig>((ref) {
  return DriverBehaviorScoreConfig.defaults;
});
