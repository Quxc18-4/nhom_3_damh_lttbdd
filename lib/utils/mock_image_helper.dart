import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';

class MockImageHelper {
  static Future<XFile> fromAsset(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/mock_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
      return XFile(file.path);
    } catch (e) {
      throw Exception('Cannot load mock image from asset "$assetPath": $e');
    }
  }
}
