import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'photo_store.dart';

/// Fotoğrafları uygulamanın belge klasöründe saklar.
///
/// Veritabanında mutlak yol değil, bu klasöre göre *göreli* yol tutulur:
/// iOS her güncellemede uygulama klasörünün mutlak yolunu değiştirir, mutlak
/// yol saklarsak bütün fotoğraflar kaybolur.
class IoPhotoStore implements PhotoStore {
  IoPhotoStore(this._root);

  final Directory _root;

  static const String folder = 'media';
  static const Uuid _uuid = Uuid();

  @override
  Future<String> save(XFile file) async {
    final extension = p.extension(file.path).toLowerCase();
    final name = '${_uuid.v4()}${extension.isEmpty ? '.jpg' : extension}';
    await File(file.path).copy(p.join(_root.path, name));
    return name;
  }

  @override
  ImageProvider? imageProvider(String? key) {
    final file = _resolve(key);
    return file == null ? null : FileImage(file);
  }

  @override
  Future<void> delete(String? key) async {
    final file = _resolve(key);
    if (file != null) await file.delete();
  }

  File? _resolve(String? key) {
    if (key == null || key.isEmpty) return null;
    final file = File(p.join(_root.path, key));
    return file.existsSync() ? file : null;
  }
}

Future<PhotoStore> createPhotoStore() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, IoPhotoStore.folder));
  if (!dir.existsSync()) await dir.create(recursive: true);
  return IoPhotoStore(dir);
}
