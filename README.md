# ATAC Bus Roma

A Flutter application for browsing bus timetables and live arrival times for all ATAC stops in Rome. Built with Clean Architecture, Riverpod state management, and a Drift SQLite database. Consumes ATAC's publicly available GTFS static and GTFS-Realtime data feeds.

## Architecture

```
DataSource -> Repository (impl) -> UseCase -> Riverpod Provider -> ConsumerWidget
```

The project follows **Clean Architecture** with three layers:

| Layer | Directory | Responsibility |
|-------|-----------|---------------|
| **Data** | `lib/data/` | Drift database, HTTP clients, CSV/protobuf parsing, repository implementations |
| **Domain** | `lib/domain/` | Entities, abstract repository interfaces, use cases (business logic) |
| **Presentation** | `lib/presentation/` | Riverpod providers, screens (ConsumerWidget), shared widgets |

**State management**: `flutter_riverpod` 2.x with standard `Provider`, `FutureProvider`, `FutureProvider.family`, `StateProvider`, and `StreamProvider` (no code generation / `@riverpod` annotation).

**Navigation**: `go_router` with a `ShellRoute` wrapping the four main tabs (Home, Lines, Map, Alerts) in a `NavigationBar`. Stop detail, settings, and sync routes live outside the shell as full-screen pushes.

**Database**: `drift` (SQLite) with 8 tables, 9 performance indexes (including composite `(stop_id, departure_time)` for fast departure lookups), batch inserts (5000 rows/transaction), schema migration (v1→v2), and code-generated data classes via `build_runner`. In-memory caching in `GtfsRepositoryImpl` for all-stops, all-routes, and active service IDs (auto-refreshes per service date). SQL injection prevention in LIKE queries. Empty primary key validation in CSV import pipeline.

## Data Sources

All feeds are publicly available from Roma Mobilita (no authentication required):

| Feed | URL | Format | Refresh |
|------|-----|--------|---------|
| Static GTFS | `https://romamobilita.it/sites/default/files/rome_static_gtfs.zip` | ZIP (~45 MB) | Daily |
| RT Trip Updates | `https://romamobilita.it/sites/default/files/rome_rtgtfs_trip_updates_feed.pb` | Protobuf | ~60 s |
| RT Vehicle Positions | `https://romamobilita.it/sites/default/files/rome_rtgtfs_vehicle_positions_feed.pb` | Protobuf | ~60 s |
| RT Service Alerts | `https://romamobilita.it/sites/default/files/rome_rtgtfs_service_alerts_feed.pb` | Protobuf | ~60 s |

## Project Structure

