import 'dart:convert';
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
  final http.Client _client;

  GtfsFileStorage({http.Client? client}) : _client = client ?? http.Client();

  Future<String> get _storagePath async {
    final dir = await getApplicationDocumentsDirectory();
    final gtfsDir = Directory(p.join(dir.path, _gtfsDir));
    if (!await gtfsDir.exists()) {
      await gtfsDir.create(recursive: true);
    }
    return gtfsDir.path;
  }

  // ─── Server-side hash ─────────────────────────────────────────

  /// Fetch the MD5 hash from Roma Mobilità's server.
  /// The .md5 file typically contains "hash  filename" or just the hash.
  Future<String?> fetchRemoteMd5() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.gtfsStaticMd5Url),
      );
      if (response.statusCode != 200) return null;
      // MD5 files may have format "hash  filename" or just "hash"
      final body = response.body.trim();
      return body.split(RegExp(r'\s+')).first.trim();
    } catch (_) {
      return null;
    }
  }

  // ─── ZIP management ───────────────────────────────────────────

  /// Path to the persisted GTFS ZIP (kept across syncs for comparison).
  Future<String> get _zipPath async {
    final storagePath = await _storagePath;
    return p.join(storagePath, 'rome_static_gtfs.zip');
  }

  /// Whether a previous GTFS ZIP exists on disk.
  Future<bool> hasExistingZip() async {
    final path = await _zipPath;
    return File(path).exists();
  }

  /// Download the GTFS ZIP to a temporary file.
  /// Returns the temp file path.
  Future<String> downloadGtfsToTemp({
    void Function(int received, int total)? onProgress,
  }) async {
    final storagePath = await _storagePath;
    final tempPath = p.join(storagePath, 'rome_static_gtfs_new.zip');

    final request = http.Request('GET', Uri.parse(ApiConstants.gtfsStaticUrl));
    final response = await _client.send(request);

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

    // Write to temp file
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(bytes);

    return tempPath;
  }

  /// Promote a temp ZIP to the final location after successful import.
  Future<void> promoteZip(String tempPath) async {
    final finalPath = await _zipPath;
    final tempFile = File(tempPath);
    final finalFile = File(finalPath);

    // Delete existing if present
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await tempFile.rename(finalPath);
  }

  /// Delete the temp ZIP if it exists (cleanup on error).
  Future<void> cleanupTempZip() async {
    final storagePath = await _storagePath;
    final tempPath = p.join(storagePath, 'rome_static_gtfs_new.zip');
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  // ─── Extraction ───────────────────────────────────────────────

  /// Extract a ZIP file and return the extraction directory path.
  Future<String> extractZip(String zipPath) async {
    final storagePath = await _storagePath;
    final extractDir = Directory(p.join(storagePath, 'extracted'));
    if (await extractDir.exists()) {
      await extractDir.delete(recursive: true);
    }
    await extractDir.create(recursive: true);

    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filePath = p.join(extractDir.path, file.name);
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    return extractDir.path;
  }

  // ─── Legacy compat: downloadAndExtractGtfs (used by old sync) ──

  /// Download, extract GTFS ZIP and return the extraction directory path.
  /// [onProgress] is called with (bytesReceived, totalBytes).
  /// @deprecated Use downloadGtfsToTemp + extractZip instead.
  Future<String> downloadAndExtractGtfs({
    void Function(int received, int total)? onProgress,
  }) async {
    final tempPath = await downloadGtfsToTemp(onProgress: onProgress);
    final extractDir = await extractZip(tempPath);

    // Clean up temp ZIP (old behavior: don't keep it)
    await File(tempPath).delete();

    return extractDir;
  }

  // ─── File reading ─────────────────────────────────────────────

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

  /// Compute a simple content hash using Dart's built-in hashCode.
  /// For differential sync, we use a fast DJB2-style hash on the content bytes.
  /// This is NOT cryptographically secure but sufficient for change detection.
  static String computeContentHash(String content) {
    // DJB2 hash — fast, good distribution, no external deps
    var hash = 5381;
    final bytes = utf8.encode(content);
    for (final byte in bytes) {
      hash = ((hash << 5) + hash) + byte; // hash * 33 + byte
      hash &= 0x7FFFFFFFFFFFFFFF; // keep in 64-bit range
    }
    return hash.toRadixString(16);
  }
}
