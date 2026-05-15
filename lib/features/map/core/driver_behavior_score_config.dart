import 'package:flutter/foundation.dart';

/// Tunable penalties and caps for [DriverBehaviorScoreCalculator].
///
/// **Phase 9G — foundation:** invalid merged values (future: device / group / user /
/// local layers) must not break scoring. Call [normalized] at calculator entry; it is
/// **idempotent** on valid configs and preserves [defaults] numerically. [cacheKey] is
/// derived from the normalized snapshot for memoization. Layer resolution is **not**
/// wired here — `driver_behavior_score_config_provider.dart` exposes defaults-only for now.
@immutable
class DriverBehaviorScoreConfig {
  const DriverBehaviorScoreConfig({
    this.baseScore = 100.0,
    this.excellentMin = 90,
    this.goodMin = 75,
    this.moderateMin = 55,
    this.overspeedEventPenalty = 5.0,
    this.severeOverspeedEventPenalty = 10.0,
    this.severeOverspeedKmh = 120.0,
    this.longStopShareThreshold = 0.45,
    this.longStopPenalty = 3.0,
    this.referenceStopsPerKm = 2.5,
    this.excessiveStopsPenaltyRate = 1.25,
    this.excessiveStopsPenalty = 5.0,
    this.ignitionTransitionPenalty = 2.0,
    this.ignitionTransitionsSoftMax = 4,
    this.efficiencyAvgSpeedFloorKmh = 12.0,
    this.efficiencyStopCountFloor = 4,
    this.efficiencyPenalty = 3.0,
    this.maxSpeedPenalty = 40.0,
    this.maxStopPenalty = 20.0,
    this.maxIgnitionPenalty = 10.0,
    this.maxEfficiencyPenalty = 6.0,
    this.maxTotalPenalty = 80.0,
    this.minScorableDistanceKm = 0.5,
    this.minScorableDuration = const Duration(minutes: 3),
  });

  static const DriverBehaviorScoreConfig defaults = DriverBehaviorScoreConfig();

  final double baseScore;

  final int excellentMin;
  final int goodMin;
  final int moderateMin;

  /// Per overspeed **event** (non-severe tier).
  final double overspeedEventPenalty;

  /// Per overspeed event whose peak ≥ [severeOverspeedKmh] when [RouteEventAnalysisResult] supplied,
  /// or substituted heuristically from [TripSegment.maxSpeedKmh].
  final double severeOverspeedEventPenalty;

  /// Peak speed threshold (km/h) for tagging **heavy overspeed**.
  final double severeOverspeedKmh;

  /// When ([totalStopDuration] / [duration]) exceeds this fraction, apply [longStopPenalty].
  final double longStopShareThreshold;

  final double longStopPenalty;

  /// Baseline stops per km — exceeding it drives proportional penalty (capped).
  final double referenceStopsPerKm;

  /// Penalty multiplier on excess stops/km beyond [referenceStopsPerKm].
  final double excessiveStopsPenaltyRate;

  /// Cap for the excessive-stops component before [maxStopPenalty].
  final double excessiveStopsPenalty;

  final double ignitionTransitionPenalty;

  /// Transitions beyond this budget on the trip incur penalties (light touch).
  final int ignitionTransitionsSoftMax;

  final double efficiencyAvgSpeedFloorKmh;
  final int efficiencyStopCountFloor;
  final double efficiencyPenalty;

  final double maxSpeedPenalty;
  final double maxStopPenalty;
  final double maxIgnitionPenalty;
  final double maxEfficiencyPenalty;
  final double maxTotalPenalty;

  final double minScorableDistanceKm;
  final Duration minScorableDuration;

