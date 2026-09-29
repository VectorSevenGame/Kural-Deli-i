/// Bir eşyaya bağlı belge (fatura, garanti belgesi, kılavuz).
enum DocumentKind {
  invoice('Fatura'),
  warranty('Garanti Belgesi'),
  manual('Kılavuz'),
  other('Diğer');

  const DocumentKind(this.label);

  final String label;

  static DocumentKind fromName(String? name) => values.firstWhere(
        (k) => k.name == name,
        orElse: () => DocumentKind.other,
      );
}

class ItemDocument {
  const ItemDocument({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.filePath,
    this.title,
    required this.addedAt,
  });

  final String id;
  final String itemId;
  final DocumentKind kind;

  /// Uygulamanın belge klasörüne göre göreli yol.
  final String filePath;
  final String? title;
  final DateTime addedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'item_id': itemId,
        'kind': kind.name,
        'file_path': filePath,
        'title': title,
        'added_at': addedAt.millisecondsSinceEpoch,
      };

  factory ItemDocument.fromMap(Map<String, Object?> map) => ItemDocument(
        id: map['id']! as String,
        itemId: map['item_id']! as String,
        kind: DocumentKind.fromName(map['kind'] as String?),
        filePath: map['file_path']! as String,
        title: map['title'] as String?,
        addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at']! as int),
      );
}
