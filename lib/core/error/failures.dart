abstract class Failure {
  final String message;

  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}