  /// Canonical values safe for scoring. Invalid intervals fall back field-wise to [defaults].
  DriverBehaviorScoreConfig normalized() {
    const d = DriverBehaviorScoreConfig.defaults;

    double nnFin(double x, double fallback, {required bool strictPositive}) {
      if (!x.isFinite) return fallback;
      if (x < 0) return fallback;
      if (strictPositive && x <= 0) return fallback;
      return x;
    }

    int nnNat(int x, int fallback) {
      if (x < 0) return fallback;
      return x;
    }

    var base = nnFin(baseScore, d.baseScore, strictPositive: true);
    if (base > 1e6) base = d.baseScore;

    var ex = excellentMin.clamp(0, 100);
    var gd = goodMin.clamp(0, 100);
    var md = moderateMin.clamp(0, 100);
    if (!(ex >= gd && gd >= md)) {
      ex = d.excellentMin;
      gd = d.goodMin;
      md = d.moderateMin;
    }

    final overs = nnFin(overspeedEventPenalty, d.overspeedEventPenalty,
        strictPositive: false);
    final severeO = nnFin(
        severeOverspeedEventPenalty, d.severeOverspeedEventPenalty,
        strictPositive: false);
    final severeK = nnFin(severeOverspeedKmh, d.severeOverspeedKmh,
        strictPositive: true);

    var share =
        nnFin(longStopShareThreshold, d.longStopShareThreshold, strictPositive: false);
    if (share > 1.0) share = d.longStopShareThreshold;

    final longPen =
        nnFin(longStopPenalty, d.longStopPenalty, strictPositive: false);

    var refKm =
        nnFin(referenceStopsPerKm, d.referenceStopsPerKm, strictPositive: true);
    if (refKm <= 1e-9) refKm = d.referenceStopsPerKm;

    final exRate = nnFin(
        excessiveStopsPenaltyRate, d.excessiveStopsPenaltyRate,
        strictPositive: false);
    final exCap =
        nnFin(excessiveStopsPenalty, d.excessiveStopsPenalty, strictPositive: false);

    final ignPen = nnFin(
        ignitionTransitionPenalty, d.ignitionTransitionPenalty,
        strictPositive: false);
    var ignSoft = nnNat(ignitionTransitionsSoftMax, d.ignitionTransitionsSoftMax);

    final effFloorKmh =
        nnFin(efficiencyAvgSpeedFloorKmh, d.efficiencyAvgSpeedFloorKmh,
            strictPositive: false);
    var effStopsFloor = nnNat(efficiencyStopCountFloor, d.efficiencyStopCountFloor);

    final effPen =
        nnFin(efficiencyPenalty, d.efficiencyPenalty, strictPositive: false);

    var maxSpeed =
        nnFin(maxSpeedPenalty, d.maxSpeedPenalty, strictPositive: false);
    var maxStop =
        nnFin(maxStopPenalty, d.maxStopPenalty, strictPositive: false);
    var maxIgn =
        nnFin(maxIgnitionPenalty, d.maxIgnitionPenalty, strictPositive: false);
    var maxEff =
        nnFin(maxEfficiencyPenalty, d.maxEfficiencyPenalty, strictPositive: false);
    var maxTot =
        nnFin(maxTotalPenalty, d.maxTotalPenalty, strictPositive: true);
    if (maxTot > base) maxTot = base;
    maxSpeed = maxSpeed.clamp(0, maxTot);
    maxStop = maxStop.clamp(0, maxTot);
    maxIgn = maxIgn.clamp(0, maxTot);
    maxEff = maxEff.clamp(0, maxTot);

    var minKm =
        nnFin(minScorableDistanceKm, d.minScorableDistanceKm, strictPositive: true);
    if (minKm > base) minKm = d.minScorableDistanceKm;

    var minDur = minScorableDuration;
    if (minDur <= Duration.zero || minDur.inMilliseconds > 1 << 30) {
      minDur = d.minScorableDuration;
    }

    return DriverBehaviorScoreConfig(
      baseScore: base,
      excellentMin: ex,
      goodMin: gd,
      moderateMin: md,
      overspeedEventPenalty: overs,
      severeOverspeedEventPenalty: severeO,
      severeOverspeedKmh: severeK,
      longStopShareThreshold: share,
      longStopPenalty: longPen,
      referenceStopsPerKm: refKm,
      excessiveStopsPenaltyRate: exRate,
      excessiveStopsPenalty: exCap,
      ignitionTransitionPenalty: ignPen,
      ignitionTransitionsSoftMax: ignSoft,
      efficiencyAvgSpeedFloorKmh: effFloorKmh,
      efficiencyStopCountFloor: effStopsFloor,
      efficiencyPenalty: effPen,
      maxSpeedPenalty: maxSpeed,
      maxStopPenalty: maxStop,
      maxIgnitionPenalty: maxIgn,
      maxEfficiencyPenalty: maxEff,
      maxTotalPenalty: maxTot,
      minScorableDistanceKm: minKm,
      minScorableDuration: minDur,
    );
  }

