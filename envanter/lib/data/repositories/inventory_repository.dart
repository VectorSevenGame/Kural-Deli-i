import 'package:sqflite/sqflite.dart';

import '../database.dart';
import '../models/document.dart';
import '../models/item.dart';
import '../models/room.dart';
import '../models/service_record.dart';

/// Odalar, esyalar, belgeler ve bakim kayitlari icin tek veri kapisi.
class InventoryRepository {
  InventoryRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  // --- Odalar -------------------------------------------------------------

  Future<List<Room>> rooms() async {
    final rows = await _db.query('rooms', orderBy: 'sort_order ASC, name ASC');
    return rows.map(Room.fromMap).toList();
  }

  Future<void> upsertRoom(Room room) => _db.insert(
        'rooms',
        room.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteRoom(String id) =>
      _db.delete('rooms', where: 'id = ?', whereArgs: [id]);

  // --- Esyalar ------------------------------------------------------------

  Future<List<Item>> items({String? roomId}) async {
    final rows = await _db.query(
      'items',
      where: roomId == null ? null : 'room_id = ?',
      whereArgs: roomId == null ? null : [roomId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<Item?> item(String id) async {
    final rows = await _db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Item.fromMap(rows.first);
  }

  Future<List<Item>> search(String query) async {
    final q = '%${query.trim()}%';
    final rows = await _db.query(
      'items',
      where: '''
        name LIKE ? OR brand LIKE ? OR model LIKE ?
        OR serial_number LIKE ? OR seller LIKE ? OR note LIKE ?
      ''',
      whereArgs: List.filled(6, q),
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<void> upsertItem(Item item) => _db.insert(
        'items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// Esyayi siler. Belgeleri ve bakim kayitlari ON DELETE CASCADE ile gider.
  Future<void> deleteItem(String id) =>
      _db.delete('items', where: 'id = ?', whereArgs: [id]);

  // --- Belgeler -----------------------------------------------------------

  Future<List<ItemDocument>> documents(String itemId) async {
    final rows = await _db.query(
      'documents',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'added_at DESC',
    );
    return rows.map(ItemDocument.fromMap).toList();
  }

  Future<void> addDocument(ItemDocument document) => _db.insert(
        'documents',
        document.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteDocument(String id) =>
      _db.delete('documents', where: 'id = ?', whereArgs: [id]);

  // --- Bakim kayitlari ----------------------------------------------------

  Future<List<ServiceRecord>> serviceRecords(String itemId) async {
    final rows = await _db.query(
      'service_records',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<void> addServiceRecord(ServiceRecord record) => _db.insert(
        'service_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteServiceRecord(String id) =>
      _db.delete('service_records', where: 'id = ?', whereArgs: [id]);
}
