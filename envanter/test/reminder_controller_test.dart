import 'package:envanter/data/inventory_store.dart';
import 'package:envanter/data/models/item.dart';
import 'package:envanter/data/photo_store_memory.dart';
import 'package:envanter/data/repositories/memory_inventory_repository.dart';
import 'package:envanter/services/notification_service.dart';
import 'package:envanter/services/reminder_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Çağrıları kaydeden sahte bildirim servisi.
class FakeNotifications implements NotificationService {
  FakeNotifications({this.grant = true});

  /// İzin isteğine verilecek cevap.
  bool grant;

  bool granted = false;
  int syncCount = 0;
  int cancelCount = 0;
  List<Item> lastSynced = const [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    granted = grant;
    return grant;
  }

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<void> sync(Iterable<Item> items) async {
    syncCount++;
    lastSynced = items.toList();
  }

  @override
  Future<int> scheduledCount() async => lastSynced.length;

  @override
  Future<void> cancelAll() async => cancelCount++;
}

Item _item(String id) => Item(
      id: id,
      name: 'Eşya $id',
      category: ItemCategory.other,
      purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      warrantyMonths: 24,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

Future<(ReminderController, FakeNotifications, InventoryStore)> build({
  bool grant = true,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final store = InventoryStore(
    MemoryInventoryRepository(items: [_item('a')]),
    MemoryPhotoStore(),
  );
  await store.load();
  final notifications = FakeNotifications(grant: grant);
  final controller = ReminderController(
    notifications: notifications,
    inventory: store,
    preferences: await SharedPreferences.getInstance(),
  );
  return (controller, notifications, store);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('varsayilan olarak kapali', () async {
    final (controller, notifications, _) = await build();
    expect(controller.enabled, isFalse);
    expect(notifications.syncCount, 0);
    controller.dispose();
  });

  test('acilinca izin ister ve bildirimleri kurar', () async {
    final (controller, notifications, _) = await build();
    final ok = await controller.setEnabled(true);

    expect(ok, isTrue);
    expect(controller.enabled, isTrue);
    expect(notifications.syncCount, 1);
    controller.dispose();
  });

  test('izin reddedilirse kapali kalir ve bildirim kurulmaz', () async {
    final (controller, notifications, _) = await build(grant: false);
    final ok = await controller.setEnabled(true);

    expect(ok, isFalse);
    expect(controller.enabled, isFalse);
    expect(notifications.syncCount, 0);
    controller.dispose();
  });

  test('kapatilinca hepsi iptal edilir', () async {
    final (controller, notifications, _) = await build();
    await controller.setEnabled(true);
    await controller.setEnabled(false);

    expect(controller.enabled, isFalse);
    expect(notifications.cancelCount, greaterThan(0));
    expect(controller.scheduledCount, 0);
    controller.dispose();
  });

  test('acikken envanter degisince yeniden kurar', () async {
    final (controller, notifications, store) = await build();
    await controller.setEnabled(true);
    final before = notifications.syncCount;

    await store.saveItem(_item('b'));
    // Kontrolcü art arda gelen değişiklikleri bekletiyor.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(notifications.syncCount, greaterThan(before));
    expect(notifications.lastSynced.length, 2);
    controller.dispose();
  });

  test('kapaliyken envanter degisse de bildirim kurmaz', () async {
    final (controller, notifications, store) = await build();

    await store.saveItem(_item('b'));
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(notifications.syncCount, 0);
    controller.dispose();
  });

  test('izin sistem ayarlarindan kapatildiysa acilisda kendini kapatir',
      () async {
    // Kayıtta açık görünüyor ama işletim sistemi izni yok.
    final (controller, notifications, _) =
        await build(prefs: {'reminders.enabled': true});
    expect(controller.enabled, isTrue);

    await controller.start();

    expect(controller.enabled, isFalse);
    expect(notifications.syncCount, 0);
    controller.dispose();
  });
}
