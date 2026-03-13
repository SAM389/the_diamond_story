import 'dart:io';
import 'dart:typed_data';

/// Saves [bytes] to [path] on the native file system.
/// Returns the written file path.
Future<String> saveBackupFile(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes);
  return path;
}

/// Reads bytes from [path] on the native file system.
Future<Uint8List> readBackupFile(String path) async {
  return await File(path).readAsBytes();
}

/// Triggers a file-save prompt on native (no-op stub — caller uses FilePicker
/// getDirectoryPath on desktop).
void triggerDownload(Uint8List bytes, String fileName) {
  // Not used on native; caller writes the file directly.
}
