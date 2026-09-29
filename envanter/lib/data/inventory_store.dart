import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'models/item.dart';
import 'models/room.dart';
import 'photo_store.dart';
import 'repositories/inventory_repository.dart';

/// Uygulama genelinde paylasilan envanter durumu.
class InventoryStore extends ChangeNotifier {
  InventoryStore(this._repository, this.photos);

  final InventoryRepository _repository;
  final PhotoStore photos;

  static const _uuid = Uuid();

  List<Room> _rooms = const [];
  List<Item> _items = const [];
  bool _loading = true;

  List<Room> get rooms => _rooms;
  List<Item> get items => _items;
  bool get loading => _loading;

  /// Odasi silinmis veya hic atanmamis esyalar.
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

  /// Odayi siler; icindeki esyalar silinmez, odasiz kalir.
  Future<void> deleteRoom(String id) async {
    await _repository.deleteRoom(id);
    _rooms = await _repository.rooms();
    _items = await _repository.items();
    notifyListeners();
  }

  Future<List<Item>> search(String query) =>
      query.trim().isEmpty ? Future.value(const []) : _repository.search(query);

  /// Secilen fotografi kalici klasore kopyalar, goreli yolunu doner.
  Future<String> savePhoto(File file) => photos.save(file);

  /// Garantisi yaklasan veya bitmis esyalar, en acilden baslayarak.
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
