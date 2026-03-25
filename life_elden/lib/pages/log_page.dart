import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/elden_theme.dart';
import '../providers/journal_provider.dart';
import '../providers/quest_provider.dart';
import '../models/quest_journal.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('值 日 · 日 志')),
      body: Consumer2<JournalProvider, QuestProvider>(
        builder: (context, jp, qp, _) {
          final questTitle = <int, String>{
            for (final q in qp.quests)
              if (q.id != null) q.id!: q.title,
          };
          final grouped = <String, List<QuestJournal>>{};
          for (final j in jp.items) {
            (grouped[j.logDate] ??= []).add(j);
          }
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          if (dates.isEmpty) {
            return const Center(
              child: Text('暂无日志（仅保留最近 30 天）', style: TextStyle(color: EldenTheme.textDim)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dates.length,
            itemBuilder: (context, i) {
              final date = dates[i];
              final items = grouped[date]!..sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final sum = items.fold<int>(0, (acc, x) => acc + x.expDelta);
              final sumColor = sum >= 0 ? EldenTheme.green : EldenTheme.red;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: EldenTheme.parchmentDecoration,
                child: ExpansionTile(
                  collapsedIconColor: EldenTheme.textDim,
                  iconColor: EldenTheme.gold,
                  title: Row(
                    children: [
                      Expanded(child: Text(date, style: const TextStyle(color: EldenTheme.textLight, fontWeight: FontWeight.w600))),
                      Text(
                        sum >= 0 ? '+$sum' : '$sum',
                        style: TextStyle(color: sumColor, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  children: [
                    const Divider(height: 1, color: EldenTheme.bgDark),
                    ...items.map((j) {
                      final title = questTitle[j.questId] ?? '任务 #${j.questId}';
                      final deltaColor = j.expDelta >= 0 ? EldenTheme.green : EldenTheme.red;
                      final deltaText = j.expDelta >= 0 ? '+${j.expDelta}' : '${j.expDelta}';
                      final tag = j.completed ? '完成' : '未完成';
                      final tagColor = j.completed ? EldenTheme.green : EldenTheme.red;

                      return ListTile(
                        dense: true,
                        title: Text(title, style: const TextStyle(color: EldenTheme.textLight, fontSize: 13)),
                        subtitle: Text(j.reason, style: const TextStyle(color: EldenTheme.textDim, fontSize: 11)),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tagColor.withOpacity(0.35)),
                          ),
                          child: Text(tag, style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        trailing: Text(deltaText, style: TextStyle(color: deltaColor, fontWeight: FontWeight.w700)),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

