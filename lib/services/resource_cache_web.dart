/// Web stub - disk caching not available, memory cache only.

Future<void> initializeDiskCache() async {}

Future<void> writeToDisk(String key, String content) async {}

Future<String?> readFromDisk(String key) async => null;

Future<void> removeFromDisk(String key) async {}

Future<void> clearDiskCache() async {}

Future<void> cleanExpiredDiskCache(int expiryThreshold) async {}
