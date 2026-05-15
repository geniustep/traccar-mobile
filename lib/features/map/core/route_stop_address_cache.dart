/// Cache key for stop coordinates (~1.1 m precision at equator).
String routeStopAddressCacheKey(double latitude, double longitude) =>
    '${latitude.toStringAsFixed(5)}_${longitude.toStringAsFixed(5)}';
