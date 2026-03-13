// Selects web or native implementation at compile time.
export 'file_io_native.dart'
    if (dart.library.html) 'file_io_web.dart';
