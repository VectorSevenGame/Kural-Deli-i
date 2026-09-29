import 'package:intl/intl.dart';

import '../domain/warranty.dart';

final DateFormat _dayFormat = DateFormat('d MMMM yyyy', 'tr_TR');
final NumberFormat _liraFormat =
    NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 2);

String formatDate(DateTime? date) =>
    date == null ? '-' : _dayFormat.format(date);

String formatPrice(int? kurus) =>
    kurus == null ? '-' : _liraFormat.format(kurus / 100);

/// Kullanicinin yazdigi fiyati kurus cinsine cevirir. Gecersizse `null`.
int? parsePrice(String raw) {
  final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0) return null;
  return (value * 100).round();
}

/// Garanti durumunun kisa Turkce etiketi.
String warrantyLabel(WarrantyStatus status, int? daysRemaining) {
  switch (status) {
    case WarrantyStatus.unknown:
      return 'Garanti bilgisi yok';
    case WarrantyStatus.expired:
      return 'Garanti bitti';
    case WarrantyStatus.expiringSoon:
      return 'Garanti: $daysRemaining gun kaldi';
    case WarrantyStatus.active:
      return 'Garanti: ${_humanDuration(daysRemaining!)} kaldi';
  }
}

String _humanDuration(int days) {
  if (days < 30) return '$days gun';
  final months = days ~/ 30;
  if (months < 12) return '$months ay';
  final years = months ~/ 12;
  final restMonths = months % 12;
  return restMonths == 0 ? '$years yil' : '$years yil $restMonths ay';
}
