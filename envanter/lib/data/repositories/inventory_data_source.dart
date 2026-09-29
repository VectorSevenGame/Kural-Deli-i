import '../models/document.dart';
import '../models/item.dart';
import '../models/room.dart';
import '../models/service_record.dart';

/// Envanter verisinin kaynağı.
///
/// Uygulamada SQLite'a bağlanır; testlerde ve önizlemede bellek içi bir
/// uygulaması kullanılır. Store yalnızca bu arayüzü tanır.
abstract interface class InventoryDataSource {
  Future<List<Room>> rooms();
  Future<void> upsertRoom(Room room);
  Future<void> deleteRoom(String id);

  Future<List<Item>> items({String? roomId});
  Future<Item?> item(String id);
  Future<List<Item>> search(String query);
  Future<void> upsertItem(Item item);
  Future<void> deleteItem(String id);

  Future<List<ItemDocument>> documents(String itemId);
  Future<void> addDocument(ItemDocument document);
  Future<void> deleteDocument(String id);

  Future<List<ServiceRecord>> serviceRecords(String itemId);
  Future<void> addServiceRecord(ServiceRecord record);
  Future<void> deleteServiceRecord(String id);
}
