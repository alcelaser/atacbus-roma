import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/sync_repository_impl.dart';
import '../../providers/sync_provider.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  Stream<SyncProgress>? _syncStream;
  SyncProgress _currentProgress = const SyncProgress(
    stage: SyncStage.downloading,
    progress: 0.0,
  );
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  void _startSync() {
    final syncRepo = ref.read(syncRepositoryProvider);
    _hasError = false;
    _syncStream = syncRepo.syncGtfsData();
    _syncStream!.listen(
      (progress) {
        if (mounted) {
          setState(() {
            _currentProgress = progress;
            if (progress.stage == SyncStage.complete) {
              ref.invalidate(hasCompletedSyncProvider);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) context.go('/');
              });
            }
            if (progress.stage == SyncStage.error) {
              _hasError = true;
            }
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _currentProgress = SyncProgress(
              stage: SyncStage.error,
              errorMessage: e.toString(),
            );
          });
        }
      },
    );
  }

  String _stageLabel(BuildContext context, SyncStage stage) {
    final l10n = AppLocalizations.of(context)!;
    switch (stage) {
      case SyncStage.downloading:
        return l10n.syncDownloading;
      case SyncStage.extracting:
        return l10n.syncExtracting;
      case SyncStage.importingStops:
        return l10n.syncImportingTable('stops');
      case SyncStage.importingRoutes:
        return l10n.syncImportingTable('routes');
      case SyncStage.importingTrips:
        return l10n.syncImportingTable('trips');
      case SyncStage.importingStopTimes:
        return l10n.syncImportingTable('stop_times');
      case SyncStage.importingCalendar:
        return l10n.syncImportingTable('calendar');
      case SyncStage.importingCalendarDates:
        return l10n.syncImportingTable('calendar_dates');
      case SyncStage.importingShapes:
        return l10n.syncImportingTable('shapes');
      case SyncStage.complete:
        return l10n.syncComplete;
      case SyncStage.error:
        return _currentProgress.errorMessage ?? 'Unknown error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bus,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                l10n.appTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.syncTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 48),
              if (!_hasError) ...[
                LinearProgressIndicator(
                  value: _currentProgress.progress > 0
                      ? _currentProgress.progress
                      : null,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  _stageLabel(context, _currentProgress.stage),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_currentProgress.progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _currentProgress.errorMessage ?? 'Unknown error',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentProgress = const SyncProgress(
                        stage: SyncStage.downloading,
                        progress: 0.0,
                      );
                    });
                    _startSync();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.syncRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
