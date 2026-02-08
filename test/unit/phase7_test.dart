import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/domain/entities/service_alert.dart';
import 'package:atacbus_roma/domain/entities/vehicle.dart';
import 'package:atacbus_roma/core/constants/app_constants.dart';

void main() {
  group('ServiceAlert entity', () {
    test('alert with all fields', () {
      const alert = ServiceAlert(
        alertId: 'alert_1',
        headerText: 'Sciopero linea 64',
        descriptionText: 'Route 64 suspended due to strike action.',
        url: 'https://romamobilita.it/alerts/1',
        routeIds: ['64', '40', '170'],
        stopIds: ['stop_A', 'stop_B'],
        activePeriodStart: 1700000000,
        activePeriodEnd: 1700100000,
      );
      expect(alert.alertId, 'alert_1');
      expect(alert.headerText, 'Sciopero linea 64');
      expect(alert.descriptionText, contains('strike'));
      expect(alert.url, isNotNull);
      expect(alert.routeIds.length, 3);
      expect(alert.stopIds.length, 2);
      expect(alert.activePeriodStart, 1700000000);
      expect(alert.activePeriodEnd, 1700100000);
    });

    test('alert with no routes or stops', () {
      const alert = ServiceAlert(
        alertId: 'alert_2',
        headerText: 'General Notice',
      );
      expect(alert.routeIds, isEmpty);
      expect(alert.stopIds, isEmpty);
      expect(alert.descriptionText, isNull);
      expect(alert.url, isNull);
    });

    test('alert with only routes', () {
      const alert = ServiceAlert(
        headerText: 'Route disruption',
        routeIds: ['64'],
      );
      expect(alert.routeIds, ['64']);
      expect(alert.stopIds, isEmpty);
    });

    test('empty alert has sensible defaults', () {
      const alert = ServiceAlert();
      expect(alert.alertId, isNull);
      expect(alert.headerText, isNull);
      expect(alert.descriptionText, isNull);
      expect(alert.url, isNull);
      expect(alert.routeIds, isEmpty);
      expect(alert.stopIds, isEmpty);
      expect(alert.activePeriodStart, isNull);
      expect(alert.activePeriodEnd, isNull);
    });

    test('alert with many affected routes', () {
      final routeIds = List.generate(20, (i) => 'route_$i');
      final alert = ServiceAlert(
        headerText: 'Major disruption',
        routeIds: routeIds,
      );
      expect(alert.routeIds.length, 20);
    });

    test('alert with many affected stops (UI shows max 5 + overflow)', () {
      final stopIds = List.generate(10, (i) => 'stop_$i');
      final alert = ServiceAlert(
        headerText: 'Stop closure',
        stopIds: stopIds,
      );
      // Simulating the take(5) logic from _AlertCard
      final displayed = alert.stopIds.take(5).toList();
      final overflow = alert.stopIds.length - 5;
      expect(displayed.length, 5);
      expect(overflow, 5);
    });
  });

  group('ThemeMode persistence', () {
    test('ThemeMode enum has expected values', () {
      expect(ThemeMode.values.length, 3);
      expect(ThemeMode.system.index, 0);
      expect(ThemeMode.light.index, 1);
      expect(ThemeMode.dark.index, 2);
    });

    test('ThemeMode string conversion roundtrip', () {
      // Test the logic used in ThemeModeNotifier
      String themeModeToString(ThemeMode mode) {
        switch (mode) {
          case ThemeMode.light:
            return 'light';
          case ThemeMode.dark:
            return 'dark';
          case ThemeMode.system:
            return 'system';
        }
      }

      ThemeMode stringToThemeMode(String s) {
        switch (s) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          default:
            return ThemeMode.system;
        }
      }

      for (final mode in ThemeMode.values) {
        final str = themeModeToString(mode);
        final parsed = stringToThemeMode(str);
        expect(parsed, mode);
      }
    });

    test('unknown string defaults to system', () {
      ThemeMode stringToThemeMode(String s) {
        switch (s) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          default:
            return ThemeMode.system;
        }
      }

      expect(stringToThemeMode('invalid'), ThemeMode.system);
      expect(stringToThemeMode(''), ThemeMode.system);
      expect(stringToThemeMode('auto'), ThemeMode.system);
    });
  });

  group('AppConstants', () {
    test('app version is set', () {
      expect(AppConstants.appVersion, isNotEmpty);
      expect(AppConstants.appVersion, contains('.'));
    });

    test('app name matches', () {
      expect(AppConstants.appName, 'BUS - Roma');
    });

    test('default coordinates are in Rome', () {
      expect(AppConstants.defaultLatitude, closeTo(41.9, 0.1));
      expect(AppConstants.defaultLongitude, closeTo(12.5, 0.1));
    });

    test('preferences keys are non-empty', () {
      expect(AppConstants.prefsKeyLastSync, isNotEmpty);
      expect(AppConstants.prefsKeyThemeMode, isNotEmpty);
    });

    test('batch size is reasonable', () {
      expect(AppConstants.dbBatchSize, greaterThan(100));
      expect(AppConstants.dbBatchSize, lessThanOrEqualTo(10000));
    });
  });

  group('Vehicle display logic', () {
    test('vehicles with position are shown on map', () {
      final vehicles = [
        const Vehicle(tripId: 't1', latitude: 41.9, longitude: 12.5),
        const Vehicle(tripId: 't2'), // no position
        const Vehicle(tripId: 't3', latitude: 41.8, longitude: 12.4),
        const Vehicle(tripId: 't4', latitude: null, longitude: 12.3), // partial
      ];

      final onMap = vehicles
          .where((v) => v.latitude != null && v.longitude != null)
          .toList();
      expect(onMap.length, 2);
      expect(onMap[0].tripId, 't1');
      expect(onMap[1].tripId, 't3');
    });

    test('vehicle speed is optional', () {
      const v = Vehicle(
        tripId: 't1',
        latitude: 41.9,
        longitude: 12.5,
        speed: 45.0,
      );
      expect(v.speed, 45.0);

      const v2 = Vehicle(tripId: 't2', latitude: 41.9, longitude: 12.5);
      expect(v2.speed, isNull);
    });

    test('vehicle timestamp is optional', () {
      const v = Vehicle(tripId: 't1', timestamp: 1700000000);
      expect(v.timestamp, 1700000000);

      const v2 = Vehicle(tripId: 't2');
      expect(v2.timestamp, isNull);
    });
  });

  group('Alert filtering logic', () {
    test('filter alerts by route ID', () {
      final alerts = [
        const ServiceAlert(
          alertId: 'a1',
          headerText: 'Route 64 disruption',
          routeIds: ['64'],
        ),
        const ServiceAlert(
          alertId: 'a2',
          headerText: 'Metro A closure',
          routeIds: ['MA'],
        ),
        const ServiceAlert(
          alertId: 'a3',
          headerText: 'General notice',
          routeIds: [],
        ),
      ];

      final route64Alerts =
          alerts.where((a) => a.routeIds.contains('64')).toList();
      expect(route64Alerts.length, 1);
      expect(route64Alerts[0].alertId, 'a1');
    });

    test('filter alerts by stop ID', () {
      final alerts = [
        const ServiceAlert(
          alertId: 'a1',
          headerText: 'Stop closed',
          stopIds: ['stop_termini'],
        ),
        const ServiceAlert(
          alertId: 'a2',
          headerText: 'Stop moved',
          stopIds: ['stop_colosseo', 'stop_termini'],
        ),
      ];

      final terminiAlerts =
          alerts.where((a) => a.stopIds.contains('stop_termini')).toList();
      expect(terminiAlerts.length, 2);
    });

    test('filter active alerts by time period', () {
      const now = 1700050000; // some timestamp

      final alerts = [
        const ServiceAlert(
          alertId: 'active',
          headerText: 'Active alert',
          activePeriodStart: 1700000000,
          activePeriodEnd: 1700100000,
        ),
        const ServiceAlert(
          alertId: 'expired',
          headerText: 'Expired alert',
          activePeriodStart: 1699900000,
          activePeriodEnd: 1699990000,
        ),
        const ServiceAlert(
          alertId: 'no_period',
          headerText: 'No period specified',
        ),
      ];

      final active = alerts.where((a) {
        if (a.activePeriodStart == null || a.activePeriodEnd == null) {
          return true; // no period means always active
        }
        return now >= a.activePeriodStart! && now <= a.activePeriodEnd!;
      }).toList();

      expect(active.length, 2);
      expect(
          active.map((a) => a.alertId), containsAll(['active', 'no_period']));
    });
  });
}
