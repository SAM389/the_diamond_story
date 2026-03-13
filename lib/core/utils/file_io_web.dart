// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// On web, saving to the file system is not possible.
/// Returns empty string; callers should use [triggerDownload] instead.
Future<String> saveBackupFile(String path, Uint8List bytes) async {
  triggerDownload(bytes, path.split('/').last);
  return path;
}

/// On web, reading from a path is not supported.
/// Callers should use FilePicker with [withData: true] to get bytes directly.
Future<Uint8List> readBackupFile(String path) async {
  return Uint8List(0);
}

/// Triggers a browser file download with the given [bytes] and [fileName].
void triggerDownload(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
