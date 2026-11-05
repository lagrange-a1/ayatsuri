import 'dart:typed_data';

/// Web stub: no file system, so background images live in SharedPreferences
/// as base64 (see `AppSettingsController.pickBackground`).
Future<Uint8List?> readBackgroundFile() async => null;

Future<String?> writeBackgroundFile(Uint8List bytes) async => null;

Future<void> deleteBackgroundFile() async {}
