import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:atacbus_roma/data/datasources/local/database/app_database.dart';

void main() {
  test('sqlite3.dll loads and in-memory database works', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.insertStops([
      GtfsStopsCompanion.insert(
        stopId: 'TEST',
        stopName: 'Test Stop',
        stopLat: 41.9,
        stopLon: 12.5,
      ),
    ]);

    final stops = await db.select(db.gtfsStops).get();
    expect(stops.length, 1);
    expect(stops.first.stopId, 'TEST');

    await db.close();
  });
}
