import 'dart:io';
import 'package:path_provider/path_provider.dart';

Directory? _cacheDirectory;

Future<void> initializeDiskCache() async {
  _cacheDirectory = await getTemporaryDirectory();
}

Future<void> writeToDisk(String key, String content) async {
  if (_cacheDirectory == null) return;
  final file = File('${_cacheDirectory!.path}/$key');
  await file.writeAsString(content);
}

Future<String?> readFromDisk(String key) async {
  if (_cacheDirectory == null) return null;
  final file = File('${_cacheDirectory!.path}/$key');
  if (await file.exists()) {
    return await file.readAsString();
  }
  return null;
}

Future<void> removeFromDisk(String key) async {
  if (_cacheDirectory == null) return;
  final file = File('${_cacheDirectory!.path}/$key');
  if (await file.exists()) {
    await file.delete();
  }
}

Future<void> clearDiskCache() async {
  if (_cacheDirectory == null) return;
  await _cacheDirectory!.delete(recursive: true);
  await _cacheDirectory!.create();
}

Future<void> cleanExpiredDiskCache(int expiryThreshold) async {
  if (_cacheDirectory == null) return;
  final files = await _cacheDirectory!.list().toList();
  for (var file in files) {
    if (file is File) {
      final stat = await file.stat();
      if (stat.modified.millisecondsSinceEpoch < expiryThreshold) {
        await file.delete();
      }
    }
  }
}
