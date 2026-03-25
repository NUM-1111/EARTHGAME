class StreakLog {
  final int? id;
  final int questId;
  final String lastCompletedDate; // ISO 8601 date string
  final int currentStreak;
  final String lastDebuffAppliedDate; // ISO 8601 date string

  StreakLog({
    this.id,
    required this.questId,
    required this.lastCompletedDate,
    this.currentStreak = 0,
    this.lastDebuffAppliedDate = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'quest_id': questId,
        'last_completed_date': lastCompletedDate,
        'current_streak': currentStreak,
        'last_debuff_applied_date': lastDebuffAppliedDate,
      };

  factory StreakLog.fromMap(Map<String, dynamic> m) => StreakLog(
        id: m['id'] as int?,
        questId: m['quest_id'] as int,
        lastCompletedDate: m['last_completed_date'] as String,
        currentStreak: m['current_streak'] as int? ?? 0,
        lastDebuffAppliedDate: m['last_debuff_applied_date'] as String? ?? '',
      );

  StreakLog copyWith({int? id, int? questId, String? lastCompletedDate, int? currentStreak, String? lastDebuffAppliedDate}) => StreakLog(
        id: id ?? this.id,
        questId: questId ?? this.questId,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
        currentStreak: currentStreak ?? this.currentStreak,
        lastDebuffAppliedDate: lastDebuffAppliedDate ?? this.lastDebuffAppliedDate,
      );
}