```
lib/
  main.dart                          # WidgetsFlutterBinding + ProviderScope
  app.dart                           # MaterialApp.router (ConsumerWidget)
  l10n/                              # ARB localization files (EN + IT)
    app_en.arb
    app_it.arb
  core/
    constants/
      api_constants.dart             # GTFS URLs, refresh intervals
      app_constants.dart             # App name, batch size, Rome coords, prefs keys
    error/
      exceptions.dart                # ServerException, CacheException, ParseException, SyncException
      failures.dart                  # Failure hierarchy (Server, Cache, Parse, Sync, Location)
    theme/
      app_theme.dart                 # ThemeData builder (light + dark, Material 3)
      color_schemes.dart             # Explicit ColorScheme: dark red #8B0000 / gold #DAA520
      text_theme.dart                # Default Material 3 TextTheme
    utils/
      date_time_utils.dart           # GTFS time parsing (25:30:00 handling), service date logic
      gtfs_csv_parser.dart           # CSV-to-Map<String,String> parser (normalized EOL, quoted fields)
      distance_utils.dart            # Haversine distance calculation
    router/
      app_router.dart                # GoRouter config + ScaffoldWithNavBar (NavigationBar shell)
  data/
    datasources/
      local/
        database/
          app_database.dart          # Drift database: 8 tables, indexes, batch inserts, queries
          app_database.g.dart        # Generated (build_runner)
        gtfs_file_storage.dart       # HTTP download + ZIP extraction to local filesystem
        preferences_storage.dart     # SharedPreferences wrapper (last sync date, theme mode)
      remote/
        gtfs_static_api.dart         # Streamed HTTP download of GTFS ZIP
        gtfs_realtime_api.dart       # HTTP GET for 3 protobuf feeds
    models/
      gtfs/                          # Data models with fromCsvRow factories:
        agency_model.dart            #   agency_id, agency_name, agency_url, agency_timezone
        stop_model.dart              #   stop_id, stop_name, stop_lat, stop_lon, ...
        route_model.dart             #   route_id, route_short_name, route_type, route_color, ...
        trip_model.dart              #   trip_id, route_id, service_id, trip_headsign, shape_id
        stop_time_model.dart         #   trip_id, arrival_time, departure_time, stop_sequence
        calendar_model.dart          #   service_id, monday..sunday, start_date, end_date
        calendar_date_model.dart     #   service_id, date, exception_type
        shape_model.dart             #   shape_id, shape_pt_lat, shape_pt_lon, shape_pt_sequence
      realtime/                      # RT data models:
        trip_update_model.dart       #   tripId, routeId, delay (seconds)
        vehicle_position_model.dart  #   vehicleId, tripId, lat, lon, bearing, speed
        service_alert_model.dart     #   headerText, descriptionText, routeIds, stopIds
    repositories/
      sync_repository_impl.dart      # Stream<SyncProgress>: download -> extract -> batch import
      gtfs_repository_impl.dart      # GtfsRepository impl: search, departures, calendar logic
      realtime_repository_impl.dart  # RealtimeRepository impl: protobuf parsing via FeedMessage
  domain/
    entities/                        # Immutable domain objects:
      stop.dart                      #   Stop (stopId, stopName, stopLat, stopLon, ...)
      route_entity.dart              #   RouteEntity (routeId, routeShortName, routeType + isBus/isTram/isMetro)
      departure.dart                 #   Departure (scheduled + RT times, effectiveSeconds getter)
      vehicle.dart                   #   Vehicle (tripId, lat, lon, bearing, speed)
      service_alert.dart             #   ServiceAlert (headerText, descriptionText, routeIds, stopIds)
      favorite_stop.dart             #   FavoriteStop (stopId, addedAt)
    repositories/                    # Abstract interfaces:
      gtfs_repository.dart           #   searchStops, getScheduledDepartures, favorites, routes
      realtime_repository.dart       #   getTripDelays, getVehiclePositions, getServiceAlerts
    usecases/
      search_stops.dart              # Trim + delegate to repo; empty on blank query
      get_stop_departures.dart       # CORE: schedule filter + RT delay merge + sort by effectiveSeconds
      get_route_details.dart         # Route metadata + ordered stop list
      get_routes_for_stop.dart       # All routes serving a stop
      toggle_favorite.dart           # Check -> flip -> return new state
      sync_gtfs_data.dart            # Wraps SyncRepositoryImpl stream
  presentation/
    providers/
      sync_provider.dart             # databaseProvider, preferencesStorageProvider, syncRepositoryProvider, hasCompletedSyncProvider
      gtfs_providers.dart            # gtfsRepositoryProvider, realtimeRepositoryProvider, connectivityProvider, isOnlineProvider, searchResultsProvider, stopDeparturesProvider, favoriteStopIdsProvider, ...
      theme_provider.dart            # themeModeProvider (StateNotifier), lastSyncDateProvider, persists theme to SharedPreferences
    screens/
      home/home_screen.dart          # Search bar (live results), favorites with live departure countdown + LIVE badges
      stop_detail/stop_detail_screen.dart  # Departure list, RT auto-refresh (30s), offline banner, favorite toggle, pull-to-refresh
      route_browser/route_browser_screen.dart  # Tabbed route list (All/Bus/Tram/Metro), LineBadge, tap to route detail
      route_detail/route_detail_screen.dart  # Route info + ordered stop list with timeline indicator, tap to stop detail
      map/map_screen.dart            # flutter_map + OSM tiles, stop markers, live vehicle positions, user GPS location, bottom sheet stop info
      alerts/alerts_screen.dart      # Service alert cards with route/stop chips, offline banner, pull-to-refresh
      settings/settings_screen.dart  # Theme toggle (system/light/dark), re-sync with confirmation, last sync date, about
      sync/sync_screen.dart          # Multi-stage progress bar, friendly error messages, retry
    widgets/
      line_badge.dart                # Colored route badge (parses GTFS hex color)
      departure_tile.dart            # ListTile with LineBadge, headsign, schedule, LIVE badge, countdown
```

