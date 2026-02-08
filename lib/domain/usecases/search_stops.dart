import '../entities/stop.dart';
import '../repositories/gtfs_repository.dart';

class SearchStops {
  final GtfsRepository _repository;

  SearchStops(this._repository);

  Future<List<Stop>> call(String query) async {
    if (query.trim().isEmpty) return [];
    return _repository.searchStops(query.trim());
  }
}
