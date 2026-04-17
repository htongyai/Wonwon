import 'dart:io';
import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';

/// Native image processing with cropping and multi-stage compression.
Future<Uint8List?> processImageNative(String imagePath) async {
  final Uint8List? preCompressed = await FlutterImageCompress.compressWithFile(
    imagePath,
    minWidth: 800,
    minHeight: 800,
    quality: 85,
    rotate: 0,
  );

  if (preCompressed == null) return null;

  final tempDir = Directory.systemTemp;
  final tempFile = File(
    '${tempDir.path}/temp_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
  await tempFile.writeAsBytes(preCompressed);

  final CroppedFile? cropped = await ImageCropper().cropImage(
    sourcePath: tempFile.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressQuality: 85,
    compressFormat: ImageCompressFormat.jpg,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Profile Image',
        toolbarColor: const Color(0xFFC3C130),
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
        hideBottomControls: false,
      ),
      IOSUiSettings(
        title: 'Crop Profile Image',
        aspectRatioLockEnabled: true,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );

  if (await tempFile.exists()) {
    await tempFile.delete();
  }

  if (cropped == null) return null;

  final Uint8List? finalCompressed =
      await FlutterImageCompress.compressWithFile(
    cropped.path,
    minWidth: 256,
    minHeight: 256,
    quality: 75,
    rotate: 0,
    format: CompressFormat.jpeg,
  );

  if (finalCompressed == null) return null;

  final Uint8List? ultraCompressed =
      await FlutterImageCompress.compressWithList(
    finalCompressed,
    minWidth: 256,
    minHeight: 256,
    quality: 70,
    rotate: 0,
    format: CompressFormat.jpeg,
  );

  return ultraCompressed;
}
