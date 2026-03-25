import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/elden_theme.dart';
import '../providers/quest_provider.dart';
import '../providers/character_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/journal_provider.dart';
import '../models/quest_journal.dart';
import '../models/quest.dart';

class QuestPage extends StatelessWidget {
  const QuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('任 务'),
          actions: [
            IconButton(
              tooltip: '已归档任务',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ArchivedQuestPage()),
              ),
              icon: const Icon(Icons.archive),
            ),
          ],
          bottom: TabBar(
            indicatorColor: EldenTheme.gold,
            labelColor: EldenTheme.gold,
            unselectedLabelColor: EldenTheme.textDim,
            tabs: const [
              Tab(text: '主线'),
              Tab(text: '日常'),
              Tab(text: '支线'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddQuestDialog(context),
          child: const Icon(Icons.add),
        ),
        body: Consumer<QuestProvider>(
          builder: (context, qp, _) {
            return TabBarView(
              children: [
                _QuestList(quests: qp.mainQuests, type: 'main'),
                _QuestList(quests: qp.dailyQuests, type: 'daily'),
                _QuestList(quests: qp.sideQuests, type: 'side'),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddQuestDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final expCtrl = TextEditingController(text: '10');
    final dueDaysCtrl = TextEditingController(text: '3');
    String type = 'daily';
    int? targetSkillId;
    int? lossSkillId;
    bool debuffEnabled = true;

    final skills = context.read<SkillProvider>().skills;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('创建任务', style: TextStyle(color: EldenTheme.gold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: EldenTheme.textLight),
                  decoration: const InputDecoration(labelText: '任务标题'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: EldenTheme.bgCard,
                  decoration: const InputDecoration(labelText: '任务类型'),
                  items: [
                    DropdownMenuItem(value: 'main', child: Text('主线', style: TextStyle(color: EldenTheme.questTypeColor('main')))),
                    DropdownMenuItem(value: 'daily', child: Text('日常', style: TextStyle(color: EldenTheme.questTypeColor('daily')))),
                    DropdownMenuItem(value: 'side', child: Text('支线', style: TextStyle(color: EldenTheme.questTypeColor('side')))),
                  ],
                  onChanged: (v) => setDialogState(() {
                    type = v ?? 'daily';
                    // side requires two skills by new rule
                    if (type != 'side') lossSkillId = null;
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  value: targetSkillId,
                  dropdownColor: EldenTheme.bgCard,
                  decoration: InputDecoration(labelText: type == 'side' ? '增益技能（必选）' : '关联技能（可选）'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('无', style: TextStyle(color: EldenTheme.textDim))),
                    ...skills.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, style: const TextStyle(color: EldenTheme.textLight)),
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => targetSkillId = v),
                ),
                if (type == 'side') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int?>(
                    value: lossSkillId,
                    dropdownColor: EldenTheme.bgCard,
                    decoration: const InputDecoration(labelText: '惩罚技能（必选）'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('请选择', style: TextStyle(color: EldenTheme.textDim))),
                      ...skills.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name, style: const TextStyle(color: EldenTheme.textLight)),
                          )),
                    ],
                    onChanged: (v) => setDialogState(() => lossSkillId = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dueDaysCtrl,
                    style: const TextStyle(color: EldenTheme.textLight),
                    decoration: const InputDecoration(labelText: '到期（创建后 N 天）'),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: expCtrl,
                  style: const TextStyle(color: EldenTheme.textLight),
                  decoration: const InputDecoration(labelText: '经验奖励'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: debuffEnabled,
                  onChanged: (v) => setDialogState(() => debuffEnabled = v),
                  activeColor: EldenTheme.gold,
                  title: const Text('未完成触发 Debuff', style: TextStyle(color: EldenTheme.textLight, fontSize: 13)),
                  subtitle: Text(
                    type == 'daily' ? '每天未完成：扣除奖励经验的 50%' : '到期后每天未完成：扣除奖励经验的 50%',
                    style: const TextStyle(color: EldenTheme.textDim, fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: EldenTheme.textLight),
                  decoration: const InputDecoration(labelText: '描述（可选）'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  final exp = int.tryParse(expCtrl.text) ?? 10;
                  final safeExp = exp <= 0 ? 1 : exp;
                  if (type == 'side' && (targetSkillId == null || lossSkillId == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('支线任务需要选择“增益技能”和“惩罚技能”')),
                    );
                    return;
                  }
                  final today = DateTime.now().toIso8601String().substring(0, 10);
                  context.read<QuestProvider>().addQuest(Quest(
                        title: titleCtrl.text.trim(),
                        type: type,
                        targetSkillId: targetSkillId,
                        lossSkillId: lossSkillId,
                        expReward: safeExp,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        createdDate: today,
                        completedDate: '',
                        debuffEnabled: debuffEnabled,
                        debuffDueDays: type == 'side' ? (int.tryParse(dueDaysCtrl.text) ?? 3) : null,
                        lastDebuffAppliedDate: '',
                      ));
                }
                Navigator.pop(ctx);
              },
              child: const Text('创建', style: TextStyle(color: EldenTheme.gold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  final List<Quest> quests;
  final String type;
  const _QuestList({required this.quests, required this.type});

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(
        child: Text(
          '暂无${EldenTheme.questTypeLabel(type)}任务',
          style: const TextStyle(color: EldenTheme.textDim),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quests.length,
      itemBuilder: (context, i) => _QuestCard(quest: quests[i]),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final color = EldenTheme.questTypeColor(quest.type);
    final isCompleted = quest.status == 'completed';
    final qp = context.read<QuestProvider>();
    final streak = qp.streakFor(quest.id ?? -1);

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? EldenTheme.bgDark.withOpacity(0.5) : EldenTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? EldenTheme.textDim.withOpacity(0.2) : color.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    EldenTheme.questTypeLabel(quest.type),
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (streak != null && streak.currentStreak > 0) ...[
                  Icon(Icons.local_fire_department, size: 16, color: Colors.orange.shade400),
                  Text(
                    '${streak.currentStreak}连击',
                    style: TextStyle(color: Colors.orange.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                IconButton(
                  tooltip: '编辑描述',
                  onPressed: () => _editDescription(context, quest),
                  icon: Icon(Icons.edit_note, size: 20, color: EldenTheme.textDim.withOpacity(0.8)),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, size: 18, color: EldenTheme.green)
                else
                  Text(
                    '+${quest.expReward} EXP',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quest.title,
              style: TextStyle(
                color: isCompleted ? EldenTheme.textDim : EldenTheme.textLight,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            if (quest.description != null && quest.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                quest.description!,
                style: TextStyle(color: EldenTheme.textDim.withOpacity(0.7), fontSize: 12),
              ),
            ],
            if (!isCompleted) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _completeQuest(context, quest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    quest.type == 'daily' ? '打卡完成' : '完成任务',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('quest-${quest.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: EldenTheme.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.archive, color: EldenTheme.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('归档任务', style: TextStyle(color: EldenTheme.gold)),
                content: Text('将「${quest.title}」移入已归档？', style: const TextStyle(color: EldenTheme.textLight)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('归档', style: TextStyle(color: EldenTheme.gold)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => qp.archiveQuest(quest.id!),
      child: card,
    );
  }

  Future<void> _completeQuest(BuildContext context, Quest quest) async {
    final qp = context.read<QuestProvider>();
    final cp = context.read<CharacterProvider>();
    final sp = context.read<SkillProvider>();
    final jp = context.read<JournalProvider>();

    if (quest.type == 'side') {
      // Side quests: same as others (no judgement dialog).
      final reward = await qp.completeQuest(quest.id!);
      await cp.addExp(reward);
      if (quest.targetSkillId != null) {
        await sp.addExpToSkill(quest.targetSkillId!, reward);
      }
      await jp.upsert(QuestJournal(
        questId: quest.id!,
        logDate: DateTime.now().toIso8601String().substring(0, 10),
        completed: true,
        expDelta: reward,
        reason: 'complete',
        createdAt: DateTime.now().toIso8601String(),
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EldenTheme.bgCard,
            content: Text(
              '支线完成：获得 $reward 经验！',
              style: const TextStyle(color: EldenTheme.textLight),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final reward = await qp.completeQuest(quest.id!);

    // Add exp to character
    await cp.addExp(reward);

    // Add exp to target skill if set
    if (quest.targetSkillId != null) {
      await sp.addExpToSkill(quest.targetSkillId!, reward);
    }

    await jp.upsert(QuestJournal(
      questId: quest.id!,
      logDate: DateTime.now().toIso8601String().substring(0, 10),
      completed: true,
      expDelta: reward,
      reason: 'complete',
      createdAt: DateTime.now().toIso8601String(),
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: EldenTheme.bgCard,
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: EldenTheme.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                '获得 $reward 经验！',
                style: const TextStyle(color: EldenTheme.gold, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: EldenTheme.gold.withOpacity(0.3)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _editDescription(BuildContext context, Quest quest) {
    final ctrl = TextEditingController(text: quest.description ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑任务描述', style: TextStyle(color: EldenTheme.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('任务：${quest.title}', style: const TextStyle(color: EldenTheme.textDim, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: EldenTheme.textLight),
              decoration: const InputDecoration(labelText: '描述（可选）'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              await context.read<QuestProvider>().updateQuestDescription(
                    quest.id!,
                    text.isEmpty ? null : text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存', style: TextStyle(color: EldenTheme.gold)),
          ),
        ],
      ),
    );
  }
}

class ArchivedQuestPage extends StatelessWidget {
  const ArchivedQuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('已归档任务')),
      body: Consumer<QuestProvider>(
        builder: (context, qp, _) {
          final list = qp.archivedItems;
          if (list.isEmpty) {
            return const Center(
              child: Text('暂无已归档任务', style: TextStyle(color: EldenTheme.textDim)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) => _ArchivedQuestTile(quest: list[i]),
          );
        },
      ),
    );
  }
}

class _ArchivedQuestTile extends StatelessWidget {
  final Quest quest;
  const _ArchivedQuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    final qp = context.read<QuestProvider>();
    final color = EldenTheme.questTypeColor(quest.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EldenTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: ListTile(
        title: Text(quest.title, style: const TextStyle(color: EldenTheme.textLight)),
        subtitle: Text(
          '${EldenTheme.questTypeLabel(quest.type)}  ·  ${quest.status == 'completed' ? '已完成' : '进行中'}',
          style: const TextStyle(color: EldenTheme.textDim, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () => qp.restoreQuest(quest.id!),
              icon: const Icon(Icons.unarchive, size: 18),
              label: const Text('恢复'),
            ),
            IconButton(
              tooltip: '彻底删除（不可恢复）',
              icon: Icon(Icons.delete_forever, size: 18, color: EldenTheme.red.withOpacity(0.9)),
              onPressed: () async {
                final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('彻底删除任务', style: TextStyle(color: EldenTheme.gold)),
                        content: Text(
                          '将「${quest.title}」从数据中永久删除？将同时清理该任务的日志与日常连击记录。',
                          style: const TextStyle(color: EldenTheme.textLight),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('彻底删除', style: TextStyle(color: EldenTheme.gold)),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!ok) return;

                final deleted = await qp.purgeQuest(quest.id!);
                if (!context.mounted) return;
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: EldenTheme.bgCard,
                      content: const Text('任务已彻底删除'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
