import 'package:envanter/data/models/item.dart';
import 'package:envanter/domain/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item({
  required String id,
  required String name,
  DateTime? purchase,
  int? warrantyMonths,
}) =>
    Item(
      id: id,
      name: name,
      category: ItemCategory.other,
      purchaseDate: purchase,
      warrantyMonths: warrantyMonths,
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );

void main() {
  final now = DateTime(2026, 1, 1, 12);

  group('ReminderPlanner.plan', () {
    test('garanti bilgisi olmayan esya icin hatirlatici uretmez', () {
      final plan = ReminderPlanner.plan(
        [_item(id: 'a', name: 'Lamba')],
        now: now,
      );
      expect(plan, isEmpty);
    });

    test('her kademe icin bir hatirlatici uretir', () {
      // Bitis: 2026-07-01 -> 30, 7 ve 0 gun oncesi hepsi gelecekte.
      final plan = ReminderPlanner.plan(
        [
          _item(
            id: 'a',
            name: 'Buzdolabi',
            purchase: DateTime(2024, 7, 1),
            warrantyMonths: 24,
          ),
        ],
        now: now,
      );
      expect(plan.length, 3);
      expect(
        plan.map((r) => r.when).toList(),
        [
          DateTime(2026, 6, 1, 10),
          DateTime(2026, 6, 24, 10),
          DateTime(2026, 7, 1, 10),
        ],
      );
    });

    test('gecmiste kalan kademeleri atlar', () {
      // Bitis: 2026-01-20. 30 gun oncesi (2025-12-21) gecmis, digerleri degil.
      final plan = ReminderPlanner.plan(
        [
          _item(
            id: 'a',
            name: 'Klima',
            purchase: DateTime(2024, 1, 20),
            warrantyMonths: 24,
          ),
        ],
        now: now,
      );
      expect(plan.length, 2);
      expect(plan.first.when, DateTime(2026, 1, 13, 10));
    });

    test('garantisi coktan bitmis esya icin hicbir sey uretmez', () {
      final plan = ReminderPlanner.plan(
        [
          _item(
            id: 'a',
            name: 'Eski TV',
            purchase: DateTime(2015, 1, 1),
            warrantyMonths: 24,
          ),
        ],
        now: now,
      );
      expect(plan, isEmpty);
    });

    test('sonuc zamana gore sirali', () {
      final plan = ReminderPlanner.plan(
        [
          _item(
            id: 'gec',
            name: 'Gec',
            purchase: DateTime(2025, 6, 1),
            warrantyMonths: 24,
          ),
          _item(
            id: 'erken',
            name: 'Erken',
            purchase: DateTime(2024, 4, 1),
            warrantyMonths: 24,
          ),
        ],
        now: now,
      );
      for (var i = 1; i < plan.length; i++) {
        expect(
          plan[i].when.isBefore(plan[i - 1].when),
          isFalse,
          reason: 'sira bozuk: ${plan[i - 1]} -> ${plan[i]}',
        );
      }
    });

    test('bildirim saati 10:00', () {
      final plan = ReminderPlanner.plan(
        [
          _item(
            id: 'a',
            name: 'Firin',
            purchase: DateTime(2025, 1, 1),
            warrantyMonths: 24,
          ),
        ],
        now: now,
      );
      expect(plan.every((r) => r.when.hour == 10), isTrue);
    });

    test('metinler esyanin adini icerir ve bos degil', () {
      final plan = ReminderPlanner.plan(
        [
          _item(
            id: 'a',
            name: 'Siemens Bulasik Makinesi',
            purchase: DateTime(2025, 1, 1),
            warrantyMonths: 24,
          ),
        ],
        now: now,
      );
      expect(plan, isNotEmpty);
      for (final reminder in plan) {
        expect(reminder.title, isNotEmpty);
        expect(reminder.body, contains('Siemens Bulasik Makinesi'));
      }
    });
  });

  group('ReminderPlanner.notificationId', () {
    test('ayni girdi ayni kimligi verir', () {
      expect(
        ReminderPlanner.notificationId('abc', ReminderKind.warranty, 30),
        ReminderPlanner.notificationId('abc', ReminderKind.warranty, 30),
      );
    });

    test('farkli esya, tur veya kademe farkli kimlik verir', () {
      final base =
          ReminderPlanner.notificationId('abc', ReminderKind.warranty, 30);
      expect(
        ReminderPlanner.notificationId('abd', ReminderKind.warranty, 30),
        isNot(base),
      );
      expect(
        ReminderPlanner.notificationId('abc', ReminderKind.maintenance, 30),
        isNot(base),
      );
      expect(
        ReminderPlanner.notificationId('abc', ReminderKind.warranty, 7),
        isNot(base),
      );
    });

    test('32 bit pozitif tam sayi araliginda kalir', () {
      for (final id in ['a', 'uzun-bir-uuid-4f3a2b1c', '', '  ']) {
        final value =
            ReminderPlanner.notificationId(id, ReminderKind.warranty, 0);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(0x7fffffff));
      }
    });

    test('bir plandaki kimlikler benzersiz', () {
      final items = [
        for (var i = 0; i < 40; i++)
          _item(
            id: 'item-$i',
            name: 'Esya $i',
            purchase: DateTime(2025, 1, 1 + (i % 28)),
            warrantyMonths: 24,
          ),
      ];
      final plan = ReminderPlanner.plan(items, now: now);
      final ids = plan.map((r) => r.id).toSet();
      expect(ids.length, plan.length, reason: 'kimlik cakismasi var');
    });
  });
}
