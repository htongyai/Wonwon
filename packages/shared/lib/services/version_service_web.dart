import 'dart:html' as html;

String? getStoredVersion() => html.window.localStorage['app_version'];

void storeVersion(String version) {
  html.window.localStorage['app_version'] = version;
}

Future<void> clearAppCache() async {
  final cacheNames = await html.window.caches?.keys();
  if (cacheNames != null) {
    for (final cacheName in cacheNames) {
      await html.window.caches?.delete(cacheName);
    }
  }

  final version = html.window.localStorage['app_version'];
  html.window.localStorage.clear();
  if (version != null) {
    html.window.localStorage['app_version'] = version;
  }

  html.window.sessionStorage.clear();
}

void forceReloadPage() {
  html.window.location.reload();
}
