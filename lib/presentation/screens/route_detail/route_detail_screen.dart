import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/line_badge.dart';

final routeDetailProvider =
    FutureProvider.family<RouteDetailData?, String>((ref, routeId) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  final route = await repo.getRouteById(routeId);
  if (route == null) return null;
  final stops = await repo.getStopsForRoute(routeId);
  return RouteDetailData(route: route, stops: stops);
});

class RouteDetailData {
  final dynamic route;
  final List<dynamic> stops;
  RouteDetailData({required this.route, required this.stops});
}

class RouteDetailScreen extends ConsumerWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detailAsync = ref.watch(routeDetailProvider(routeId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.when(
          data: (data) => data != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LineBadge(
                      lineNumber: data.route.routeShortName,
                      color: data.route.routeColor,
                      textColor: data.route.routeTextColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        data.route.routeLongName.isNotEmpty
                            ? data.route.routeLongName
                            : data.route.routeShortName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(l10n.routeStops),
          loading: () => Text(l10n.routeStops),
          error: (_, __) => Text(l10n.routeStops),
        ),
      ),
      body: detailAsync.when(
        data: (data) {
          if (data == null) {
            return Center(child: Text(l10n.noResults));
          }

          final stops = data.stops;
          if (stops.isEmpty) {
            return Center(
              child: Text(
                l10n.noResults,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              final isFirst = index == 0;
              final isLast = index == stops.length - 1;

              return InkWell(
                onTap: () => context.push('/stop/${stop.stopId}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Route timeline indicator
                        SizedBox(
                          width: 32,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: 3,
                                  color: isFirst
                                      ? Colors.transparent
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isFirst || isLast)
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 3,
                                  color: isLast
                                      ? Colors.transparent
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.stopName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: (isFirst || isLast)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (stop.stopCode != null)
                                  Text(
                                    l10n.stopCode(stop.stopCode!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      ),
    );
  }
}
