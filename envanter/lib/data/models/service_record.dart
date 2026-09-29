/// Bir eşyaya yapılan bakım / onarım kaydı.
enum ServiceKind {
  maintenance('Bakım'),
  repair('Onarım'),
  inspection('Kontrol');

  const ServiceKind(this.label);

  final String label;

  static ServiceKind fromName(String? name) => values.firstWhere(
        (k) => k.name == name,
        orElse: () => ServiceKind.maintenance,
      );
}

class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.date,
    this.provider,
    this.note,
    this.costKurus,
    this.nextDate,
  });

  final String id;
  final String itemId;
  final ServiceKind kind;
  final DateTime date;
  final String? provider;
  final String? note;
  final int? costKurus;

  /// Bir sonraki bakım tarihi (örn. kombi yıllık bakımı).
  final DateTime? nextDate;

  Map<String, Object?> toMap() => {
        'id': id,
        'item_id': itemId,
        'kind': kind.name,
        'date': date.millisecondsSinceEpoch,
        'provider': provider,
        'note': note,
        'cost_kurus': costKurus,
        'next_date': nextDate?.millisecondsSinceEpoch,
      };

  factory ServiceRecord.fromMap(Map<String, Object?> map) => ServiceRecord(
        id: map['id']! as String,
        itemId: map['item_id']! as String,
        kind: ServiceKind.fromName(map['kind'] as String?),
        date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
        provider: map['provider'] as String?,
        note: map['note'] as String?,
        costKurus: map['cost_kurus'] as int?,
        nextDate: map['next_date'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['next_date']! as int),
      );
}
