import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialises SQLite for Windows / Linux / macOS desktop targets.
Future<void> initDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // On Android / iOS the default sqflite factory is already correct.
}
