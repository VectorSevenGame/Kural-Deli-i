import 'package:envanter/data/models/item.dart';
import 'package:envanter/data/models/room.dart';

/// Ekran görüntüleri ve arayüz testleri için sabit demo envanter.
///
/// Alım tarihleri bugüne göre *göreli* verilir (kaç ay önce alındı).
/// Böylece ekran görüntüleri hangi gün üretilirse üretilsin garanti
/// sayaçları anlamlı kalır: bir kısmı aktif, bir kısmı yaklaşan, biri bitmiş.
DateTime _monthsAgo(int months) {
  final now = DateTime.now();
  // DateTime, taşan ay değerlerini kendisi normalleştirir; elle bölme
  // yapmıyoruz çünkü Dart'ın `~/` işleci negatifte sıfıra doğru keser.
  final shifted = DateTime(now.year, now.month - months, 1);
  final lastDay = DateTime(shifted.year, shifted.month + 1, 0).day;
  return DateTime(
    shifted.year,
    shifted.month,
    now.day <= lastDay ? now.day : lastDay,
  );
}

const Room salon = Room(id: 'r1', name: 'Salon', sortOrder: 0);
const Room mutfak = Room(id: 'r2', name: 'Mutfak', sortOrder: 1);
const Room yatak = Room(id: 'r3', name: 'Yatak Odası', sortOrder: 2);

List<Room> demoRooms() => const [salon, mutfak, yatak];

Item _item({
  required String id,
  required String name,
  required String roomId,
  required ItemCategory category,
  String? brand,
  String? model,
  String? serial,
  String? seller,
  required DateTime purchase,
  required int price,
  int? warrantyMonths = 24,
  String? note,
}) =>
    Item(
      id: id,
      name: name,
      category: category,
      roomId: roomId,
      brand: brand,
      model: model,
      serialNumber: serial,
      seller: seller,
      purchaseDate: purchase,
      priceKurus: price * 100,
      warrantyMonths: warrantyMonths,
      note: note,
      createdAt: purchase,
      updatedAt: purchase,
    );

List<Item> demoItems() => [
      _item(
        id: 'i1',
        name: 'DeLonghi Dedica Espresso',
        roomId: mutfak.id,
        category: ItemCategory.electronics,
        brand: 'DeLonghi',
        model: 'EC685.M',
        serial: 'SN-98421034-TR',
        seller: 'Amazon Türkiye',
        purchase: _monthsAgo(11),
        price: 8450,
        note: 'Kireç temizliği 3 ayda bir, EcoDecalk ile.',
      ),
      _item(
        id: 'i2',
        name: 'Dyson V12 Detect Slim',
        roomId: salon.id,
        category: ItemCategory.electronics,
        brand: 'Dyson',
        model: 'V12',
        seller: 'MediaMarkt',
        purchase: _monthsAgo(23),
        price: 22800,
      ),
      _item(
        id: 'i3',
        name: 'Sony XR-65A80J OLED',
        roomId: salon.id,
        category: ItemCategory.electronics,
        brand: 'Sony',
        model: 'XR-65A80J',
        seller: 'Vatan Bilgisayar',
        purchase: _monthsAgo(6),
        price: 54000,
        warrantyMonths: 36,
      ),
      _item(
        id: 'i4',
        name: 'Poäng Huş Ağacı Koltuk',
        roomId: salon.id,
        category: ItemCategory.furniture,
        brand: 'IKEA',
        seller: 'IKEA Ümraniye',
        purchase: _monthsAgo(64),
        price: 3900,
      ),
      _item(
        id: 'i5',
        name: 'Hue White & Color Ampul',
        roomId: salon.id,
        category: ItemCategory.electronics,
        brand: 'Philips',
        seller: 'Trendyol',
        purchase: _monthsAgo(16),
        price: 4200,
      ),
      _item(
        id: 'i6',
        name: 'Arçelik No-Frost Buzdolabı',
        roomId: mutfak.id,
        category: ItemCategory.whiteGoods,
        brand: 'Arçelik',
        model: '584630 MB',
        serial: 'AR-5846-2024',
        seller: 'Arçelik Bayi',
        purchase: _monthsAgo(22),
        price: 41500,
      ),
      _item(
        id: 'i7',
        name: 'Siemens Çamaşır Makinesi',
        roomId: mutfak.id,
        category: ItemCategory.whiteGoods,
        brand: 'Siemens',
        model: 'WM14N2X0TR',
        seller: 'Teknosa',
        purchase: _monthsAgo(9),
        price: 28900,
        warrantyMonths: 36,
      ),
      _item(
        id: 'i8',
        name: 'Daikin Klima',
        roomId: yatak.id,
        category: ItemCategory.heating,
        brand: 'Daikin',
        seller: 'Yetkili Servis',
        purchase: _monthsAgo(38),
        price: 19750,
      ),
    ];
