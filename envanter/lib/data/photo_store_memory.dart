import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'photo_store.dart';

/// Fotoğrafları yalnızca bellekte tutar: testler ve web önizlemesi için.
///
/// Uygulama kapanınca kaybolur; kalıcı depolama [PhotoStore] arayüzünün
/// `dart:io` uygulamasında.
class MemoryPhotoStore implements PhotoStore {
  final Map<String, Uint8List> _bytes = {};

  static const Uuid _uuid = Uuid();

  @override
  Future<String> save(XFile file) async {
    final key = _uuid.v4();
    _bytes[key] = await file.readAsBytes();
    return key;
  }

  @override
  ImageProvider? imageProvider(String? key) {
    if (key == null) return null;
    final bytes = _bytes[key];
    return bytes == null ? null : MemoryImage(bytes);
  }

  @override
  Future<void> delete(String? key) async {
    if (key != null) _bytes.remove(key);
  }
}

Future<PhotoStore> createPhotoStore() async => MemoryPhotoStore();
