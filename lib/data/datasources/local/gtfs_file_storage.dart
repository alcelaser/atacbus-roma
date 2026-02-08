import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';

class GtfsFileStorage {
  static const String _gtfsDir = 'gtfs';

  Future<String> get _storagePath async {
    final dir = await getApplicationDocumentsDirectory();
    final gtfsDir = Directory(p.join(dir.path, _gtfsDir));
    if (!await gtfsDir.exists()) {
      await gtfsDir.create(recursive: true);
    }
    return gtfsDir.path;
  }

  /// Download, extract GTFS ZIP and return the extraction directory path.
  /// [onProgress] is called with (bytesReceived, totalBytes).
  Future<String> downloadAndExtractGtfs({
    void Function(int received, int total)? onProgress,
  }) async {
    final storagePath = await _storagePath;
    final zipPath = p.join(storagePath, 'rome_static_gtfs.zip');

    // Download ZIP
    final request = http.Request('GET', Uri.parse(ApiConstants.gtfsStaticUrl));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw ServerException(
        'Failed to download GTFS data',
        statusCode: response.statusCode,
      );
    }

    final totalBytes = response.contentLength ?? -1;
    var receivedBytes = 0;
    final chunks = <List<int>>[];

    await for (final chunk in response.stream) {
      chunks.add(chunk);
      receivedBytes += chunk.length;
      onProgress?.call(receivedBytes, totalBytes);
    }

    final bytes = Uint8List(receivedBytes);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    // Write ZIP to disk
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(bytes);

    // Extract
    final extractDir = Directory(p.join(storagePath, 'extracted'));
    if (await extractDir.exists()) {
      await extractDir.delete(recursive: true);
    }
    await extractDir.create(recursive: true);

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filePath = p.join(extractDir.path, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // Clean up ZIP
    await zipFile.delete();

    return extractDir.path;
  }

  /// Read a specific file from the extracted GTFS data.
  Future<String> readGtfsFile(String extractedDir, String filename) async {
    final file = File(p.join(extractedDir, filename));
    if (!await file.exists()) {
      throw CacheException('GTFS file not found: $filename');
    }
    return file.readAsString();
  }

  /// Check if a file exists in the extraction directory.
  Future<bool> gtfsFileExists(String extractedDir, String filename) async {
    return File(p.join(extractedDir, filename)).exists();
  }

  /// Delete extracted GTFS data.
  Future<void> cleanupExtracted() async {
    final storagePath = await _storagePath;
    final extractDir = Directory(p.join(storagePath, 'extracted'));
    if (await extractDir.exists()) {
      await extractDir.delete(recursive: true);
    }
  }
}
