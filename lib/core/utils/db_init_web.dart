import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

/// Initialises SQLite for Flutter Web.
/// Loads sqlite3.wasm from web/ then sets the no-web-worker factory.
Future<void> initDatabaseFactory() async {
  // Must load the WASM module before assigning the factory.
  await sqfliteFfiWebLoadSqlite3Wasm(
    SqfliteFfiWebOptions(
      // sqlite3.wasm is served from the web/ root by Flutter's dev server.
      sharedWorkerUri: null,
    ),
  );
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
