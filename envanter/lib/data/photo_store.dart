import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_store_io.dart'
    if (dart.library.js_interop) 'photo_store_memory.dart' as impl;

/// Fotoğrafların nerede durduğunu soyutlar.
///
/// Cihazda dosya sistemine yazar; test ve web önizlemesinde bellekte tutar.
/// Bu ayrım sayesinde arayüz `dart:io`ya bağlanmaz.
abstract interface class PhotoStore {
  /// Seçilen dosyayı kalıcı hale getirir ve sonradan çözümlenecek anahtarı
  /// (göreli yol) döner.
  Future<String> save(XFile file);

  /// Anahtardan görüntü sağlayıcı üretir. Dosya yoksa `null`.
  ImageProvider? imageProvider(String? key);

  Future<void> delete(String? key);

  static Future<PhotoStore> create() => impl.createPhotoStore();
}
