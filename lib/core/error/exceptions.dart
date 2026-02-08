class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class ParseException implements Exception {
  final String message;

  const ParseException(this.message);

  @override
  String toString() => 'ParseException: $message';
}

class SyncException implements Exception {
  final String message;

  const SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}
