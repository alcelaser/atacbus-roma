import '../repositories/gtfs_repository.dart';

class ToggleFavorite {
  final GtfsRepository _repository;

  ToggleFavorite(this._repository);

  Future<bool> call(String stopId) async {
    final isFav = await _repository.isFavorite(stopId);
    if (isFav) {
      await _repository.removeFavorite(stopId);
      return false;
    } else {
      await _repository.addFavorite(stopId);
      return true;
    }
  }
}
