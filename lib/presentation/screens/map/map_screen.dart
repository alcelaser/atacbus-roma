import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/stop.dart';
import '../../providers/gtfs_providers.dart';
import '../../widgets/line_badge.dart';

/// Provider: all stops (cached once)
final allStopsProvider = FutureProvider<List<Stop>>((ref) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getAllStops();
});

/// Provider: user location
final userLocationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.medium,
  );
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  Timer? _vehicleRefreshTimer;
  bool _showVehicles = false;

  @override
  void initState() {
    super.initState();
    _vehicleRefreshTimer = Timer.periodic(
      ApiConstants.rtRefreshInterval,
      (_) {
        if (mounted && _showVehicles) {
          ref.invalidate(vehiclePositionsProvider);
        }
      },
    );
  }

  @override
  void dispose() {
    _vehicleRefreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stopsAsync = ref.watch(allStopsProvider);
    final vehiclesAsync = ref.watch(vehiclePositionsProvider);
    final locationAsync = ref.watch(userLocationProvider);

    final romeCenter = LatLng(
      AppConstants.defaultLatitude,
      AppConstants.defaultLongitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.map),
        actions: [
          IconButton(
            icon: Icon(
              _showVehicles
                  ? Icons.directions_bus
                  : Icons.directions_bus_outlined,
              color: _showVehicles ? theme.colorScheme.primary : null,
            ),
            tooltip: 'Live vehicles',
            onPressed: () {
              setState(() => _showVehicles = !_showVehicles);
              if (_showVehicles) {
                ref.invalidate(vehiclePositionsProvider);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: l10n.nearbyStops,
            onPressed: () {
              final pos = locationAsync.valueOrNull;
              if (pos != null) {
                _mapController.move(
                  LatLng(pos.latitude, pos.longitude),
                  15.0,
                );
              } else {
                ref.invalidate(userLocationProvider);
              }
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: locationAsync.whenOrNull(
                data: (pos) => pos != null
                    ? LatLng(pos.latitude, pos.longitude)
                    : null,
              ) ??
              romeCenter,
          initialZoom: 14.0,
          minZoom: 10.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.atacbus.atacbus_roma',
          ),

          // Stop markers
          stopsAsync.when(
            data: (stops) => MarkerLayer(
              markers: stops
                  .map((stop) => Marker(
                        point: LatLng(stop.stopLat, stop.stopLon),
                        width: 24,
                        height: 24,
                        child: GestureDetector(
                          onTap: () => _showStopSheet(context, stop),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            loading: () => const MarkerLayer(markers: []),
            error: (_, __) => const MarkerLayer(markers: []),
          ),

          // Vehicle markers
          if (_showVehicles)
            vehiclesAsync.when(
              data: (vehicles) => MarkerLayer(
                markers: vehicles
                    .where((v) => v.latitude != null && v.longitude != null)
                    .map((v) => Marker(
                          point: LatLng(v.latitude!, v.longitude!),
                          width: 28,
                          height: 28,
                          child: Transform.rotate(
                            angle: (v.bearing ?? 0) * (3.14159 / 180),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              loading: () => const MarkerLayer(markers: []),
              error: (_, __) => const MarkerLayer(markers: []),
            ),

          // User location
          locationAsync.when(
            data: (pos) {
              if (pos == null) return const MarkerLayer(markers: []);
              return MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(pos.latitude, pos.longitude),
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const MarkerLayer(markers: []),
            error: (_, __) => const MarkerLayer(markers: []),
          ),
        ],
      ),
    );
  }

  void _showStopSheet(BuildContext context, Stop stop) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop.stopName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (stop.stopCode != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.stopCode(stop.stopCode!),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, _) {
                final routesAsync =
                    ref.watch(routesForStopProvider(stop.stopId));
                return routesAsync.when(
                  data: (routes) {
                    if (routes.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: routes
                          .map((r) => LineBadge(
                                lineNumber: r.routeShortName,
                                color: r.routeColor,
                                textColor: r.routeTextColor,
                              ))
                          .toList(),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/stop/${stop.stopId}');
                },
                icon: const Icon(Icons.schedule),
                label: Text(l10n.departures),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