### Test Structure

```
test/
  widget_test.dart                     # Theme, DateTimeUtils, DistanceUtils, GtfsCsvParser
  unit/
    phase2_test.dart                   # GTFS model fromCsvRow factories
    phase3_test.dart                   # SearchStops, ToggleFavorite, Departure, RouteEntity
    phase4_test.dart                   # RT models, GetStopDepartures RT merge + fallback
    phase5_test.dart                   # Route type filtering, GetRouteDetails, GetRoutesForStop
    phase6_test.dart                   # Map coordinates, Vehicle filtering, distance calcs
    phase7_test.dart                   # ServiceAlert, ThemeMode, AppConstants, alert filtering
    departure_comprehensive_test.dart  # 78 edge-case tests for GTFS time + departures
  integration/
    database_integration_test.dart     # 90 real-DB tests (in-memory SQLite, no mocks)
```

## Database Schema

8 Drift tables with composite primary keys where appropriate:

| Table | PK | Rows (Rome) | Key Indexes |
|-------|-----|-------------|-------------|
| `gtfs_stops` | `stop_id` | ~12,000 | `stop_name COLLATE NOCASE` |
| `gtfs_routes` | `route_id` | ~400 | - |
| `gtfs_trips` | `trip_id` | ~50,000 | `route_id`, `service_id` |
| `gtfs_stop_times` | `(trip_id, stop_sequence)` | ~1,200,000 | `stop_id`, `(stop_id, departure_time)`, `trip_id` |
| `gtfs_calendar` | `service_id` | ~50 | - |
| `gtfs_calendar_dates` | `(service_id, date)` | ~3,000 | `date`, `service_id` |
| `gtfs_shapes` | `(shape_id, shape_pt_sequence)` | ~800,000 | `shape_id` |
| `favorite_stops` | `stop_id` | user data | - |

Import uses batch inserts of 5000 rows per transaction to handle the 1M+ `stop_times` rows without exhausting memory.

## GTFS Time Handling

GTFS uses `HH:MM:SS` where HH can exceed 24 (e.g., `25:30:00` = 1:30 AM the next calendar day). The "service day" starts around 04:00 and extends past midnight.

All time comparisons go through `DateTimeUtils`:
- `parseGtfsTime("25:30:00")` -> `91800` (total seconds)
- `formatTime(91800)` -> `"01:30"` (normalized for display)
- `getServiceDate()` -> returns yesterday if current time is before 04:00

## Service Calendar Logic

```
isActive(serviceId, date) =
  (calendar[weekday] == true AND startDate <= date <= endDate
   AND NOT calendar_dates has exception_type=2)
  OR calendar_dates has exception_type=1
```

## Departure Merge Algorithm (Core)

1. Determine today's GTFS service date (before 04:00 = yesterday)
2. Resolve active service IDs from `calendar` + `calendar_dates` exceptions
3. Query all `stop_times` for the stop, filter to active services
4. Look up route metadata (short name, color) via trip -> route join
5. Filter to upcoming window (next 90 minutes)
6. Fetch RT trip delays from protobuf feed (graceful fallback if offline)
7. Overlay delays: `estimatedSeconds = scheduledSeconds + delay`
8. Sort by `effectiveSeconds` (prefers RT estimate, falls back to scheduled)

## Real-Time Data Flow

