import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/line_badge.dart';

class RouteBrowserScreen extends ConsumerWidget {
  const RouteBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.allLines),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.allLines),
              Tab(text: l10n.bus),
              Tab(text: l10n.tram),
              Tab(text: l10n.metro),
            ],
          ),
        ),
        body: TabBarView(
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
    final routesAsync = typeFilter == null
        ? ref.watch(allRoutesProvider)
        : ref.watch(routesByTypeProvider(typeFilter!));

    return routesAsync.when(
      data: (routes) {
        if (routes.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noResults,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final route = routes[index];
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
              subtitle: Text(_routeTypeLabel(context, route.routeType)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/route/${route.routeId}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _routeTypeLabel(BuildContext context, int type) {
    final l10n = AppLocalizations.of(context)!;
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
}
