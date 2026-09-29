import 'package:intl/intl.dart';

import '../domain/warranty.dart';

final DateFormat _dayFormat = DateFormat('d MMMM yyyy', 'tr_TR');
final DateFormat _shortDayFormat = DateFormat('d MMM yyyy', 'tr_TR');
final NumberFormat _wholeLira = NumberFormat.decimalPattern('tr_TR');
final NumberFormat _preciseLira =
    NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

String formatDate(DateTime? date) =>
    date == null ? '—' : _dayFormat.format(date);

String formatShortDate(DateTime? date) =>
    date == null ? '—' : _shortDayFormat.format(date);

/// Tasarımdaki biçim: tam sayıysa "₺8.450", kuruşluysa "₺8.450,75".
String formatPrice(int? kurus) {
  if (kurus == null) return '—';
  if (kurus % 100 == 0) return '₺${_wholeLira.format(kurus ~/ 100)}';
  return _preciseLira.format(kurus / 100);
}

/// Kullanıcının yazdığı fiyatı kuruş cinsine çevirir. Geçersizse `null`.
int? parsePrice(String raw) {
  final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}

/// Kart rozetlerindeki kısa etiket: "14 Ay Kaldı", "28 Gün Kaldı", "Bitti".
String warrantyShortLabel(
  WarrantyStatus status,
  int? daysRemaining,
  DateTime? endDate,
) {
  switch (status) {
    case WarrantyStatus.unknown:
      return 'Garanti bilgisi yok';
    case WarrantyStatus.expired:
      return endDate == null ? 'Bitti' : 'Bitti (${endDate.year})';
    case WarrantyStatus.expiringSoon:
    case WarrantyStatus.active:
      return '${humanDuration(daysRemaining!)} Kaldı';
  }
}

/// Detay ekranındaki durum rozeti. Gün sayısı büyük rakamla ayrıca
/// gösterildiği için burası kısa tutulur, yoksa başlık satırı taşar.
String warrantyStatusLabel(WarrantyStatus status) => switch (status) {
      WarrantyStatus.unknown => 'Bilgi Yok',
      WarrantyStatus.expired => 'Süresi Doldu',
      WarrantyStatus.expiringSoon => 'Yakında Bitiyor',
      WarrantyStatus.active => 'Aktif Koruma',
    };

/// 426 -> "1 Yıl 2 Ay", 45 -> "45 Gün", 240 -> "8 Ay"
String humanDuration(int days) {
  if (days < 45) return '$days Gün';
  final months = (days / 30.44).round();
  if (months < 12) return '$months Ay';
  final years = months ~/ 12;
  final restMonths = months % 12;
  return restMonths == 0 ? '$years Yıl' : '$years Yıl $restMonths Ay';
}

/// "42 eşya", "1 eşya"
String itemCountLabel(int count) => '$count eşya';

/// Türkçe büyük harf.
///
/// Dart'ın `toUpperCase()`'i yerelden bağımsızdır: 'i' harfini 'I' yapar,
/// 'İ' değil. Başlıklarda "KÜNYESI", "ACIL" gibi yanlış yazımlar çıkar.
String turkishUpper(String value) => value
    .replaceAll('i', 'İ')
    .replaceAll('ı', 'I')
    .toUpperCase();
