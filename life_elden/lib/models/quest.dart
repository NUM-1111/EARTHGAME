class Quest {
  final int? id;
  final String title;
  final String type; // main, side, daily
  final String status; // active, completed
  final int? targetSkillId;
  final int expReward;
  final String? description;

  Quest({
    this.id,
    required this.title,
    required this.type,
    this.status = 'active',
    this.targetSkillId,
    this.expReward = 0,
    this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'status': status,
        'target_skill_id': targetSkillId,
        'exp_reward': expReward,
        'description': description,
      };

  factory Quest.fromMap(Map<String, dynamic> m) => Quest(
        id: m['id'] as int?,
        title: m['title'] as String,
        type: m['type'] as String,
        status: m['status'] as String? ?? 'active',
        targetSkillId: m['target_skill_id'] as int?,
        expReward: m['exp_reward'] as int? ?? 0,
        description: m['description'] as String?,
      );

  Quest copyWith({int? id, String? title, String? type, String? status, int? targetSkillId, int? expReward, String? description}) => Quest(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        status: status ?? this.status,
        targetSkillId: targetSkillId ?? this.targetSkillId,
        expReward: expReward ?? this.expReward,
        description: description ?? this.description,
      );
}
