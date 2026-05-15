import 'vehicle_comparison_model.dart';

/// Load result for the comparison screen.
class VehicleComparisonState {
  const VehicleComparisonState({
    required this.isLoading,
    this.errorMessage,
    this.items = const [],
    required this.periodStart,
    required this.periodEnd,
  });

  const VehicleComparisonState.loading({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) : this(
          isLoading: true,
          periodStart: periodStart,
          periodEnd: periodEnd,
        );

  const VehicleComparisonState.success({
    required List<VehicleComparisonItem> items,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) : this(
          isLoading: false,
          items: items,
          periodStart: periodStart,
          periodEnd: periodEnd,
        );

  const VehicleComparisonState.failure({
    required String errorMessage,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) : this(
          isLoading: false,
          errorMessage: errorMessage,
          periodStart: periodStart,
          periodEnd: periodEnd,
        );

  final bool isLoading;
  final String? errorMessage;
  final List<VehicleComparisonItem> items;
  final DateTime periodStart;
  final DateTime periodEnd;

  bool get hasError => errorMessage != null;
  bool get isSuccess => !isLoading && !hasError;

  VehicleComparisonHighlights get highlights =>
      VehicleComparisonHighlights.fromItems(items);
}
