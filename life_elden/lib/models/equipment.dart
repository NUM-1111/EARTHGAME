class Equipment {
  final int? id;
  final String name;
  final String rarity; // Common, Rare, Epic, Legendary
  final String buffDescription;
  final bool isEquipped;

  Equipment({
    this.id,
    required this.name,
    required this.rarity,
    required this.buffDescription,
    this.isEquipped = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'rarity': rarity,
        'buff_description': buffDescription,
        'is_equipped': isEquipped ? 1 : 0,
      };

  factory Equipment.fromMap(Map<String, dynamic> m) => Equipment(
        id: m['id'] as int?,
        name: m['name'] as String,
        rarity: m['rarity'] as String,
        buffDescription: m['buff_description'] as String,
        isEquipped: (m['is_equipped'] as int? ?? 0) == 1,
      );

  Equipment copyWith({int? id, String? name, String? rarity, String? buffDescription, bool? isEquipped}) => Equipment(
        id: id ?? this.id,
        name: name ?? this.name,
        rarity: rarity ?? this.rarity,
        buffDescription: buffDescription ?? this.buffDescription,
        isEquipped: isEquipped ?? this.isEquipped,
      );
}