```
GTFS-RT Protobuf Feed (HTTP, ~60s refresh)
    │
    ▼
GtfsRealtimeApi._fetchFeed() → Uint8List
    │
    ▼
FeedMessage.fromBuffer(bytes) → parsed protobuf
    │
    ▼
RealtimeRepositoryImpl
    ├── getTripDelays() → Map<String, int> (tripId → delay seconds)
    ├── getVehiclePositions() → List<Vehicle>
    └── getServiceAlerts() → List<ServiceAlert>
    │
    ▼
GetStopDepartures use case (RT merge)
    ├── Online: scheduled + RT delays → sorted by effectiveSeconds
    └── Offline: scheduled only (graceful fallback)
    │
    ▼
StopDetailScreen (30s auto-refresh via Timer.periodic)
    ├── DepartureTile: LIVE badge (green/orange/red), delay ±Xm
    └── Offline banner: "Offline – showing scheduled times"
```

`isOnlineProvider` (via `connectivity_plus`) reactively switches `GetStopDepartures` between RT-enabled and scheduled-only modes.

## Theme

Material 3 with an explicit `ColorScheme` constructor (not `fromSeed`):

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#8B0000` (dark red) | `#FFB4AA` (soft salmon) |
| Primary Container | `#FFDAD5` | `#8B0000` |
| Secondary | `#DAA520` (gold) | `#FFD700` (bright gold) |
| Surface | `#FFFBFF` (warm ivory) | `#201A19` (warm charcoal) |
| Error | `#BA1A1A` | `#FFB4AB` |

`NavigationBar` indicator uses the secondary (gold) color. Cards have 12px border radius.

## Localization

Bilingual (EN + IT) via `flutter_localizations` + ARB files. System language detection with fallback to English. 60+ localized strings covering all UI text, parameterized messages (`lastSync`, `syncImportingTable`, `stopCode`, etc.).

## Dependencies

### Runtime
| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management (Provider, FutureProvider, StreamProvider) |
| `go_router` | Declarative routing with ShellRoute |
| `drift` + `sqlite3_flutter_libs` | SQLite database with type-safe queries |
| `http` | GTFS ZIP download and RT feed fetching |
| `gtfs_realtime_bindings` + `protobuf` | GTFS-RT protobuf deserialization |
| `archive` | ZIP extraction |
| `csv` | CSV parsing with quoted field support |
| `connectivity_plus` | Online/offline detection |
| `flutter_map` + `latlong2` + `flutter_map_marker_cluster` | OpenStreetMap widget |
| `geolocator` | GPS for nearby stops |
| `path_provider` + `shared_preferences` | Local file/preference storage |
| `intl` | Date formatting + l10n |

### Dev
| Package | Purpose |
|---------|---------|
| `build_runner` + `drift_dev` | Drift code generation |
| `drift` (native) + `sqlite3` | In-memory SQLite for integration tests |
| `mocktail` | Test mocking |
| `flutter_lints` | Static analysis |

## Building

### Prerequisites
- Flutter 3.16.3+
- Java 17 (for Android Gradle Plugin 8.1)
- Android SDK 35

### Commands
```bash
# Install dependencies
flutter pub get

# Generate Drift database code
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Build release APK (set JAVA_HOME if needed)
JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-17.0.8.7-hotspot" flutter build apk --release
```

The release APK is output to `build/app/outputs/flutter-apk/app-release.apk`.

### Android Configuration
- `compileSdkVersion 35`, `minSdkVersion 21`
- AGP 8.1.0, Gradle 8.3, Kotlin 1.8.22
- Permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- `android:usesCleartextTraffic="true"` (Roma Mobilita serves some assets over HTTP)

## Testing

339 tests across nine test files (249 unit + 90 integration):

