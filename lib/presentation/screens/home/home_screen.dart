import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../providers/gtfs_providers.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/line_badge.dart';
import '../../../core/utils/date_time_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  DateTime? _lastRefreshed;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(nearbyStopsProvider);
    ref.invalidate(favoriteStopIdsProvider);
    setState(() {
      _lastRefreshed = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Check if we need initial sync.
    // Only redirect when we have a confirmed AsyncData(false) — NOT during
    // AsyncLoading (which preserves the stale previous value after invalidation).
    final hasSync = ref.watch(hasCompletedSyncProvider);
    if (!hasSync.isLoading && hasSync.valueOrNull == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/sync');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchStopsByNameOrCode,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              )
            : Text(l10n.appTitle),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
          ],
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _isSearching ? _buildSearchResults() : _buildHome(l10n, theme),
    );
  }

  Widget _buildSearchResults() {
    final results = ref.watch(searchResultsProvider);

    return results.when(
      data: (stops) {
        if (stops.isEmpty) {
          final query = ref.watch(searchQueryProvider);
          if (query.isEmpty) {
            return const Center(child: Text('Type to search...'));
          }
          return Center(
            child: Text(AppLocalizations.of(context)!.noResults),
          );
        }
        return ListView.builder(
          itemCount: stops.length,
          itemBuilder: (context, index) {
            final stop = stops[index];
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(stop.stopName),
              subtitle: stop.stopCode != null
                  ? Text(AppLocalizations.of(context)!.stopCode(stop.stopCode!))
                  : null,
              onTap: () => context.push('/stop/${stop.stopId}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildHome(AppLocalizations l10n, ThemeData theme) {
    final favStopIds = ref.watch(favoriteStopIdsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search card
        Card(
          child: InkWell(
            onTap: () => setState(() => _isSearching = true),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.search,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 12),
                  Text(
                    l10n.searchStops,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_lastRefreshed != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'last refreshed at: ${_lastRefreshed!.hour.toString().padLeft(2, '0')}:${_lastRefreshed!.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Favorites section
        Text(
          l10n.favorites,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        favStopIds.when(
          data: (ids) {
            if (ids.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.noFavorites,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: ids
                  .map((stopId) => _FavoriteStopCard(stopId: stopId))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: 24),

        // Nearby stops section
        Text(
          l10n.nearbyStops,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildNearbyStops(l10n, theme),
      ],
    );
  }

  Widget _buildNearbyStops(AppLocalizations l10n, ThemeData theme) {
    final nearbyAsync = ref.watch(nearbyStopsProvider);

    return nearbyAsync.when(
      data: (nearbyStops) {
        if (nearbyStops.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.noNearbyStops,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }
        return Column(
          children: nearbyStops
              .map((nearby) => _NearbyStopCard(nearbyStop: nearby))
              .toList(),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.locationPermissionDenied,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteStopCard extends ConsumerStatefulWidget {
  const _FavoriteStopCard({required this.stopId});

  final String stopId;

  @override
  ConsumerState<_FavoriteStopCard> createState() => _FavoriteStopCardState();
}

class _FavoriteStopCardState extends ConsumerState<_FavoriteStopCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Refresh countdown every 15 seconds
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int secondsUntil) {
    if (secondsUntil <= 0) return 'Now';
    final minutes = secondsUntil ~/ 60;
    if (minutes == 0) return '<1 min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stopAsync = ref.watch(stopDetailProvider(widget.stopId));
    final depsAsync = ref.watch(stopDeparturesProvider(widget.stopId));

    return stopAsync.when(
      data: (stop) {
        if (stop == null) return const SizedBox.shrink();

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/stop/${stop.stopId}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFDAA520), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.stopName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ],
                  ),
                  // Next departures preview
                  depsAsync.when(
                    data: (deps) {
                      if (deps.isEmpty) return const SizedBox.shrink();
                      final now = DateTimeUtils.currentTimeAsSeconds();
                      final upcoming = deps.take(3).toList();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, left: 28),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: upcoming.map((dep) {
                            final secsUntil = dep.effectiveSeconds - now;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LineBadge(
                                  lineNumber: dep.routeShortName,
                                  color: dep.routeColor,
                                  fontSize: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatCountdown(secsUntil),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: secsUntil <= 120
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                                if (dep.isRealtime) ...[
                                  const SizedBox(width: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 8, left: 28),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Loading...'),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class _NearbyStopCard extends ConsumerStatefulWidget {
  const _NearbyStopCard({required this.nearbyStop});

  final NearbyStop nearbyStop;

  @override
  ConsumerState<_NearbyStopCard> createState() => _NearbyStopCardState();
}

class _NearbyStopCardState extends ConsumerState<_NearbyStopCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int secondsUntil) {
    if (secondsUntil <= 0) return 'Now';
    final minutes = secondsUntil ~/ 60;
    if (minutes == 0) return '<1 min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nearby = widget.nearbyStop;
    final depsAsync = ref.watch(stopDeparturesProvider(nearby.stop.stopId));

    final distanceStr = nearby.distanceMeters < 1000
        ? '${nearby.distanceMeters.round()} m'
        : '${(nearby.distanceMeters / 1000).toStringAsFixed(1)} km';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/stop/${nearby.stop.stopId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Distance badge as leading element
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      distanceStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nearby.stop.stopName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
              // Next 2 departures
              depsAsync.when(
                data: (deps) {
                  if (deps.isEmpty) return const SizedBox.shrink();
                  final now = DateTimeUtils.currentTimeAsSeconds();
                  final upcoming = deps.take(2).toList();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: upcoming.map((dep) {
                        final secsUntil = dep.effectiveSeconds - now;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LineBadge(
                              lineNumber: dep.routeShortName,
                              color: dep.routeColor,
                              fontSize: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatCountdown(secsUntil),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: secsUntil <= 120
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            if (dep.isRealtime) ...[
                              const SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
