import 'dart:typed_data';

/// Stub for web - native image processing not available.
/// On web, raw bytes from ImagePicker are used directly.
Future<Uint8List?> processImageNative(String imagePath) async {
  return null;
}
