/// Shared Traccar unit conversions (speed from API/socket is typically in knots).
class TraccarUnits {
  TraccarUnits._();

  static const double knotsToKmhFactor = 1.852;

  static double knotsToKmh(double knots) => knots * knotsToKmhFactor;
}