  /// Memoization fingerprint for the **[normalized]** shape.
  String get cacheKey {
    final n = normalized();
    return [
      n.baseScore.toStringAsFixed(6),
      '${n.excellentMin}|${n.goodMin}|${n.moderateMin}',
      n.overspeedEventPenalty.toStringAsFixed(6),
      n.severeOverspeedEventPenalty.toStringAsFixed(6),
      n.severeOverspeedKmh.toStringAsFixed(6),
      n.longStopShareThreshold.toStringAsFixed(6),
      n.longStopPenalty.toStringAsFixed(6),
      n.referenceStopsPerKm.toStringAsFixed(6),
      n.excessiveStopsPenaltyRate.toStringAsFixed(6),
      n.excessiveStopsPenalty.toStringAsFixed(6),
      n.ignitionTransitionPenalty.toStringAsFixed(6),
      '${n.ignitionTransitionsSoftMax}',
      n.efficiencyAvgSpeedFloorKmh.toStringAsFixed(6),
      '${n.efficiencyStopCountFloor}',
      n.efficiencyPenalty.toStringAsFixed(6),
      n.maxSpeedPenalty.toStringAsFixed(6),
      n.maxStopPenalty.toStringAsFixed(6),
      n.maxIgnitionPenalty.toStringAsFixed(6),
      n.maxEfficiencyPenalty.toStringAsFixed(6),
      n.maxTotalPenalty.toStringAsFixed(6),
      n.minScorableDistanceKm.toStringAsFixed(6),
      '${n.minScorableDuration.inSeconds}',
    ].join('#');
  }

