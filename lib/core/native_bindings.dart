// Conditional export: uses native FFI on IO platforms (Android, Windows, iOS, Linux, macOS)
// and pure Dart mathematical implementation on Web (Chrome).
export 'native_bindings_interface.dart';
export 'native_bindings_web.dart'
    if (dart.library.io) 'native_bindings_io.dart';
