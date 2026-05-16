import 'multi_replay_kpi.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_timeline.dart';

enum MultiVehicleReplayLoadStatus {
  invalidSelection,
  loading,
  success,
  empty,
  error,
}

class MultiVehicleReplayLoadState {
  const MultiVehicleReplayLoadState({
    required this.status,
    this.tracks = const [],
    this.timeline,
    this.selectedDate,
    this.errorMessage,
    this.invalidReason,
    this.totalPoints = 0,
    this.loadDurationMs = 0,
    this.timelineBuildMs = 0,
    this.comparisonSummary,
  });

  final MultiVehicleReplayLoadStatus status;
  final List<MultiVehicleReplayTrack> tracks;
  final MultiVehicleReplayTimeline? timeline;
  final DateTime? selectedDate;
  final String? errorMessage;

  /// `too_few` | `too_many` when [status] is [invalidSelection].
  final String? invalidReason;
  final int totalPoints;
  final int loadDurationMs;
  final int timelineBuildMs;

  /// Route-based KPIs computed once at load (Phase R8).
  final MultiReplayComparisonSummary? comparisonSummary;

  bool get hasAnyRouteData =>
      tracks.any((t) => t.hasData);

  bool get allRequestsFailed =>
      tracks.isNotEmpty && tracks.every((t) => t.loadError != null && !t.hasData);

  MultiVehicleReplayLoadState copyWith({
    MultiVehicleReplayLoadStatus? status,
    List<MultiVehicleReplayTrack>? tracks,
    MultiVehicleReplayTimeline? timeline,
    DateTime? selectedDate,
    String? errorMessage,
    String? invalidReason,
    int? totalPoints,
    int? loadDurationMs,
    int? timelineBuildMs,
    MultiReplayComparisonSummary? comparisonSummary,
  }) =>
      MultiVehicleReplayLoadState(
        status: status ?? this.status,
        tracks: tracks ?? this.tracks,
        timeline: timeline ?? this.timeline,
        selectedDate: selectedDate ?? this.selectedDate,
        errorMessage: errorMessage ?? this.errorMessage,
        invalidReason: invalidReason ?? this.invalidReason,
        totalPoints: totalPoints ?? this.totalPoints,
        loadDurationMs: loadDurationMs ?? this.loadDurationMs,
        timelineBuildMs: timelineBuildMs ?? this.timelineBuildMs,
        comparisonSummary: comparisonSummary ?? this.comparisonSummary,
      );
}
