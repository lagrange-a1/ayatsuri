/*
 * Background-image file storage (native platforms only).
 *
 * On Android (and other file-system platforms) the custom background image
 * is persisted as a real file under the app-private directory
 * (`getApplicationDocumentsDirectory()`, i.e. `/data/data/<package>/files/`
 * on Android) instead of base64-in-SharedPreferences. On Web there is no
 * file system, so the caller falls back to base64 storage.
 */
export 'background_file_stub.dart'
    if (dart.library.io) 'background_file_io.dart';
