import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/data/models/gtfs/stop_model.dart';
import 'package:atacbus_roma/data/models/gtfs/route_model.dart';
import 'package:atacbus_roma/data/models/gtfs/trip_model.dart';
import 'package:atacbus_roma/data/models/gtfs/stop_time_model.dart';
import 'package:atacbus_roma/data/models/gtfs/calendar_model.dart';
import 'package:atacbus_roma/data/models/gtfs/calendar_date_model.dart';
import 'package:atacbus_roma/data/models/gtfs/agency_model.dart';
import 'package:atacbus_roma/data/models/gtfs/shape_model.dart';
import 'package:atacbus_roma/core/utils/gtfs_csv_parser.dart';

void main() {
  group('StopModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'stop_id': '10001',
        'stop_code': 'TRM',
        'stop_name': 'Termini',
        'stop_desc': 'Main station',
        'stop_lat': '41.9010',
        'stop_lon': '12.5016',
        'location_type': '0',
        'parent_station': '',
      };
      final stop = StopModel.fromCsvRow(row);
      expect(stop.stopId, '10001');
      expect(stop.stopCode, 'TRM');
      expect(stop.stopName, 'Termini');
      expect(stop.stopLat, closeTo(41.901, 0.001));
      expect(stop.stopLon, closeTo(12.5016, 0.001));
      expect(stop.locationType, 0);
    });

    test('fromCsvRow handles missing fields', () {
      final row = <String, String>{
        'stop_id': '10002',
        'stop_name': 'Colosseo',
        'stop_lat': '41.8902',
        'stop_lon': '12.4922',
      };
      final stop = StopModel.fromCsvRow(row);
      expect(stop.stopId, '10002');
      expect(stop.stopCode, isNull);
      expect(stop.stopDesc, isNull);
    });
  });

  group('RouteModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'route_id': 'R64',
        'agency_id': 'ATAC',
        'route_short_name': '64',
        'route_long_name': 'Termini - San Pietro',
        'route_type': '3',
        'route_color': 'FF0000',
        'route_text_color': 'FFFFFF',
      };
      final route = RouteModel.fromCsvRow(row);
      expect(route.routeId, 'R64');
      expect(route.routeShortName, '64');
      expect(route.routeType, 3);
      expect(route.routeColor, 'FF0000');
    });

    test('defaults route type to 3 (bus) on missing', () {
      final row = {
        'route_id': 'RX',
        'route_short_name': 'X',
        'route_long_name': 'Test',
      };
      final route = RouteModel.fromCsvRow(row);
      expect(route.routeType, 3);
    });
  });

  group('TripModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'trip_id': 'T001',
        'route_id': 'R64',
        'service_id': 'S1',
        'trip_headsign': 'San Pietro',
        'direction_id': '0',
        'shape_id': 'SH64_0',
      };
      final trip = TripModel.fromCsvRow(row);
      expect(trip.tripId, 'T001');
      expect(trip.routeId, 'R64');
      expect(trip.serviceId, 'S1');
      expect(trip.tripHeadsign, 'San Pietro');
      expect(trip.directionId, 0);
      expect(trip.shapeId, 'SH64_0');
    });
  });

  group('StopTimeModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'trip_id': 'T001',
        'arrival_time': '08:30:00',
        'departure_time': '08:31:00',
        'stop_id': '10001',
        'stop_sequence': '5',
        'pickup_type': '0',
        'drop_off_type': '0',
      };
      final st = StopTimeModel.fromCsvRow(row);
      expect(st.tripId, 'T001');
      expect(st.arrivalTime, '08:30:00');
      expect(st.departureTime, '08:31:00');
      expect(st.stopSequence, 5);
    });

    test('handles times > 24:00', () {
      final row = {
        'trip_id': 'T999',
        'arrival_time': '25:30:00',
        'departure_time': '25:31:00',
        'stop_id': '10001',
        'stop_sequence': '1',
      };
      final st = StopTimeModel.fromCsvRow(row);
      expect(st.arrivalTime, '25:30:00');
    });
  });

  group('CalendarModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'service_id': 'WD',
        'monday': '1',
        'tuesday': '1',
        'wednesday': '1',
        'thursday': '1',
        'friday': '1',
        'saturday': '0',
        'sunday': '0',
        'start_date': '20240101',
        'end_date': '20241231',
      };
      final cal = CalendarModel.fromCsvRow(row);
      expect(cal.serviceId, 'WD');
      expect(cal.monday, true);
      expect(cal.saturday, false);
      expect(cal.sunday, false);
      expect(cal.startDate, '20240101');
    });

    test('isActiveOnWeekday returns correct values', () {
      final row = {
        'service_id': 'WE',
        'monday': '0',
        'tuesday': '0',
        'wednesday': '0',
        'thursday': '0',
        'friday': '0',
        'saturday': '1',
        'sunday': '1',
        'start_date': '20240101',
        'end_date': '20241231',
      };
      final cal = CalendarModel.fromCsvRow(row);
      expect(cal.isActiveOnWeekday(1), false); // Monday
      expect(cal.isActiveOnWeekday(6), true);  // Saturday
      expect(cal.isActiveOnWeekday(7), true);  // Sunday
    });
  });

  group('CalendarDateModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'service_id': 'WD',
        'date': '20240325',
        'exception_type': '2',
      };
      final cd = CalendarDateModel.fromCsvRow(row);
      expect(cd.serviceId, 'WD');
      expect(cd.date, '20240325');
      expect(cd.exceptionType, 2);
    });

    test('exception_type 1 means added', () {
      final row = {
        'service_id': 'SPECIAL',
        'date': '20240501',
        'exception_type': '1',
      };
      final cd = CalendarDateModel.fromCsvRow(row);
      expect(cd.exceptionType, 1);
    });
  });

  group('AgencyModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'agency_id': 'ATAC',
        'agency_name': 'ATAC S.p.A.',
        'agency_url': 'https://www.atac.roma.it',
        'agency_timezone': 'Europe/Rome',
        'agency_lang': 'it',
        'agency_phone': '06-57003',
      };
      final agency = AgencyModel.fromCsvRow(row);
      expect(agency.agencyId, 'ATAC');
      expect(agency.agencyName, 'ATAC S.p.A.');
      expect(agency.agencyTimezone, 'Europe/Rome');
    });
  });

  group('ShapeModel', () {
    test('fromCsvRow parses correctly', () {
      final row = {
        'shape_id': 'SH64_0',
        'shape_pt_lat': '41.9010',
        'shape_pt_lon': '12.5016',
        'shape_pt_sequence': '1',
      };
      final shape = ShapeModel.fromCsvRow(row);
      expect(shape.shapeId, 'SH64_0');
      expect(shape.shapePtLat, closeTo(41.901, 0.001));
      expect(shape.shapePtSequence, 1);
    });
  });

  group('CSV -> Model integration', () {
    test('parse stops CSV into StopModels', () {
      const csv = 'stop_id,stop_code,stop_name,stop_desc,stop_lat,stop_lon,location_type,parent_station\n'
          '10001,TRM,Termini,,41.9010,12.5016,0,\n'
          '10002,COL,Colosseo,,41.8902,12.4922,0,';
      final rows = GtfsCsvParser.parse(csv);
      final stops = rows.map((r) => StopModel.fromCsvRow(r)).toList();
      expect(stops.length, 2);
      expect(stops[0].stopName, 'Termini');
      expect(stops[1].stopName, 'Colosseo');
    });

    test('parse routes CSV into RouteModels', () {
      const csv = 'route_id,agency_id,route_short_name,route_long_name,route_type,route_color,route_text_color\n'
          'R64,ATAC,64,Termini - San Pietro,3,FF0000,FFFFFF\n'
          'R40,ATAC,40,Termini - Largo Argentina,3,00FF00,000000';
      final rows = GtfsCsvParser.parse(csv);
      final routes = rows.map((r) => RouteModel.fromCsvRow(r)).toList();
      expect(routes.length, 2);
      expect(routes[0].routeShortName, '64');
      expect(routes[1].routeShortName, '40');
    });

    test('parse stop_times CSV with large sequence numbers', () {
      const csv = 'trip_id,arrival_time,departure_time,stop_id,stop_sequence\n'
          'T001,08:30:00,08:31:00,10001,1\n'
          'T001,08:35:00,08:36:00,10002,2\n'
          'T001,25:30:00,25:31:00,10003,100';
      final rows = GtfsCsvParser.parse(csv);
      final times = rows.map((r) => StopTimeModel.fromCsvRow(r)).toList();
      expect(times.length, 3);
      expect(times[2].arrivalTime, '25:30:00');
      expect(times[2].stopSequence, 100);
    });

    test('parse calendar_dates CSV', () {
      const csv = 'service_id,date,exception_type\n'
          'WD,20240325,2\n'
          'SPECIAL,20240501,1';
      final rows = GtfsCsvParser.parse(csv);
      final dates = rows.map((r) => CalendarDateModel.fromCsvRow(r)).toList();
      expect(dates.length, 2);
      expect(dates[0].exceptionType, 2);
      expect(dates[1].exceptionType, 1);
    });
  });
}
