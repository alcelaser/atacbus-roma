import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/core/theme/app_theme.dart';
import 'package:atacbus_roma/core/theme/color_schemes.dart';
import 'package:atacbus_roma/core/utils/date_time_utils.dart';
import 'package:atacbus_roma/core/utils/distance_utils.dart';
import 'package:atacbus_roma/core/utils/gtfs_csv_parser.dart';

void main() {
  group('AppColorSchemes', () {
    test('light color scheme has correct primary color', () {
      final scheme = AppColorSchemes.lightColorScheme();
      expect(scheme.primary, const Color(0xFF8B0000));
      expect(scheme.brightness, Brightness.light);
    });

    test('dark color scheme has correct primary color', () {
      final scheme = AppColorSchemes.darkColorScheme();
      expect(scheme.primary, const Color(0xFFFFB4AA));
      expect(scheme.brightness, Brightness.dark);
    });

    test('light scheme secondary is gold', () {
      final scheme = AppColorSchemes.lightColorScheme();
      expect(scheme.secondary, const Color(0xFFDAA520));
    });

    test('dark scheme secondary is bright gold', () {
      final scheme = AppColorSchemes.darkColorScheme();
      expect(scheme.secondary, const Color(0xFFFFD700));
    });
  });

  group('AppTheme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.lightTheme();
      expect(theme.useMaterial3, true);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.darkTheme();
      expect(theme.useMaterial3, true);
    });

    test('light theme has correct color scheme', () {
      final theme = AppTheme.lightTheme();
      expect(theme.colorScheme.primary, const Color(0xFF8B0000));
    });

    test('dark theme has correct color scheme', () {
      final theme = AppTheme.darkTheme();
      expect(theme.colorScheme.primary, const Color(0xFFFFB4AA));
    });
  });

  group('DateTimeUtils', () {
    test('parses normal GTFS time', () {
      expect(DateTimeUtils.parseGtfsTime('08:30:00'), 30600);
    });

    test('parses GTFS time > 24h', () {
      expect(DateTimeUtils.parseGtfsTime('25:30:00'), 91800);
    });

    test('parses midnight', () {
      expect(DateTimeUtils.parseGtfsTime('00:00:00'), 0);
    });

    test('formats time correctly', () {
      expect(DateTimeUtils.formatTime(30600), '08:30');
    });

    test('formats time > 24h normalizes to day', () {
      expect(DateTimeUtils.formatTime(91800), '01:30');
    });

    test('service date returns yesterday before 4 AM', () {
      final earlyMorning = DateTime(2024, 3, 15, 2, 30);
      final serviceDate = DateTimeUtils.getServiceDate(earlyMorning);
      expect(serviceDate, DateTime(2024, 3, 14));
    });

    test('service date returns today after 4 AM', () {
      final afternoon = DateTime(2024, 3, 15, 14, 0);
      final serviceDate = DateTimeUtils.getServiceDate(afternoon);
      expect(serviceDate, DateTime(2024, 3, 15));
    });

    test('parses GTFS date string', () {
      final date = DateTimeUtils.parseGtfsDate('20240315');
      expect(date, DateTime(2024, 3, 15));
    });

    test('formats DateTime to GTFS date string', () {
      final date = DateTime(2024, 3, 15);
      expect(DateTimeUtils.toGtfsDate(date), '20240315');
    });

    test('weekday names are correct', () {
      expect(DateTimeUtils.weekdayName(1), 'monday');
      expect(DateTimeUtils.weekdayName(7), 'sunday');
    });
  });

  group('DistanceUtils', () {
    test('calculates distance between same point as zero', () {
      final distance = DistanceUtils.haversineDistance(
        41.9028,
        12.4964,
        41.9028,
        12.4964,
      );
      expect(distance, closeTo(0, 0.01));
    });

    test('calculates distance between Rome Termini and Colosseum', () {
      // Approximate coordinates
      final distance = DistanceUtils.haversineDistance(
        41.9010, 12.5016, // Termini
        41.8902, 12.4922, // Colosseum
      );
      // Should be roughly 1.3 km
      expect(distance, greaterThan(1000));
      expect(distance, lessThan(2000));
    });
  });

  group('GtfsCsvParser', () {
    test('parses simple CSV', () {
      const csv = 'name,code,lat\nTermini,1234,41.9\nColosseo,5678,41.89';
      final result = GtfsCsvParser.parse(csv);
      expect(result.length, 2);
      expect(result[0]['name'], 'Termini');
      expect(result[0]['code'], '1234');
      expect(result[1]['name'], 'Colosseo');
    });

    test('handles quoted fields with commas', () {
      const csv = 'name,desc\n"Piazza Venezia, Roma",central';
      final result = GtfsCsvParser.parse(csv);
      expect(result.length, 1);
      expect(result[0]['name'], 'Piazza Venezia, Roma');
    });

    test('handles empty fields', () {
      const csv = 'a,b,c\n1,,3';
      final result = GtfsCsvParser.parse(csv);
      expect(result[0]['b'], '');
    });

    test('handles empty input', () {
      final result = GtfsCsvParser.parse('');
      expect(result, isEmpty);
    });

    test('handles CRLF line endings', () {
      const csv = 'name,code\r\nTermini,1234\r\nColosseo,5678\r\n';
      final result = GtfsCsvParser.parse(csv);
      expect(result.length, 2);
    });
  });
}
