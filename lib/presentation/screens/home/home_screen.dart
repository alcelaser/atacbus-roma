import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../providers/gtfs_providers.dart';
import '../../providers/sync_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Check if we need initial sync
    final hasSync = ref.watch(hasCompletedSyncProvider);
    if (hasSync.valueOrNull == false) {
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
                  Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.5)),
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
              children: ids.map((stopId) => _FavoriteStopCard(stopId: stopId)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}

class _FavoriteStopCard extends ConsumerWidget {
  const _FavoriteStopCard({required this.stopId});

  final String stopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopAsync = ref.watch(stopDetailProvider(stopId));

    return stopAsync.when(
      data: (stop) {
        if (stop == null) return const SizedBox.shrink();
        return Card(
          child: ListTile(
            leading: const Icon(Icons.star, color: Color(0xFFDAA520)),
            title: Text(stop.stopName),
            subtitle: stop.stopCode != null ? Text('Stop ${stop.stopCode}') : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/stop/${stop.stopId}'),
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
