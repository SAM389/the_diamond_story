// Conditional import: selects web or native DB initializer at compile time.
// dart.library.html is only available on web targets.
export 'db_init_native.dart'
    if (dart.library.html) 'db_init_web.dart';
