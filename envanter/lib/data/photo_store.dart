import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Fotograf ve belgeleri uygulamanin belge klasorunde saklar.
///
/// Veritabaninda mutlak yol degil, bu klasore gore *goreli* yol tutulur:
/// iOS her guncellemede uygulama klasorunun mutlak yolunu degistirir,
/// mutlak yol saklarsak butun fotograflar kaybolur.
class PhotoStore {
  PhotoStore(this._root);

  final Directory _root;

  static const String _folder = 'media';

  static Future<PhotoStore> create() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _folder));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return PhotoStore(dir);
  }

  /// Verilen dosyayi kalici klasore kopyalar ve goreli yolunu doner.
  Future<String> save(File source) async {
    const uuid = Uuid();
    final extension = p.extension(source.path).toLowerCase();
    final name = '${uuid.v4()}${extension.isEmpty ? '.jpg' : extension}';
    await source.copy(p.join(_root.path, name));
    return name;
  }

  /// Goreli yoldan okunabilir dosyayi doner. Dosya yoksa `null`.
  File? resolve(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    final file = File(p.join(_root.path, relativePath));
    return file.existsSync() ? file : null;
  }

  Future<void> delete(String? relativePath) async {
    final file = resolve(relativePath);
    if (file != null) await file.delete();
  }
}
