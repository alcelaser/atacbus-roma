/// Type of a unified search result.
enum SearchResultType { stop, station, landmark }

/// A unified search result that can represent a bus stop, GTFS station,
/// or a well-known landmark.
class SearchResult {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final SearchResultType type;
  final String? stopId;

  const SearchResult({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.type,
    this.stopId,
  });
}
