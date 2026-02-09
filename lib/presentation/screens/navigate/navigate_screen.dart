import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/stop.dart';
import '../../../domain/entities/trip_plan.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/line_badge.dart';

class NavigateScreen extends ConsumerStatefulWidget {
  const NavigateScreen({super.key});

  @override
  ConsumerState<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends ConsumerState<NavigateScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _showOriginResults = false;
  bool _showDestinationResults = false;
  Timer? _originDebounce;
  Timer? _destinationDebounce;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originDebounce?.cancel();
    _destinationDebounce?.cancel();
    super.dispose();
  }

  void _onOriginChanged(String value) {
    _originDebounce?.cancel();
    _originDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(originSearchQueryProvider.notifier).state = value;
      setState(() {
        _showOriginResults = value.isNotEmpty;
      });
    });
  }

  void _onDestinationChanged(String value) {
    _destinationDebounce?.cancel();
    _destinationDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(destinationSearchQueryProvider.notifier).state = value;
      setState(() {
        _showDestinationResults = value.isNotEmpty;
      });
    });
  }

  void _selectOrigin(Stop stop) {
    ref.read(tripOriginProvider.notifier).state = TripOrigin.stop(stop);
    _originController.text = stop.stopName;
    setState(() => _showOriginResults = false);
    ref.read(originSearchQueryProvider.notifier).state = '';
  }

  void _selectDestination(Stop stop) {
    ref.read(tripDestinationProvider.notifier).state = stop;
    _destinationController.text = stop.stopName;
    setState(() => _showDestinationResults = false);
    ref.read(destinationSearchQueryProvider.notifier).state = '';
  }

  void _swapStops() {
    final origin = ref.read(tripOriginProvider);
    final destination = ref.read(tripDestinationProvider);

    if (origin != null && origin.selectedStop != null && destination != null) {
      ref.read(tripOriginProvider.notifier).state =
          TripOrigin.stop(destination);
      ref.read(tripDestinationProvider.notifier).state = origin.selectedStop;
      _originController.text = destination.stopName;
      _destinationController.text = origin.name;
    } else if (destination != null) {
      ref.read(tripOriginProvider.notifier).state =
          TripOrigin.stop(destination);
      ref.read(tripDestinationProvider.notifier).state = null;
      _originController.text = destination.stopName;
      _destinationController.text = '';
    }
  }

  void _useMyLocation() async {
    final l10n = AppLocalizations.of(context)!;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    if (!mounted) return;

    ref.read(tripOriginProvider.notifier).state = TripOrigin.gps(
      lat: position.latitude,
      lon: position.longitude,
      name: l10n.myLocation,
    );
    _originController.text = l10n.myLocation;
    setState(() => _showOriginResults = false);
  }

  void _saveRoute() {
    final origin = ref.read(tripOriginProvider);
    final destination = ref.read(tripDestinationProvider);
    if (origin == null || destination == null) return;

    final repo = ref.read(gtfsRepositoryProvider);
    repo.addFavoriteRoute(
      originLat: origin.lat,
      originLon: origin.lon,
      originName: origin.name,
      destStopId: destination.stopId,
      destStopName: destination.stopName,
    );

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.routeSaved)),
    );
  }

  void _showSavedRoutes() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final favRoutes = ref.watch(favoriteRoutesProvider);
            return favRoutes.when(
              data: (routes) {
                if (routes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        l10n.noSavedRoutes,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return ListTile(
                      leading: const Icon(Icons.alt_route),
                      title: Text(
                        '${route.originName} \u2192 ${route.destStopName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          _confirmDeleteRoute(sheetContext, route.id);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _loadFavoriteRoute(
                          route.originLat,
                          route.originLon,
                          route.originName,
                          route.destStopId,
                          route.destStopName,
                        );
                      },
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteRoute(BuildContext sheetContext, int id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: sheetContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteRoute),
          content: Text(l10n.confirmDeleteRoute),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                ref.read(gtfsRepositoryProvider).removeFavoriteRoute(id);
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.deleteRoute),
            ),
          ],
        );
      },
    );
  }

  void _loadFavoriteRoute(
    double originLat,
    double originLon,
    String originName,
    String destStopId,
    String destStopName,
  ) async {
    ref.read(tripOriginProvider.notifier).state = TripOrigin.gps(
      lat: originLat,
      lon: originLon,
      name: originName,
    );
    _originController.text = originName;

    final repo = ref.read(gtfsRepositoryProvider);
    final stop = await repo.getStopById(destStopId);
    if (stop != null && mounted) {
      _selectDestination(stop);
    } else if (mounted) {
      _destinationController.text = destStopName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final origin = ref.watch(tripOriginProvider);
    final destination = ref.watch(tripDestinationProvider);
    final canSave = origin != null && destination != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navigate),
        actions: [
          if (canSave)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: l10n.saveRoute,
              onPressed: _saveRoute,
            ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: l10n.savedRoutes,
            onPressed: _showSavedRoutes,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInputCard(theme, l10n),
          Expanded(
            child: _buildResults(theme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _originController,
                    decoration: InputDecoration(
                      hintText: l10n.from,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    onChanged: _onOriginChanged,
                    onTap: () {
                      if (_originController.text.isNotEmpty) {
                        setState(() => _showOriginResults = true);
                        _onOriginChanged(_originController.text);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location, size: 20),
                  tooltip: l10n.useMyLocation,
                  onPressed: _useMyLocation,
                ),
              ],
            ),
            if (_showOriginResults) _buildOriginAutocomplete(theme),
            const Divider(height: 1),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: l10n.to,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    onChanged: _onDestinationChanged,
                    onTap: () {
                      if (_destinationController.text.isNotEmpty) {
                        setState(() => _showDestinationResults = true);
                        _onDestinationChanged(_destinationController.text);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_vert, size: 20),
                  tooltip: l10n.swapStops,
                  onPressed: _swapStops,
                ),
              ],
            ),
            if (_showDestinationResults) _buildDestinationAutocomplete(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginAutocomplete(ThemeData theme) {
    final resultsAsync = ref.watch(originSearchResultsProvider);
    return resultsAsync.when(
      data: (stops) {
        if (stops.isEmpty) return const SizedBox.shrink();
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.location_on, size: 18),
                title: Text(stop.stopName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _selectOrigin(stop),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDestinationAutocomplete(ThemeData theme) {
    final resultsAsync = ref.watch(destinationSearchResultsProvider);
    return resultsAsync.when(
      data: (stops) {
        if (stops.isEmpty) return const SizedBox.shrink();
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.location_on, size: 18),
                title: Text(stop.stopName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _selectDestination(stop),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildResults(ThemeData theme, AppLocalizations l10n) {
    final resultAsync = ref.watch(tripPlanResultProvider);

    return resultAsync.when(
      data: (result) {
        if (result == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.selectStops,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (result.itineraries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.noRoutesFound,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: result.itineraries.length,
          itemBuilder: (context, index) {
            return _ItineraryCard(
              itinerary: result.itineraries[index],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('${l10n.error}: $e'),
      ),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({required this.itinerary});

  final TripItinerary itinerary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final duration = itinerary.totalDurationSeconds ~/ 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/trip-detail', extra: itinerary);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: itinerary.isDirect
                          ? theme.colorScheme.primaryContainer
                          : itinerary.hasWalkingTransfer
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      itinerary.isDirect
                          ? l10n.direct
                          : itinerary.hasWalkingTransfer
                              ? l10n.walkingTransfer
                              : l10n.transfer,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: itinerary.isDirect
                            ? theme.colorScheme.onPrimaryContainer
                            : itinerary.hasWalkingTransfer
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.totalDuration(duration),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...itinerary.legs.asMap().entries.map((entry) {
                final index = entry.key;
                final leg = entry.value;
                // Walking legs are shown as transfer indicators, not as leg rows
                if (leg.isWalking) {
                  final walkMin = leg.durationSeconds ~/ 60;
                  final distMeters = leg.walkingDistanceMeters?.round() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${l10n.walkTo(leg.alightStopName)} (${l10n.walkDistance(distMeters)})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '~$walkMin min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0 && !itinerary.legs[index - 1].isWalking) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.transfer_within_a_station,
                              size: 16,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.transferAt(leg.boardStopName),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildLegRow(leg, theme, l10n),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegRow(TripLeg leg, ThemeData theme, AppLocalizations l10n) {
    final depTime = DateTimeUtils.formatTime(leg.departureSeconds);
    final arrTime = DateTimeUtils.formatTime(leg.arrivalSeconds);

    return Row(
      children: [
        LineBadge(
          lineNumber: leg.routeShortName,
          color: leg.routeColor,
          fontSize: 11,
        ),
        const SizedBox(width: 8),
        Text(
          depTime,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.arrow_forward,
            size: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        Text(
          arrTime,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.nStops(leg.stopCount),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        if (leg.tripHeadsign != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              leg.tripHeadsign!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
