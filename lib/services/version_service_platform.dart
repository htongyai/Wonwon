/// Platform-aware version helpers: real implementation on web, stubs elsewhere.
export 'version_service_stub.dart'
    if (dart.library.html) 'version_service_web.dart';
