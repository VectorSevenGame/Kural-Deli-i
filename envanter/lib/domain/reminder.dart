import '../data/models/item.dart';

/// Hatırlatıcının ne hakkında olduğu.
enum ReminderKind { warranty, maintenance }

/// Zamanlanacak tek bir bildirim.
class Reminder {
  const Reminder({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.when,
    required this.title,
    required this.body,
  });

  /// Platform bildirim kimliği. Aynı eşya + aynı uyarı için her zaman aynı
  /// sayı üretilir; böylece yeniden zamanlarken kopya bildirim oluşmaz.
  final int id;
  final String itemId;
  final ReminderKind kind;
  final DateTime when;
  final String title;
  final String body;

  @override
  String toString() => 'Reminder($id, $when, $title)';
}

/// Eşya listesinden bildirim planı çıkarır.
///
/// Saf fonksiyon: takvim hesabı burada, platform çağrısı yok. Bildirim
/// sisteminin doğruluğu bu sınıfın testleriyle güvence altına alınır.
abstract final class ReminderPlanner {
  /// Garanti bitişinden kaç gün önce uyarılacak.
  ///
  /// Üç kademe: bir ay önce (servise götürmeye vakit var), bir hafta önce
  /// (son çağrı), bitiş günü.
  static const List<int> warrantyLeadDays = [30, 7, 0];

  /// Bakım tarihinden kaç gün önce uyarılacak.
  static const List<int> maintenanceLeadDays = [7, 0];

  /// Bildirimlerin gönderileceği saat (yerel).
  static const int hourOfDay = 10;

  /// [items] için gelecekteki tüm hatırlatıcıları, zamana göre sıralı döner.
  ///
  /// Geçmişte kalan uyarılar atlanır: bir bildirimi geriye dönük kurmanın
  /// anlamı yok, kullanıcıya açılış anında eski uyarı yağmuru gitmemeli.
  static List<Reminder> plan(
    Iterable<Item> items, {
    required DateTime now,
    List<int> warrantyLeads = warrantyLeadDays,
  }) {
    final reminders = <Reminder>[];

    for (final item in items) {
      final end = item.warrantyEndDate;
      if (end == null) continue;

      for (final lead in warrantyLeads) {
        final when = _at(end.subtract(Duration(days: lead)), hourOfDay);
        if (!when.isAfter(now)) continue;

        reminders.add(
          Reminder(
            id: notificationId(item.id, ReminderKind.warranty, lead),
            itemId: item.id,
            kind: ReminderKind.warranty,
            when: when,
            title: _warrantyTitle(lead),
            body: _warrantyBody(item, lead),
          ),
        );
      }
    }

    reminders.sort((a, b) => a.when.compareTo(b.when));
    return reminders;
  }

  static String _warrantyTitle(int lead) => switch (lead) {
        0 => 'Garanti bugün bitiyor',
        7 => 'Garantiye 1 hafta kaldı',
        _ => 'Garantiye $lead gün kaldı',
      };

  static String _warrantyBody(Item item, int lead) {
    final name = item.name;
    return switch (lead) {
      0 => '$name için garanti bugün sona eriyor. Bir sorun varsa bugün '
          'servise başvur.',
      _ => '$name garantisi bitmeden kontrol ettir — arıza varsa ücretsiz '
          'onarım hakkın var.',
    };
  }

  /// Eşya, tür ve kademeden kararlı bir bildirim kimliği üretir.
  ///
  /// `String.hashCode` sürümler arası değişebildiği için kendi FNV-1a
  /// karmamızı kullanıyoruz: aynı girdi her cihazda, her sürümde aynı sayıyı
  /// verir. Aksi halde uygulama güncellendiğinde eski bildirimler iptal
  /// edilemez ve kullanıcı aynı uyarıyı iki kez alır.
  static int notificationId(String itemId, ReminderKind kind, int lead) {
    final seed = '$itemId|${kind.name}|$lead';
    var hash = 0x811c9dc5;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static DateTime _at(DateTime day, int hour) =>
      DateTime(day.year, day.month, day.day, hour);
}
