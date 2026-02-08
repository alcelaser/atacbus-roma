import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/entities/service_alert.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/line_badge.dart';

/// Provider that fetches route metadata + stops for a given direction.
final routeDetailProvider = FutureProvider.family<RouteDetailData?,
    ({String routeId, int? directionId})>((ref, params) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  final route = await repo.getRouteById(params.routeId);
  if (route == null) return null;
  final stops = await repo.getStopsForRoute(params.routeId,
      directionId: params.directionId);
  return RouteDetailData(route: route, stops: stops);
});

class RouteDetailData {
  final RouteEntity route;
  final List<Stop> stops;
  RouteDetailData({required this.route, required this.stops});
}

class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  int? _selectedDirection;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final directionsAsync = ref.watch(routeDirectionsProvider(widget.routeId));
    final detailAsync = ref.watch(routeDetailProvider(
      (routeId: widget.routeId, directionId: _selectedDirection),
    ));

    // Auto-select the first direction once loaded
    directionsAsync.whenData((directions) {
      if (!_initialized && directions.isNotEmpty) {
        _initialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedDirection = directions.first);
          }
        });
      }
    });

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
      body: Column(
        children: [
          // Route alerts
          _buildRouteAlerts(theme, l10n),
          // Direction toggle
          _buildDirectionToggle(directionsAsync, theme, l10n),
          // Stop list
          Expanded(
            child: detailAsync.when(
              data: (data) {
                if (data == null) {
                  return Center(child: Text(l10n.noResults));
                }
                return _buildStopList(data.stops, theme, l10n);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteAlerts(ThemeData theme, AppLocalizations l10n) {
    final alertsAsync = ref.watch(serviceAlertsProvider);

    return alertsAsync.when(
      data: (allAlerts) {
        final routeAlerts = allAlerts
            .where((a) => a.routeIds.contains(widget.routeId))
            .toList();
        if (routeAlerts.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            color: theme.colorScheme.errorContainer,
            child: ExpansionTile(
              leading: Icon(
                Icons.warning_amber,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l10n.serviceAlerts,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              subtitle: Text(
                '${routeAlerts.length} ${routeAlerts.length == 1 ? l10n.activeAlert : l10n.activeAlerts}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              initiallyExpanded: true,
              children: routeAlerts
                  .map((alert) => ListTile(
                        title: Text(
                          alert.headerText ?? l10n.serviceAlerts,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: alert.descriptionText != null &&
                                alert.descriptionText!.isNotEmpty
                            ? Text(
                                alert.descriptionText!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        dense: true,
                      ))
                  .toList(),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDirectionToggle(
    AsyncValue<List<int>> directionsAsync,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return directionsAsync.when(
      data: (directions) {
        if (directions.length < 2) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: directions.map((dirId) {
              final isSelected = dirId == _selectedDirection;
              final headsignAsync = ref.watch(directionHeadsignProvider(
                (routeId: widget.routeId, directionId: dirId),
              ));
              final label = headsignAsync.when(
                data: (h) => h ?? '${l10n.direction(dirId.toString())}',
                loading: () => '...',
                error: (_, __) => '${l10n.direction(dirId.toString())}',
              );

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: dirId == directions.first ? 0 : 4,
                    right: dirId == directions.last ? 0 : 4,
                  ),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedDirection = dirId);
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStopList(
    List<Stop> stops,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
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
  }
}
