import '../../domain/warranty.dart';

/// Esya kategorisi.
///
/// Her kategorinin varsayilan garanti suresi vardir. Turkiye'de tuketici
/// garantisi cogu urunde 2 yildir (6502 sayili kanun); kategoriler
/// ayristikca bu degerler farklilasacak.
enum ItemCategory {
  whiteGoods('Beyaz Esya', 24),
  electronics('Elektronik', 24),
  furniture('Mobilya', 24),
  heating('Isitma / Kombi', 24),
  tool('Alet / Bahce', 24),
  other('Diger', 24);

  const ItemCategory(this.label, this.defaultWarrantyMonths);

  final String label;
  final int defaultWarrantyMonths;

  static ItemCategory fromName(String? name) => values.firstWhere(
        (c) => c.name == name,
        orElse: () => ItemCategory.other,
      );
}

/// Evdeki tek bir esya.
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

  /// Fiyat kurus cinsinden tam sayi olarak tutulur (kayan nokta hatasi olmasin).
  final int? priceKurus;
  final String? seller;
  final int? warrantyMonths;

  /// Uygulamanin belge klasorune gore goreli yol.
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
