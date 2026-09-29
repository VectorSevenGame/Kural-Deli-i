import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../domain/warranty.dart';
import 'models/item.dart';
import 'models/room.dart';
import 'photo_store.dart';
import 'repositories/inventory_data_source.dart';

/// Uygulama genelinde paylaşılan envanter durumu.
class InventoryStore extends ChangeNotifier {
  InventoryStore(this._repository, this.photos);

  final InventoryDataSource _repository;
  final PhotoStore photos;

  static const _uuid = Uuid();

  List<Room> _rooms = const [];
  List<Item> _items = const [];
  bool _loading = true;

  List<Room> get rooms => _rooms;
  List<Item> get items => _items;
  bool get loading => _loading;

  /// Odası silinmiş veya hiç atanmamış eşyalar.
  List<Item> get unassignedItems =>
      _items.where((i) => i.roomId == null).toList();

  List<Item> itemsInRoom(String roomId) =>
      _items.where((i) => i.roomId == roomId).toList();

  Item? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _rooms = await _repository.rooms();
    _items = await _repository.items();
    _loading = false;
    notifyListeners();
  }

  Future<Item> saveItem(Item item) async {
    await _repository.upsertItem(item);
    _items = await _repository.items();
    notifyListeners();
    return item;
  }

  Future<void> deleteItem(String id) async {
    final item = itemById(id);
    await _repository.deleteItem(id);
    if (item?.photoPath != null) {
      await photos.delete(item!.photoPath);
    }
    _items = await _repository.items();
    notifyListeners();
  }

  Future<void> addRoom(String name) async {
    final room = Room(
      id: _uuid.v4(),
      name: name.trim(),
      sortOrder: _rooms.length,
    );
    await _repository.upsertRoom(room);
    _rooms = await _repository.rooms();
    notifyListeners();
  }

  Future<void> renameRoom(Room room, String name) async {
    await _repository.upsertRoom(room.copyWith(name: name.trim()));
    _rooms = await _repository.rooms();
    notifyListeners();
  }

  /// Odayı siler; içindeki eşyalar silinmez, odasız kalır.
  Future<void> deleteRoom(String id) async {
    await _repository.deleteRoom(id);
    _rooms = await _repository.rooms();
    _items = await _repository.items();
    notifyListeners();
  }

  Future<List<Item>> search(String query) =>
      query.trim().isEmpty ? Future.value(const []) : _repository.search(query);

  /// Seçilen fotoğrafı kalıcı hale getirir, anahtarını döner.
  Future<String> savePhoto(XFile file) => photos.save(file);


  // --- Türetilmiş sayılar (ana ekrandaki özet kartları) ---------------------

  /// Garantisi [Warranty.expiringSoonDays] içinde biten eşya sayısı.
  int expiringSoonCount({DateTime? now}) {
    final today = now ?? DateTime.now();
    return _items
        .where((i) => i.warrantyStatus(now: today) == WarrantyStatus.expiringSoon)
        .length;
  }

  /// Verilen eşyaların fatura tutarları toplamı (kuruş). Fiyatsızlar sayılmaz.
  int totalValueKurus(Iterable<Item> items) => items.fold(
        0,
        (sum, item) => sum + (item.priceKurus ?? 0),
      );

  /// Odada garantisi bitmiş veya bitmek üzere olan eşya yoksa envanter sağlıklı.
  bool isHealthy(Iterable<Item> items, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return !items.any((i) {
      final status = i.warrantyStatus(now: today);
      return status == WarrantyStatus.expired ||
          status == WarrantyStatus.expiringSoon;
    });
  }

  /// Garanti bilgisi olan eşyalar, bitişi en yakın olandan başlayarak.
  List<Item> warrantyWatchlist({DateTime? now}) {
    final today = now ?? DateTime.now();
    final withWarranty = _items
        .where((i) => i.warrantyDaysRemaining(now: today) != null)
        .toList()
      ..sort((a, b) => a
          .warrantyDaysRemaining(now: today)!
          .compareTo(b.warrantyDaysRemaining(now: today)!));
    return withWarranty;
  }
}
