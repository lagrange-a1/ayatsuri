import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Name of the persisted background file inside the app documents directory.
const backgroundFileName = 'background';

/// Reads the persisted background image bytes, or null if none / unreadable.
Future<Uint8List?> readBackgroundFile() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$backgroundFileName');
    if (await file.exists()) return await file.readAsBytes();
  } catch (_) {
    // Fall through to null; the caller treats it as "no background".
  }
  return null;
}

/// Writes [bytes] as the persisted background image and returns its path.
Future<String?> writeBackgroundFile(Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$backgroundFileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}

/// Deletes the persisted background image file, if any.
Future<void> deleteBackgroundFile() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$backgroundFileName');
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Best effort only.
  }
}