  DriverBehaviorScoreConfig copyWith({
    double? baseScore,
    int? excellentMin,
    int? goodMin,
    int? moderateMin,
    double? overspeedEventPenalty,
    double? severeOverspeedEventPenalty,
    double? severeOverspeedKmh,
    double? longStopShareThreshold,
    double? longStopPenalty,
    double? referenceStopsPerKm,
    double? excessiveStopsPenaltyRate,
    double? excessiveStopsPenalty,
    double? ignitionTransitionPenalty,
    int? ignitionTransitionsSoftMax,
    double? efficiencyAvgSpeedFloorKmh,
    int? efficiencyStopCountFloor,
    double? efficiencyPenalty,
    double? maxSpeedPenalty,
    double? maxStopPenalty,
    double? maxIgnitionPenalty,
    double? maxEfficiencyPenalty,
    double? maxTotalPenalty,
    double? minScorableDistanceKm,
    Duration? minScorableDuration,
  }) =>
      DriverBehaviorScoreConfig(
        baseScore: baseScore ?? this.baseScore,
        excellentMin: excellentMin ?? this.excellentMin,
        goodMin: goodMin ?? this.goodMin,
        moderateMin: moderateMin ?? this.moderateMin,
        overspeedEventPenalty:
            overspeedEventPenalty ?? this.overspeedEventPenalty,
        severeOverspeedEventPenalty:
            severeOverspeedEventPenalty ?? this.severeOverspeedEventPenalty,
        severeOverspeedKmh: severeOverspeedKmh ?? this.severeOverspeedKmh,
        longStopShareThreshold:
            longStopShareThreshold ?? this.longStopShareThreshold,
        longStopPenalty: longStopPenalty ?? this.longStopPenalty,
        referenceStopsPerKm: referenceStopsPerKm ?? this.referenceStopsPerKm,
        excessiveStopsPenaltyRate:
            excessiveStopsPenaltyRate ?? this.excessiveStopsPenaltyRate,
        excessiveStopsPenalty:
            excessiveStopsPenalty ?? this.excessiveStopsPenalty,
        ignitionTransitionPenalty:
            ignitionTransitionPenalty ?? this.ignitionTransitionPenalty,
        ignitionTransitionsSoftMax:
            ignitionTransitionsSoftMax ?? this.ignitionTransitionsSoftMax,
        efficiencyAvgSpeedFloorKmh:
            efficiencyAvgSpeedFloorKmh ?? this.efficiencyAvgSpeedFloorKmh,
        efficiencyStopCountFloor:
            efficiencyStopCountFloor ?? this.efficiencyStopCountFloor,
        efficiencyPenalty: efficiencyPenalty ?? this.efficiencyPenalty,
        maxSpeedPenalty: maxSpeedPenalty ?? this.maxSpeedPenalty,
        maxStopPenalty: maxStopPenalty ?? this.maxStopPenalty,
        maxIgnitionPenalty: maxIgnitionPenalty ?? this.maxIgnitionPenalty,
        maxEfficiencyPenalty:
            maxEfficiencyPenalty ?? this.maxEfficiencyPenalty,
        maxTotalPenalty: maxTotalPenalty ?? this.maxTotalPenalty,
        minScorableDistanceKm:
            minScorableDistanceKm ?? this.minScorableDistanceKm,
        minScorableDuration: minScorableDuration ?? this.minScorableDuration,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DriverBehaviorScoreConfig &&
            runtimeType == other.runtimeType &&
            baseScore == other.baseScore &&
            excellentMin == other.excellentMin &&
            goodMin == other.goodMin &&
            moderateMin == other.moderateMin &&
            overspeedEventPenalty == other.overspeedEventPenalty &&
            severeOverspeedEventPenalty ==
                other.severeOverspeedEventPenalty &&
            severeOverspeedKmh == other.severeOverspeedKmh &&
            longStopShareThreshold == other.longStopShareThreshold &&
            longStopPenalty == other.longStopPenalty &&
            referenceStopsPerKm == other.referenceStopsPerKm &&
            excessiveStopsPenaltyRate == other.excessiveStopsPenaltyRate &&
            excessiveStopsPenalty == other.excessiveStopsPenalty &&
            ignitionTransitionPenalty == other.ignitionTransitionPenalty &&
            ignitionTransitionsSoftMax == other.ignitionTransitionsSoftMax &&
            efficiencyAvgSpeedFloorKmh ==
                other.efficiencyAvgSpeedFloorKmh &&
            efficiencyStopCountFloor == other.efficiencyStopCountFloor &&
            efficiencyPenalty == other.efficiencyPenalty &&
            maxSpeedPenalty == other.maxSpeedPenalty &&
            maxStopPenalty == other.maxStopPenalty &&
            maxIgnitionPenalty == other.maxIgnitionPenalty &&
            maxEfficiencyPenalty == other.maxEfficiencyPenalty &&
            maxTotalPenalty == other.maxTotalPenalty &&
            minScorableDistanceKm == other.minScorableDistanceKm &&
            minScorableDuration == other.minScorableDuration;
  }

  @override
  int get hashCode => Object.hashAll([
        baseScore,
        excellentMin,
        goodMin,
        moderateMin,
        overspeedEventPenalty,
        severeOverspeedEventPenalty,
        severeOverspeedKmh,
        longStopShareThreshold,
        longStopPenalty,
        referenceStopsPerKm,
        excessiveStopsPenaltyRate,
        excessiveStopsPenalty,
        ignitionTransitionPenalty,
        ignitionTransitionsSoftMax,
        efficiencyAvgSpeedFloorKmh,
        efficiencyStopCountFloor,
        efficiencyPenalty,
        maxSpeedPenalty,
        maxStopPenalty,
        maxIgnitionPenalty,
        maxEfficiencyPenalty,
        maxTotalPenalty,
        minScorableDistanceKm,
        minScorableDuration,
      ]);
}
