import 'dart:io';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

/// Centralized App Directory service for CatatIn.
/// Keeps all internal application data (database, product photos, temp export files)
/// isolated in a dedicated 'CatatIn' subfolder under AppData/Support Directory on Desktop,
/// keeping the user's main Documents folder completely clean and organized!
class AppDirectoryService {
  /// Base directory for CatatIn internal data.
  static Future<Directory> getAppDirectory() async {
    Directory baseDir;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      baseDir = await getApplicationSupportDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final catatinDir = Directory(join(baseDir.path, 'CatatIn'));
    if (!await catatinDir.exists()) {
      await catatinDir.create(recursive: true);
    }
    return catatinDir;
  }

  /// Directory for storing product images.
  static Future<Directory> getProductImagesDirectory() async {
    final appDir = await getAppDirectory();
    final imgDir = Directory(join(appDir.path, 'product_images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    return imgDir;
  }

  /// Directory for temporary report generation files.
  static Future<Directory> getTempExportsDirectory() async {
    final appDir = await getAppDirectory();
    final tempDir = Directory(join(appDir.path, 'temp_exports'));
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }
}
