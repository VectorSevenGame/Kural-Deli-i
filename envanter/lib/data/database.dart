import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'models/room.dart';

/// Yerel SQLite veritabani.
///
/// Veri yalnizca cihazda durur: hesap yok, sunucu yok.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const String fileName = 'envanter.db';
  static const int schemaVersion = 1;

  static Future<AppDatabase> open({String? directory}) async {
    final dir = directory ?? await getDatabasesPath();
    final database = await openDatabase(
      p.join(dir, fileName),
      version: schemaVersion,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return AppDatabase._(database);
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE rooms (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE items (
        id              TEXT PRIMARY KEY,
        name            TEXT NOT NULL,
        category        TEXT NOT NULL,
        room_id         TEXT REFERENCES rooms(id) ON DELETE SET NULL,
        brand           TEXT,
        model           TEXT,
        serial_number   TEXT,
        purchase_date   INTEGER,
        price_kurus     INTEGER,
        seller          TEXT,
        warranty_months INTEGER,
        photo_path      TEXT,
        note            TEXT,
        created_at      INTEGER NOT NULL,
        updated_at      INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE documents (
        id        TEXT PRIMARY KEY,
        item_id   TEXT NOT NULL REFERENCES items(id) ON DELETE CASCADE,
        kind      TEXT NOT NULL,
        file_path TEXT NOT NULL,
        title     TEXT,
        added_at  INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE service_records (
        id         TEXT PRIMARY KEY,
        item_id    TEXT NOT NULL REFERENCES items(id) ON DELETE CASCADE,
        kind       TEXT NOT NULL,
        date       INTEGER NOT NULL,
        provider   TEXT,
        note       TEXT,
        cost_kurus INTEGER,
        next_date  INTEGER
      )
    ''');

    batch.execute('CREATE INDEX idx_items_room ON items(room_id)');
    batch.execute('CREATE INDEX idx_documents_item ON documents(item_id)');
    batch.execute('CREATE INDEX idx_service_item ON service_records(item_id)');

    const uuid = Uuid();
    for (var i = 0; i < defaultRoomNames.length; i++) {
      batch.insert(
        'rooms',
        Room(id: uuid.v4(), name: defaultRoomNames[i], sortOrder: i).toMap(),
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int from, int to) async {
    // Surum 1 ilk surum; goc adimlari buraya eklenecek.
  }

  Future<void> close() => db.close();
}
