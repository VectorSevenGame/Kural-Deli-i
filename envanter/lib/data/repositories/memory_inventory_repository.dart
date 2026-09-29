import '../models/document.dart';
import '../models/item.dart';
import '../models/room.dart';
import '../models/service_record.dart';
import 'inventory_data_source.dart';

/// Bellek içi envanter kaynağı: testler ve tasarım önizlemesi için.
///
/// Sorgu davranışı SQLite uygulamasıyla aynı olmalı (sıralama, arama
/// alanları), yoksa testler gerçeği yansıtmaz.
class MemoryInventoryRepository implements InventoryDataSource {
  MemoryInventoryRepository({
    List<Room> rooms = const [],
    List<Item> items = const [],
    List<ServiceRecord> services = const [],
  })  : _rooms = [...rooms],
        _items = [...items],
        _services = [...services];

  final List<Room> _rooms;
  final List<Item> _items;
  final List<ItemDocument> _documents = [];
  final List<ServiceRecord> _services;

  @override
  Future<List<Room>> rooms() async {
    final sorted = [..._rooms]..sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    return sorted;
  }

  @override
  Future<void> upsertRoom(Room room) async {
    _rooms
      ..removeWhere((r) => r.id == room.id)
      ..add(room);
  }

  @override
  Future<void> deleteRoom(String id) async {
    _rooms.removeWhere((r) => r.id == id);
    // SQLite'taki ON DELETE SET NULL davranışını taklit et.
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].roomId == id) {
        _items[i] = _items[i].withoutRoom();
      }
    }
  }

  @override
  Future<List<Item>> items({String? roomId}) async {
    final filtered = roomId == null
        ? [..._items]
        : _items.where((i) => i.roomId == roomId).toList();
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  @override
  Future<Item?> item(String id) async =>
      _items.where((i) => i.id == id).firstOrNull;

  @override
  Future<List<Item>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool hit(String? value) => value != null && value.toLowerCase().contains(q);
    final results = _items
        .where((i) =>
            hit(i.name) ||
            hit(i.brand) ||
            hit(i.model) ||
            hit(i.serialNumber) ||
            hit(i.seller) ||
            hit(i.note))
        .toList();
    results.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return results;
  }

  @override
  Future<void> upsertItem(Item item) async {
    _items
      ..removeWhere((i) => i.id == item.id)
      ..add(item);
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    _documents.removeWhere((d) => d.itemId == id);
    _services.removeWhere((s) => s.itemId == id);
  }

  @override
  Future<List<ItemDocument>> documents(String itemId) async =>
      _documents.where((d) => d.itemId == itemId).toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  @override
  Future<void> addDocument(ItemDocument document) async {
    _documents
      ..removeWhere((d) => d.id == document.id)
      ..add(document);
  }

  @override
  Future<void> deleteDocument(String id) async =>
      _documents.removeWhere((d) => d.id == id);

  @override
  Future<List<ServiceRecord>> serviceRecords(String itemId) async =>
      _services.where((s) => s.itemId == itemId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<void> addServiceRecord(ServiceRecord record) async {
    _services
      ..removeWhere((s) => s.id == record.id)
      ..add(record);
  }

  @override
  Future<void> deleteServiceRecord(String id) async =>
      _services.removeWhere((s) => s.id == id);
}
