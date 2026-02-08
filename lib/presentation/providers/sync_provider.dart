import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database/app_database.dart';
import '../../data/datasources/local/gtfs_file_storage.dart';
import '../../data/datasources/local/preferences_storage.dart';
import '../../data/repositories/sync_repository_impl.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final preferencesStorageProvider = Provider<PreferencesStorage>((ref) {
  return PreferencesStorage();
});

final gtfsFileStorageProvider = Provider<GtfsFileStorage>((ref) {
  return GtfsFileStorage();
});

final syncRepositoryProvider = Provider<SyncRepositoryImpl>((ref) {
  return SyncRepositoryImpl(
    db: ref.watch(databaseProvider),
    fileStorage: ref.watch(gtfsFileStorageProvider),
    preferencesStorage: ref.watch(preferencesStorageProvider),
  );
});

final syncProgressProvider = StreamProvider.autoDispose<SyncProgress>((ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  return syncRepo.syncGtfsData();
});

final hasCompletedSyncProvider = FutureProvider.autoDispose<bool>((ref) {
  final prefs = ref.watch(preferencesStorageProvider);
  return prefs.hasCompletedSync();
});
