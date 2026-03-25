class Equipment {
  final int? id;
  final String name;
  final String rarity; // Common, Rare, Epic, Legendary
  final String buffDescription;
  final bool isEquipped;
  final bool isArchived;
  final String archivedAt; // ISO8601 or ''

  Equipment({
    this.id,
    required this.name,
    required this.rarity,
    required this.buffDescription,
    this.isEquipped = false,
    this.isArchived = false,
    this.archivedAt = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'rarity': rarity,
        'buff_description': buffDescription,
        'is_equipped': isEquipped ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'archived_at': archivedAt.isEmpty ? null : archivedAt,
      };

  factory Equipment.fromMap(Map<String, dynamic> m) => Equipment(
        id: m['id'] as int?,
        name: m['name'] as String,
        rarity: m['rarity'] as String,
        buffDescription: m['buff_description'] as String,
        isEquipped: (m['is_equipped'] as int? ?? 0) == 1,
        isArchived: (m['is_archived'] as int? ?? 0) == 1,
        archivedAt: m['archived_at'] as String? ?? '',
      );

  Equipment copyWith({
    int? id,
    String? name,
    String? rarity,
    String? buffDescription,
    bool? isEquipped,
    bool? isArchived,
    String? archivedAt,
  }) => Equipment(
        id: id ?? this.id,
        name: name ?? this.name,
        rarity: rarity ?? this.rarity,
        buffDescription: buffDescription ?? this.buffDescription,
        isEquipped: isEquipped ?? this.isEquipped,
        isArchived: isArchived ?? this.isArchived,
        archivedAt: archivedAt ?? this.archivedAt,
      );
}
