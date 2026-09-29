import 'package:envanter/domain/warranty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Warranty.endDate', () {
    test('alim tarihine ay ekler', () {
      expect(
        Warranty.endDate(DateTime(2024, 3, 15), 24),
        DateTime(2026, 3, 15),
      );
    });

    test('yil sinirini asar', () {
      expect(
        Warranty.endDate(DateTime(2024, 11, 10), 3),
        DateTime(2025, 2, 10),
      );
    });

    test('ayin son gunu tasmaz', () {
      // 31 Ocak + 1 ay -> 28 Subat (2025 artik yil degil).
      expect(
        Warranty.endDate(DateTime(2025, 1, 31), 1),
        DateTime(2025, 2, 28),
      );
    });

    test('artik yilda 29 Subat', () {
      expect(
        Warranty.endDate(DateTime(2024, 1, 31), 1),
        DateTime(2024, 2, 29),
      );
    });

    test('eksik bilgide null', () {
      expect(Warranty.endDate(null, 24), isNull);
      expect(Warranty.endDate(DateTime(2024, 1, 1), null), isNull);
      expect(Warranty.endDate(DateTime(2024, 1, 1), 0), isNull);
      expect(Warranty.endDate(DateTime(2024, 1, 1), -5), isNull);
    });
  });

  group('Warranty.statusOf', () {
    final purchase = DateTime(2024, 1, 1);
    const months = 24; // bitis: 2026-01-01

    test('surerken active', () {
      expect(
        Warranty.statusOf(purchase, months, now: DateTime(2024, 6, 1)),
        WarrantyStatus.active,
      );
    });

    test('60 gun kala expiringSoon', () {
      expect(
        Warranty.statusOf(purchase, months, now: DateTime(2025, 12, 10)),
        WarrantyStatus.expiringSoon,
      );
    });

    test('bitis gunu hala gecerli', () {
      expect(
        Warranty.statusOf(purchase, months, now: DateTime(2026, 1, 1)),
        WarrantyStatus.expiringSoon,
      );
      expect(
        Warranty.daysRemaining(purchase, months, now: DateTime(2026, 1, 1)),
        0,
      );
    });

    test('ertesi gun expired', () {
      expect(
        Warranty.statusOf(purchase, months, now: DateTime(2026, 1, 2)),
        WarrantyStatus.expired,
      );
    });

    test('bilgi yoksa unknown', () {
      expect(
        Warranty.statusOf(null, null, now: DateTime(2025, 1, 1)),
        WarrantyStatus.unknown,
      );
    });

    test('saat farki gun sayisini kaydirmaz', () {
      // Gece yarisina yakin saat, gun hesabini bozmamali.
      expect(
        Warranty.daysRemaining(
          DateTime(2024, 1, 1),
          12,
          now: DateTime(2024, 12, 31, 23, 30),
        ),
        1,
      );
    });
  });

  group('Maintenance.statusOf', () {
    final now = DateTime(2026, 5, 10);

    test('tarih yoksa none', () {
      expect(Maintenance.statusOf(null, now: now), MaintenanceStatus.none);
    });

    test('gecmisse overdue', () {
      expect(
        Maintenance.statusOf(DateTime(2026, 5, 9), now: now),
        MaintenanceStatus.overdue,
      );
    });

    test('14 gun icindeyse due', () {
      expect(
        Maintenance.statusOf(DateTime(2026, 5, 20), now: now),
        MaintenanceStatus.due,
      );
    });

    test('uzaksa upcoming', () {
      expect(
        Maintenance.statusOf(DateTime(2026, 8, 1), now: now),
        MaintenanceStatus.upcoming,
      );
    });
  });
}
