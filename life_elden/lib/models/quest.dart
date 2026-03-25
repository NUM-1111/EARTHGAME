class Quest {
  final int? id;
  final String title;
  final String type; // main, side, daily
  final String status; // active, completed
  final int? targetSkillId; // gain skill for side
  final int? lossSkillId; // loss skill for side
  final int expReward;
  final String? description;
  final String createdDate; // YYYY-MM-DD
  final String completedDate; // YYYY-MM-DD or ''
  final bool debuffEnabled;
  final int? debuffDueDays; // side: due in N days from created
  final String lastDebuffAppliedDate; // YYYY-MM-DD or ''
  final bool isArchived;
  final String archivedAt; // ISO8601 or ''
  final String? archivedReason; // 'user' | 'skill' | null
  final int? archivedBySkillId; // root skill id that triggered archiving

  Quest({
    this.id,
    required this.title,
    required this.type,
    this.status = 'active',
    this.targetSkillId,
    this.lossSkillId,
    this.expReward = 0,
    this.description,
    this.createdDate = '',
    this.completedDate = '',
    this.debuffEnabled = false,
    this.debuffDueDays,
    this.lastDebuffAppliedDate = '',
    this.isArchived = false,
    this.archivedAt = '',
    this.archivedReason,
    this.archivedBySkillId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'type': type,
        'status': status,
        'target_skill_id': targetSkillId,
        'loss_skill_id': lossSkillId,
        'exp_reward': expReward,
        'description': description,
        'created_date': createdDate,
        'completed_date': completedDate,
        'debuff_enabled': debuffEnabled ? 1 : 0,
        'debuff_due_days': debuffDueDays,
        'last_debuff_applied_date': lastDebuffAppliedDate,
        'is_archived': isArchived ? 1 : 0,
        'archived_at': archivedAt.isEmpty ? null : archivedAt,
        'archived_reason': archivedReason,
        'archived_by_skill_id': archivedBySkillId,
      };

  factory Quest.fromMap(Map<String, dynamic> m) => Quest(
        id: m['id'] as int?,
        title: m['title'] as String,
        type: m['type'] as String,
        status: m['status'] as String? ?? 'active',
        targetSkillId: m['target_skill_id'] as int?,
        lossSkillId: m['loss_skill_id'] as int?,
        expReward: m['exp_reward'] as int? ?? 0,
        description: m['description'] as String?,
        createdDate: m['created_date'] as String? ?? '',
        completedDate: m['completed_date'] as String? ?? '',
        debuffEnabled: (m['debuff_enabled'] as int? ?? 0) == 1,
        debuffDueDays: m['debuff_due_days'] as int?,
        lastDebuffAppliedDate: m['last_debuff_applied_date'] as String? ?? '',
        isArchived: (m['is_archived'] as int? ?? 0) == 1,
        archivedAt: m['archived_at'] as String? ?? '',
        archivedReason: m['archived_reason'] as String?,
        archivedBySkillId: m['archived_by_skill_id'] as int?,
      );

  Quest copyWith({
    int? id,
    String? title,
    String? type,
    String? status,
    int? targetSkillId,
    int? lossSkillId,
    int? expReward,
    String? description,
    String? createdDate,
    String? completedDate,
    bool? debuffEnabled,
    int? debuffDueDays,
    String? lastDebuffAppliedDate,
    bool? isArchived,
    String? archivedAt,
    String? archivedReason,
    int? archivedBySkillId,
  }) => Quest(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        status: status ?? this.status,
        targetSkillId: targetSkillId ?? this.targetSkillId,
        lossSkillId: lossSkillId ?? this.lossSkillId,
        expReward: expReward ?? this.expReward,
        description: description ?? this.description,
        createdDate: createdDate ?? this.createdDate,
        completedDate: completedDate ?? this.completedDate,
        debuffEnabled: debuffEnabled ?? this.debuffEnabled,
        debuffDueDays: debuffDueDays ?? this.debuffDueDays,
        lastDebuffAppliedDate: lastDebuffAppliedDate ?? this.lastDebuffAppliedDate,
        isArchived: isArchived ?? this.isArchived,
        archivedAt: archivedAt ?? this.archivedAt,
        archivedReason: archivedReason ?? this.archivedReason,
        archivedBySkillId: archivedBySkillId ?? this.archivedBySkillId,
      );
}
