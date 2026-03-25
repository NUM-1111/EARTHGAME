import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/elden_theme.dart';
import '../providers/quest_provider.dart';
import '../providers/character_provider.dart';
import '../providers/skill_provider.dart';
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
    String type = 'daily';
    int? targetSkillId;

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
                  onChanged: (v) => setDialogState(() => type = v ?? 'daily'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  value: targetSkillId,
                  dropdownColor: EldenTheme.bgCard,
                  decoration: const InputDecoration(labelText: '关联技能（可选）'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('无', style: TextStyle(color: EldenTheme.textDim))),
                    ...skills.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, style: const TextStyle(color: EldenTheme.textLight)),
                        )),
                  ],
                  onChanged: (v) => setDialogState(() => targetSkillId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: expCtrl,
                  style: const TextStyle(color: EldenTheme.textLight),
                  decoration: const InputDecoration(labelText: '经验奖励'),
                  keyboardType: TextInputType.number,
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
                  context.read<QuestProvider>().addQuest(Quest(
                        title: titleCtrl.text.trim(),
                        type: type,
                        targetSkillId: targetSkillId,
                        expReward: int.tryParse(expCtrl.text) ?? 10,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
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

    return Container(
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
  }

  Future<void> _completeQuest(BuildContext context, Quest quest) async {
    final qp = context.read<QuestProvider>();
    final cp = context.read<CharacterProvider>();
    final sp = context.read<SkillProvider>();

    final reward = await qp.completeQuest(quest.id!);

    // Add exp to character
    await cp.addExp(reward);

    // Add exp to target skill if set
    if (quest.targetSkillId != null) {
      await sp.addExpToSkill(quest.targetSkillId!, reward);
    }

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
}