| File | Tests | Coverage |
|------|-------|----------|
| `test/widget_test.dart` | 25 | ColorScheme values, ThemeData, DateTimeUtils, DistanceUtils (Haversine), GtfsCsvParser |
| `test/unit/phase2_test.dart` | 17 | All GTFS model `fromCsvRow` factories, CSV-to-model integration |
| `test/unit/phase3_test.dart` | 13 | SearchStops use case, ToggleFavorite use case, Departure entity, RouteEntity type flags |
| `test/unit/phase4_test.dart` | 20 | RT models, Vehicle/ServiceAlert entities, GetStopDepartures RT merge + fallback + sorting + 90-min window, MockRealtimeRepository |
| `test/unit/phase5_test.dart` | 13 | Route type filtering (Bus/Tram/Metro), GetRouteDetails use case, GetRoutesForStop use case, RouteEntity properties, Stop entity |
| `test/unit/phase6_test.dart` | 10 | Stop coordinates, Vehicle map filtering, nearby stops distance calculation, bearing-to-radians conversion |
| `test/unit/departure_comprehensive_test.dart` | 78 | GTFS time edge cases, service date logic, Departure entity, DepartureRow mapping, GetStopDepartures (time window, RT merge, sorting, edge cases), calendar service ID resolution, after-midnight fix verification |
| `test/unit/phase7_test.dart` | 20 | ServiceAlert entity, ThemeMode persistence logic, AppConstants, vehicle display/filtering, alert filtering by route/stop/time period |
| `test/integration/database_integration_test.dart` | 90 | **Real in-memory SQLite** (no mocks): Stop/Route/Trip/StopTime/Calendar/Favorite CRUD, JOIN queries, `GtfsRepositoryImpl` integration (search, caching, calendar resolution with exceptions), `GetStopDepartures` use case with real DB + RT mock merge, `GtfsCsvParser` edge cases (BOM, quotes, CRLF, escaped quotes), full E2E pipeline (CSV → parse → DB → repository → use case), `DateTimeUtils` comprehensive edge tests, `Departure` entity + `DepartureRow` mapping resilience |

Testing strategy: unit tests use hand-rolled mock repositories implementing abstract interfaces. Integration tests use real in-memory SQLite databases via `NativeDatabase.memory()` to validate the full stack without mocks.

## Releases

| Version | Tag | Description |
|---------|-----|-------------|
| v0.0.1 | `v0.0.1` | Scaffold + Theme: project setup, Material 3 Roman palette, GoRouter, l10n, placeholder screens |
| v0.0.2 | `v0.0.2` | GTFS Data Layer: Drift DB (8 tables), CSV parser, ZIP download, batch import, sync screen |
| v0.0.3 | `v0.0.3` | Stop Search + Timetable: domain layer, search, scheduled departures, home + stop detail screens |
| v0.0.4 | `v0.0.4` | Real-Time Integration: GTFS-RT protobuf parsing, delay overlay on departures, 30s auto-refresh, connectivity detection, offline banner |
| v0.0.5 | `v0.0.5` | Route Browser + Favorites: tabbed route list (Bus/Tram/Metro), route detail with timeline stop list, reactive favorites with live departure countdown |
| v0.0.6 | `v0.0.6` | Map View + Departure Fix + Caching: flutter_map + OSM tiles, stop markers with bottom sheet, live vehicle positions (30s refresh), user GPS location, bearing rotation; fixed departure times (JOIN query, calendar fallback, after-midnight fix); in-memory caching for stops/routes/service IDs; 78 new comprehensive tests |
| v0.0.7 | `v0.0.7` | Alerts + Polish: service alert cards with route/stop chips, settings screen with theme toggle (light/dark/system), re-sync with confirmation dialog, last sync date display, about section, persistent theme mode via SharedPreferences |
| v0.0.8 | `v0.0.8` | BOM fix + CSV parser hardening: fixed UTF-8 BOM stripping in GtfsCsvParser causing header mismatch during GTFS import |
| v0.0.9 | `v0.0.9` | Database hardening + real integration tests: schema migration (v1→v2), composite `(stop_id, departure_time)` index, N+1 query elimination in `getStopsForRoute` (single JOIN), SQL injection prevention in LIKE queries, empty PK validation in all 7 CSV parsers, cache invalidation after sync, 90 real-DB integration tests using in-memory SQLite |

## Roadmap

- **v0.1.0** - MVP: full test suite, QA pass, first stable release

## License

Personal project. Not licensed for redistribution.
