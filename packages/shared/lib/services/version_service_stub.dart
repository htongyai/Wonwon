/// No-op stubs for non-web platforms.
String? getStoredVersion() => null;
void storeVersion(String version) {}
Future<void> clearAppCache() async {}
void forceReloadPage() {}
