/// Garanti ve bakim hesaplari.
///
/// Saf Dart: Flutter'a bagimli degil, birim testle kaplanir.
library;

/// Bir esyanin garanti durumu.
enum WarrantyStatus {
  /// Garanti bilgisi girilmemis (alim tarihi veya sure yok).
  unknown,

  /// Garanti devam ediyor.
  active,

  /// Garanti [Warranty.expiringSoonDays] gun icinde bitiyor.
  expiringSoon,

  /// Garanti bitmis.
  expired,
}

abstract final class Warranty {
  /// Garantinin bitisine bu kadar gun veya daha az kaldiysa "yakinda bitiyor".
  static const int expiringSoonDays = 60;

  /// Alim tarihi ve ay cinsinden sureden garanti bitis tarihini hesaplar.
  ///
  /// Ikisinden biri eksikse veya sure pozitif degilse `null` doner.
  static DateTime? endDate(DateTime? purchaseDate, int? months) {
    if (purchaseDate == null || months == null || months <= 0) return null;

    final totalMonths = purchaseDate.month + months;
    final year = purchaseDate.year + (totalMonths - 1) ~/ 12;
    final month = (totalMonths - 1) % 12 + 1;
    // Ayin son gunu tasmasin: 31 Ocak + 1 ay -> 28/29 Subat.
    final day = purchaseDate.day <= _daysInMonth(year, month)
        ? purchaseDate.day
        : _daysInMonth(year, month);

    return DateTime(year, month, day);
  }

  /// Garantinin bitmesine kalan tam gun sayisi. Bitmisse negatif olur.
  static int? daysRemaining(
    DateTime? purchaseDate,
    int? months, {
    required DateTime now,
  }) {
    final end = endDate(purchaseDate, months);
    if (end == null) return null;
    return _dateOnly(end).difference(_dateOnly(now)).inDays;
  }

  static WarrantyStatus statusOf(
    DateTime? purchaseDate,
    int? months, {
    required DateTime now,
  }) {
    final remaining = daysRemaining(purchaseDate, months, now: now);
    if (remaining == null) return WarrantyStatus.unknown;
    if (remaining < 0) return WarrantyStatus.expired;
    if (remaining <= expiringSoonDays) return WarrantyStatus.expiringSoon;
    return WarrantyStatus.active;
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Bakim tarihinin durumu.
enum MaintenanceStatus { none, upcoming, due, overdue }

abstract final class Maintenance {
  /// Bakima bu kadar gun kaldiginda "yaklasti" sayilir.
  static const int dueSoonDays = 14;

  static MaintenanceStatus statusOf(DateTime? nextDate,
      {required DateTime now}) {
    if (nextDate == null) return MaintenanceStatus.none;
    final days = Warranty._dateOnly(nextDate)
        .difference(Warranty._dateOnly(now))
        .inDays;
    if (days < 0) return MaintenanceStatus.overdue;
    if (days <= dueSoonDays) return MaintenanceStatus.due;
    return MaintenanceStatus.upcoming;
  }
}
