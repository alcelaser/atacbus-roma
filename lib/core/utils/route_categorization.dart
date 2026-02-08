import '../../domain/entities/route_entity.dart';

/// Sub-categories for ATAC Rome routes.
enum BusCategory {
  metro,
  tram,
  regular,
  express,
  night,
  suburban,
}

/// Utility for categorizing ATAC Rome transit lines.
class RouteCategorization {
  RouteCategorization._();

  /// Determine the sub-category of a route based on GTFS type and ATAC
  /// naming conventions.
  static BusCategory categorize(RouteEntity route) {
    if (route.isMetro) return BusCategory.metro;
    if (route.isTram) return BusCategory.tram;

    final name = route.routeShortName.toUpperCase().trim();

    // Night buses: lines starting with "N" followed by digits (N1, N28, …)
    if (name.startsWith('N') && name.length > 1) {
      final rest = name.substring(1);
      if (int.tryParse(rest) != null) {
        return BusCategory.night;
      }
    }

    // Express buses: lines starting with "X"
    if (name.startsWith('X')) return BusCategory.express;

    // Suburban / regional: multi-letter prefixes (FR1, CO01, …)
    if (RegExp(r'^[A-Z]{2,}').hasMatch(name)) return BusCategory.suburban;

    // Numeric routes > 900 are typically suburban
    final numeric = int.tryParse(name);
    if (numeric != null && numeric > 900) return BusCategory.suburban;

    return BusCategory.regular;
  }

  /// Display sort order for categories.
  static int sortOrder(BusCategory category) {
    switch (category) {
      case BusCategory.metro:
        return 0;
      case BusCategory.tram:
        return 1;
      case BusCategory.regular:
        return 2;
      case BusCategory.express:
        return 3;
      case BusCategory.night:
        return 4;
      case BusCategory.suburban:
        return 5;
    }
  }

  /// Group [routes] by category, sorted by [sortOrder].
  static Map<BusCategory, List<RouteEntity>> groupRoutes(
      List<RouteEntity> routes) {
    final grouped = <BusCategory, List<RouteEntity>>{};
    for (final route in routes) {
      final cat = categorize(route);
      grouped.putIfAbsent(cat, () => []).add(route);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => sortOrder(a.key).compareTo(sortOrder(b.key))),
    );
  }
}
