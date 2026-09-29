/// Evdeki bir oda / alan.
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  Room copyWith({String? name, int? sortOrder}) => Room(
        id: id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'sort_order': sortOrder,
      };

  factory Room.fromMap(Map<String, Object?> map) => Room(
        id: map['id']! as String,
        name: map['name']! as String,
        sortOrder: map['sort_order']! as int,
      );
}

/// Ilk acilista olusturulan varsayilan odalar.
const List<String> defaultRoomNames = [
  'Salon',
  'Mutfak',
  'Yatak Odasi',
  'Banyo',
  'Balkon',
  'Depo',
];
