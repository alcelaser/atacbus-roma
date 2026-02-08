import 'package:csv/csv.dart';

class GtfsCsvParser {
  GtfsCsvParser._();

  /// Parse a GTFS CSV string into a list of maps.
  /// The first row is treated as the header row.
  /// Returns a list of Map<String, String> where each map represents a row.
  static List<Map<String, String>> parse(String csvContent) {
    const converter = CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: true,
      eol: '\n',
    );

    // Normalize line endings to \n
    var normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Strip UTF-8 BOM if present
    if (normalized.isNotEmpty && normalized.codeUnitAt(0) == 0xFEFF) {
      normalized = normalized.substring(1);
    }

    final rows = converter.convert(normalized);
    if (rows.isEmpty) return [];

    // First row is the header
    final headers =
        rows.first.map((e) => e.toString().trim()).toList(growable: false);

    final results = <Map<String, String>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty ||
          (row.length == 1 && row.first.toString().trim().isEmpty)) {
        continue; // Skip empty rows
      }
      final map = <String, String>{};
      for (var j = 0; j < headers.length && j < row.length; j++) {
        map[headers[j]] = row[j].toString().trim();
      }
      results.add(map);
    }

    return results;
  }
}
