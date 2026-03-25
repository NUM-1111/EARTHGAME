class QuestJournal {
  final int? id;
  final int questId;
  final String logDate; // YYYY-MM-DD
  final bool completed;
  final int expDelta;
  final String reason; // miss|overdue|complete_success|complete_no_harvest|complete
  final String createdAt; // ISO string

  QuestJournal({
    this.id,
    required this.questId,
    required this.logDate,
    required this.completed,
    required this.expDelta,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'quest_id': questId,
        'log_date': logDate,
        'completed': completed ? 1 : 0,
        'exp_delta': expDelta,
        'reason': reason,
        'created_at': createdAt,
      };

  factory QuestJournal.fromMap(Map<String, dynamic> m) => QuestJournal(
        id: m['id'] as int?,
        questId: m['quest_id'] as int,
        logDate: m['log_date'] as String,
        completed: (m['completed'] as int? ?? 0) == 1,
        expDelta: m['exp_delta'] as int? ?? 0,
        reason: m['reason'] as String? ?? '',
        createdAt: m['created_at'] as String? ?? '',
      );
}

