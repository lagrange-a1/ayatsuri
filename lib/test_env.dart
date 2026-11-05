// Web-safe detection of the flutter test environment.
// dart:io (Platform.environment) does not exist on web, so the
// implementation is selected with a conditional import.
export 'test_env_stub.dart' if (dart.library.io) 'test_env_io.dart';
