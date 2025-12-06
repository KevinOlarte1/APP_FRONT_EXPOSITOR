import 'dart:typed_data';
import 'package:flutter/services.dart';

class FileSaver {
  static const _channel = MethodChannel("com.expositor_app/files");

  static Future<void> saveToDownloads(Uint8List bytes, String filename) async {
    try {
      await _channel.invokeMethod("saveToDownloads", {
        "bytes": bytes,
        "filename": filename,
      });
    } catch (e) {
      print("❌ Error guardando archivo: $e");
    }
  }
}
