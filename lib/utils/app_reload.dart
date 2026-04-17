/// Platform-aware reload: reloads the page on web, no-op elsewhere.
/// Default is the stub (no-op); on web (dart:html available) use the real one.
export 'reload_stub.dart' if (dart.library.html) 'reload_web.dart';
