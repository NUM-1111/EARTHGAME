class Skill {
  final int? id;
  final String name;
  final int? parentId;
  final String description;
  final int currentExp;
  final int level;

  Skill({
    this.id,
    required this.name,
    this.parentId,
    this.description = '',
    this.currentExp = 0,
    this.level = 1,
  });

  /// Experience needed to reach next level: 100 * currentLevel
  int get expToNextLevel => 100 * level;

  double get expProgress => currentExp / expToNextLevel;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'description': description,
        'current_exp': currentExp,
        'level': level,
      };

  factory Skill.fromMap(Map<String, dynamic> m) => Skill(
        id: m['id'] as int?,
        name: m['name'] as String,
        parentId: m['parent_id'] as int?,
        description: m['description'] as String? ?? '',
        currentExp: m['current_exp'] as int? ?? 0,
        level: m['level'] as int? ?? 1,
      );

  Skill copyWith({int? id, String? name, int? parentId, String? description, int? currentExp, int? level}) => Skill(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId ?? this.parentId,
        description: description ?? this.description,
        currentExp: currentExp ?? this.currentExp,
        level: level ?? this.level,
      );
}
