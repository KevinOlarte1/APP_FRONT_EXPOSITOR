import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Guarda un archivo en Memory/Download en Android o iOS.
Future<void> downloadBytes(List<int> bytes, String filename) async {
  // Pedir permisos solo en Android
  await Permission.storage.request();

  Directory? dir;

  if (Platform.isAndroid) {
    dir = await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    dir = await getApplicationDocumentsDirectory();
  }

  if (dir == null) return;

  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);

  print("📁 Archivo guardado en: ${file.path}");
}
