import '../../domain/warranty.dart';

/// Eşya kategorisi.
///
/// Her kategorinin varsayılan garanti süresi vardır. Türkiye'de tüketici
/// garantisi çoğu üründe 2 yıldır (6502 sayılı kanun); kategoriler
/// ayrıştıkça bu değerler farklılaşacak.
enum ItemCategory {
  whiteGoods('Beyaz Eşya', 24),
  electronics('Elektronik', 24),
  furniture('Mobilya', 24),
  heating('Isıtma / Kombi', 24),
  tool('Alet / Bahçe', 24),
  other('Diğer', 24);

  const ItemCategory(this.label, this.defaultWarrantyMonths);

  final String label;
  final int defaultWarrantyMonths;

  static ItemCategory fromName(String? name) => values.firstWhere(
        (c) => c.name == name,
        orElse: () => ItemCategory.other,
      );
}

/// Evdeki tek bir eşya.
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.category,
    this.roomId,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.priceKurus,
    this.seller,
    this.warrantyMonths,
    this.photoPath,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final ItemCategory category;
  final String? roomId;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;

  /// Fiyat kuruş cinsinden tam sayı olarak tutulur (kayan nokta hatası olmasın).
  final int? priceKurus;
  final String? seller;
  final int? warrantyMonths;

  /// Uygulamanın belge klasörüne göre göreli yol.
  final String? photoPath;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime? get warrantyEndDate =>
      Warranty.endDate(purchaseDate, warrantyMonths);

  WarrantyStatus warrantyStatus({DateTime? now}) => Warranty.statusOf(
        purchaseDate,
        warrantyMonths,
        now: now ?? DateTime.now(),
      );

  int? warrantyDaysRemaining({DateTime? now}) => Warranty.daysRemaining(
        purchaseDate,
        warrantyMonths,
        now: now ?? DateTime.now(),
      );

  Item copyWith({
    String? name,
    ItemCategory? category,
    String? roomId,
    String? brand,
    String? model,
    String? serialNumber,
    DateTime? purchaseDate,
    int? priceKurus,
    String? seller,
    int? warrantyMonths,
    String? photoPath,
    String? note,
    DateTime? updatedAt,
  }) =>
      Item(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        roomId: roomId ?? this.roomId,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        serialNumber: serialNumber ?? this.serialNumber,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        priceKurus: priceKurus ?? this.priceKurus,
        seller: seller ?? this.seller,
        warrantyMonths: warrantyMonths ?? this.warrantyMonths,
        photoPath: photoPath ?? this.photoPath,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  /// Odası silindiğinde çağrılır: `copyWith` null atayamadığı için ayrı.
  Item withoutRoom() => Item(
        id: id,
        name: name,
        category: category,
        brand: brand,
        model: model,
        serialNumber: serialNumber,
        purchaseDate: purchaseDate,
        priceKurus: priceKurus,
        seller: seller,
        warrantyMonths: warrantyMonths,
        photoPath: photoPath,
        note: note,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'room_id': roomId,
        'brand': brand,
        'model': model,
        'serial_number': serialNumber,
        'purchase_date': purchaseDate?.millisecondsSinceEpoch,
        'price_kurus': priceKurus,
        'seller': seller,
        'warranty_months': warrantyMonths,
        'photo_path': photoPath,
        'note': note,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Item.fromMap(Map<String, Object?> map) => Item(
        id: map['id']! as String,
        name: map['name']! as String,
        category: ItemCategory.fromName(map['category'] as String?),
        roomId: map['room_id'] as String?,
        brand: map['brand'] as String?,
        model: map['model'] as String?,
        serialNumber: map['serial_number'] as String?,
        purchaseDate: _date(map['purchase_date']),
        priceKurus: map['price_kurus'] as int?,
        seller: map['seller'] as String?,
        warrantyMonths: map['warranty_months'] as int?,
        photoPath: map['photo_path'] as String?,
        note: map['note'] as String?,
        createdAt: _date(map['created_at'])!,
        updatedAt: _date(map['updated_at'])!,
      );

  static DateTime? _date(Object? value) => value == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(value as int);
}
