import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/departure_tile.dart';

class StopDetailScreen extends ConsumerStatefulWidget {
  const StopDetailScreen({super.key, required this.stopId});

  final String stopId;

  @override
  ConsumerState<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends ConsumerState<StopDetailScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      ApiConstants.rtRefreshInterval,
      (_) {
        if (mounted) {
          ref.invalidate(stopDeparturesProvider(widget.stopId));
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stopAsync = ref.watch(stopDetailProvider(widget.stopId));
    final departuresAsync = ref.watch(stopDeparturesProvider(widget.stopId));
    final isFavAsync = ref.watch(isFavoriteProvider(widget.stopId));
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: stopAsync.when(
          data: (stop) => Text(stop?.stopName ?? l10n.departures),
          loading: () => Text(l10n.departures),
          error: (_, __) => Text(l10n.departures),
        ),
        actions: [
          isFavAsync.when(
            data: (isFav) => IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? const Color(0xFFDAA520) : null,
              ),
              onPressed: () async {
                final toggle = ref.read(toggleFavoriteProvider);
                await toggle(widget.stopId);
                ref.invalidate(isFavoriteProvider(widget.stopId));
                ref.invalidate(favoriteStopIdsProvider);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (!isOnline)
            Container(
              width: double.infinity,
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.offline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: departuresAsync.when(
              data: (departures) {
                if (departures.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noDepartures,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(stopDeparturesProvider(widget.stopId));
                  },
                  child: ListView(
                    children: [
                      // Stop info card
                      stopAsync.when(
                        data: (stop) {
                          if (stop == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, color: theme.colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stop.stopName,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (stop.stopCode != null)
                                            Text(
                                              l10n.stopCode(stop.stopCode!),
                                              style: theme.textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Departures list
                      ...departures.map((dep) => DepartureTile(departure: dep)),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('${l10n.error}: $e'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
