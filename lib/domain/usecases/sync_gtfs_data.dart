import '../../data/repositories/sync_repository_impl.dart';

class SyncGtfsData {
  final SyncRepositoryImpl _repository;

  SyncGtfsData(this._repository);

  Stream<SyncProgress> call() {
    return _repository.syncGtfsData();
  }
}
