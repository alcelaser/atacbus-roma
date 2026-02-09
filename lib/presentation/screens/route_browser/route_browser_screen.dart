import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/route_categorization.dart';
import '../../../domain/entities/route_entity.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/line_badge.dart';

class RouteBrowserScreen extends ConsumerStatefulWidget {
  const RouteBrowserScreen({super.key});

  @override
  ConsumerState<RouteBrowserScreen> createState() => _RouteBrowserScreenState();
}

class _RouteBrowserScreenState extends ConsumerState<RouteBrowserScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchLines,
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(routeSearchQueryProvider.notifier).state = '';
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              ref.read(routeSearchQueryProvider.notifier).state = value;
              setState(() {});
            },
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.allLines),
              Tab(text: l10n.bus),
              Tab(text: l10n.tram),
              Tab(text: l10n.metro),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RouteList(typeFilter: null),
            _RouteList(typeFilter: 3), // Bus
            _RouteList(typeFilter: 0), // Tram
            _RouteList(typeFilter: 1), // Metro
          ],
        ),
      ),
    );
  }
}

class _RouteList extends ConsumerWidget {
  const _RouteList({this.typeFilter});

  final int? typeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(routeSearchQueryProvider).toLowerCase();
    final routesAsync = typeFilter == null
        ? ref.watch(allRoutesProvider)
        : ref.watch(routesByTypeProvider(typeFilter!));

    return routesAsync.when(
      data: (routes) {
        // Apply search filter
        var filtered = routes;
        if (searchQuery.isNotEmpty) {
          filtered = routes
              .where((r) =>
                  r.routeShortName.toLowerCase().contains(searchQuery) ||
                  r.routeLongName.toLowerCase().contains(searchQuery))
              .toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              l10n.noResults,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          );
        }

        // When searching, show flat list (no grouping)
        if (searchQuery.isNotEmpty) {
          return _buildFlatList(filtered, theme, l10n, context);
        }

        // Group by category
        final grouped = RouteCategorization.groupRoutes(filtered);

        // If only one category, skip section header
        if (grouped.length == 1) {
          return _buildFlatList(grouped.values.first, theme, l10n, context);
        }

        return CustomScrollView(
          slivers: grouped.entries.expand((entry) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    _categoryLabel(entry.key, l10n),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final route = entry.value[index];
                    return _buildRouteTile(route, theme, l10n, context);
                  },
                  childCount: entry.value.length,
                ),
              ),
            ];
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildFlatList(
    List<RouteEntity> routes,
    ThemeData theme,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    return ListView.builder(
      itemCount: routes.length,
      itemBuilder: (ctx, index) {
        return _buildRouteTile(routes[index], theme, l10n, context);
      },
    );
  }

  Widget _buildRouteTile(
    RouteEntity route,
    ThemeData theme,
    AppLocalizations l10n,
    BuildContext context,
  ) {
    return ListTile(
      leading: LineBadge(
        lineNumber: route.routeShortName,
        color: route.routeColor,
        textColor: route.routeTextColor,
      ),
      title: Text(
        route.routeLongName.isNotEmpty
            ? route.routeLongName
            : route.routeShortName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_routeTypeLabel(l10n, route.routeType)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/route/${route.routeId}'),
    );
  }

  String _routeTypeLabel(AppLocalizations l10n, int type) {
    switch (type) {
      case 0:
        return l10n.tram;
      case 1:
        return l10n.metro;
      case 3:
        return l10n.bus;
      default:
        return l10n.bus;
    }
  }

  String _categoryLabel(BusCategory category, AppLocalizations l10n) {
    switch (category) {
      case BusCategory.metro:
        return l10n.metro;
      case BusCategory.tram:
        return l10n.tram;
      case BusCategory.regular:
        return l10n.regularBus;
      case BusCategory.express:
        return l10n.expressBus;
      case BusCategory.night:
        return l10n.nightBus;
      case BusCategory.suburban:
        return l10n.suburbanBus;
    }
  }
}
