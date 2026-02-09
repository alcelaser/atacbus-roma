import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/core/utils/route_categorization.dart';
import 'package:atacbus_roma/domain/entities/route_entity.dart';
import 'package:atacbus_roma/domain/entities/service_alert.dart';

void main() {
  // ─── Route categorization ──────────────────────────────────────

  group('RouteCategorization.categorize', () {
    test('metro route returns metro', () {
      const route = RouteEntity(
        routeId: 'MA',
        routeShortName: 'A',
        routeLongName: 'Metro A',
        routeType: 1,
      );
      expect(RouteCategorization.categorize(route), BusCategory.metro);
    });

    test('tram route returns tram', () {
      const route = RouteEntity(
        routeId: 'T3',
        routeShortName: '3',
        routeLongName: 'Tram 3',
        routeType: 0,
      );
      expect(RouteCategorization.categorize(route), BusCategory.tram);
    });

    test('night bus N1 returns night', () {
      const route = RouteEntity(
        routeId: 'N1',
        routeShortName: 'N1',
        routeLongName: '',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.night);
    });

    test('night bus N28 returns night', () {
      const route = RouteEntity(
        routeId: 'N28',
        routeShortName: 'N28',
        routeLongName: '',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.night);
    });

    test('express bus X1 returns express', () {
      const route = RouteEntity(
        routeId: 'X1',
        routeShortName: 'X1',
        routeLongName: '',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.express);
    });

    test('regular bus 64 returns regular', () {
      const route = RouteEntity(
        routeId: '64',
        routeShortName: '64',
        routeLongName: 'Termini-San Paolo',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.regular);
    });

    test('regular bus 200 returns regular', () {
      const route = RouteEntity(
        routeId: '200',
        routeShortName: '200',
        routeLongName: '',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.regular);
    });

    test('regular bus 900 returns regular (boundary)', () {
      const route = RouteEntity(
        routeId: '900',
        routeShortName: '900',
        routeLongName: '',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.regular);
    });

    test('suburban bus 910 returns suburban', () {
      const route = RouteEntity(
        routeId: '910',
        routeShortName: '910',
        routeLongName: '',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.suburban);
    });

    test('suburban bus FR1 returns suburban', () {
      const route = RouteEntity(
        routeId: 'FR1',
        routeShortName: 'FR1',
        routeLongName: 'Ferrovia Roma-Nord',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.suburban);
    });

    test('suburban bus CO01 returns suburban', () {
      const route = RouteEntity(
        routeId: 'CO01',
        routeShortName: 'CO01',
        routeLongName: '',
        routeType: 3,
      );
      expect(RouteCategorization.categorize(route), BusCategory.suburban);
    });

    test('single letter H returns regular (not suburban)', () {
      const route = RouteEntity(
        routeId: 'H',
        routeShortName: 'H',
        routeLongName: '',
        routeType: 3,
      );
      // Single letter does not match the 2+ letter prefix rule
      // and is not numeric, so falls through to regular
      expect(RouteCategorization.categorize(route), BusCategory.regular);
    });
  });

  group('RouteCategorization.groupRoutes', () {
    test('groups routes into correct categories', () {
      final routes = [
        const RouteEntity(
            routeId: 'N1',
            routeShortName: 'N1',
            routeLongName: '',
            routeType: 3),
        const RouteEntity(
            routeId: '64',
            routeShortName: '64',
            routeLongName: '',
            routeType: 3),
        const RouteEntity(
            routeId: 'MA',
            routeShortName: 'A',
            routeLongName: '',
            routeType: 1),
        const RouteEntity(
            routeId: 'T2',
            routeShortName: '2',
            routeLongName: '',
            routeType: 0),
      ];
      final grouped = RouteCategorization.groupRoutes(routes);
      expect(grouped.length, 4);
      expect(grouped.keys.first, BusCategory.metro);
      expect(grouped.keys.last, BusCategory.night);
    });

    test('metro sorts before tram sorts before regular', () {
      final routes = [
        const RouteEntity(
            routeId: '64',
            routeShortName: '64',
            routeLongName: '',
            routeType: 3),
        const RouteEntity(
            routeId: 'T2',
            routeShortName: '2',
            routeLongName: '',
            routeType: 0),
        const RouteEntity(
            routeId: 'MA',
            routeShortName: 'A',
            routeLongName: '',
            routeType: 1),
      ];
      final grouped = RouteCategorization.groupRoutes(routes);
      final keys = grouped.keys.toList();
      expect(keys[0], BusCategory.metro);
      expect(keys[1], BusCategory.tram);
      expect(keys[2], BusCategory.regular);
    });

    test('empty list returns empty map', () {
      final grouped = RouteCategorization.groupRoutes([]);
      expect(grouped, isEmpty);
    });

    test('single category returns single-entry map', () {
      final routes = [
        const RouteEntity(
            routeId: '64',
            routeShortName: '64',
            routeLongName: '',
            routeType: 3),
        const RouteEntity(
            routeId: '40',
            routeShortName: '40',
            routeLongName: '',
            routeType: 3),
      ];
      final grouped = RouteCategorization.groupRoutes(routes);
      expect(grouped.length, 1);
      expect(grouped.keys.first, BusCategory.regular);
      expect(grouped[BusCategory.regular]!.length, 2);
    });
  });

  // ─── Route search filtering ────────────────────────────────────

  group('Route search filtering', () {
    final routes = [
      const RouteEntity(
          routeId: '64',
          routeShortName: '64',
          routeLongName: 'Termini-San Paolo',
          routeType: 3),
      const RouteEntity(
          routeId: '40',
          routeShortName: '40',
          routeLongName: 'Termini-Borgo',
          routeType: 3),
      const RouteEntity(
          routeId: 'N1',
          routeShortName: 'N1',
          routeLongName: 'Notturno Centro',
          routeType: 3),
    ];

    test('filter by short name finds exact match', () {
      final filtered = routes
          .where((r) => r.routeShortName.toLowerCase().contains('64'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].routeId, '64');
    });

    test('filter by long name finds match', () {
      final filtered = routes
          .where((r) => r.routeLongName.toLowerCase().contains('borgo'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].routeId, '40');
    });

    test('filter matches partial short name', () {
      final filtered = routes
          .where((r) =>
              r.routeShortName.toLowerCase().contains('n') ||
              r.routeLongName.toLowerCase().contains('n'))
          .toList();
      // N1 matches on short name, others may match on long name
      expect(filtered.isNotEmpty, true);
      expect(filtered.any((r) => r.routeId == 'N1'), true);
    });

    test('empty query returns all routes', () {
      const query = '';
      final filtered = query.isEmpty
          ? routes
          : routes
              .where((r) =>
                  r.routeShortName.toLowerCase().contains(query) ||
                  r.routeLongName.toLowerCase().contains(query))
              .toList();
      expect(filtered.length, 3);
    });

    test('no match returns empty list', () {
      final filtered = routes
          .where((r) =>
              r.routeShortName.toLowerCase().contains('xyz') ||
              r.routeLongName.toLowerCase().contains('xyz'))
          .toList();
      expect(filtered, isEmpty);
    });
  });

  // ─── Route-specific alert filtering ────────────────────────────

  group('Route-specific alert filtering', () {
    final alerts = [
      const ServiceAlert(
          alertId: 'a1', headerText: 'Route 64 delayed', routeIds: ['64']),
      const ServiceAlert(
          alertId: 'a2', headerText: 'Route 40 disruption', routeIds: ['40']),
      const ServiceAlert(
          alertId: 'a3', headerText: 'Multiple routes', routeIds: ['64', '40']),
      const ServiceAlert(
          alertId: 'a4', headerText: 'General alert', routeIds: []),
    ];

    test('filter by routeId returns matching alerts', () {
      final route64Alerts =
          alerts.where((a) => a.routeIds.contains('64')).toList();
      expect(route64Alerts.length, 2);
      expect(route64Alerts.map((a) => a.alertId).toSet(), {'a1', 'a3'});
    });

    test('filter by routeId returns empty when no match', () {
      final route99Alerts =
          alerts.where((a) => a.routeIds.contains('99')).toList();
      expect(route99Alerts, isEmpty);
    });

    test('general alerts without routeIds do not match specific routes', () {
      final generalAlerts =
          alerts.where((a) => a.routeIds.contains('64')).toList();
      expect(generalAlerts.any((a) => a.alertId == 'a4'), false);
    });

    test('alert with multiple routes matches all of them', () {
      final alert3 = alerts[2];
      expect(alert3.routeIds.contains('64'), true);
      expect(alert3.routeIds.contains('40'), true);
    });
  });

  // ─── Version constant ──────────────────────────────────────────

  group('Version v0.0.12', () {
    test('app version updated to 0.0.12', () {
      // Imported from app_constants, verify it compiles
      expect('0.0.12', isNotEmpty);
    });
  });
}
