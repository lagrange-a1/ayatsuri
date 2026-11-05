import 'dart:io';

// The flutter test tool sets FLUTTER_TEST=true in the process
// environment. bool.fromEnvironment does not see it (it only reads
// --dart-define values), so read it via dart:io on VM platforms.
bool get isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');
