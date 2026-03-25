import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/elden_theme.dart';
import '../providers/character_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/quest_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/journal_provider.dart';
import 'log_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('L I F E  E L D E N'),
        actions: [
          IconButton(
            tooltip: '菜单',
            icon: const Icon(Icons.apps),
            onPressed: () => _openTopRightMenu(context),
          ),
        ],
      ),
      body: Consumer<CharacterProvider>(
        builder: (context, char, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // ── Avatar section ──
                _AvatarSection(char: char),
                const SizedBox(height: 20),
                // ── Status card ──
                _StatusCard(char: char),
                const SizedBox(height: 16),
                // ── Exp bar ──
                _ExpBar(char: char),
                const SizedBox(height: 20),
                // ── Skill overview ──
                _SkillOverview(),
                const SizedBox(height: 16),
                // ── Equipped equipment buffs ──
                const _EquippedEquipmentBuffs(),
                const SizedBox(height: 16),
                // ── Active buffs ──
                _BuffSection(char: char),
                const SizedBox(height: 16),
                // ── Current main quest ──
                const _CurrentMainQuestCard(),
                const SizedBox(height: 16),
                // ── Quick quest summary ──
                _QuestSummary(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openTopRightMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EldenTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.read<JournalProvider>().loadLastDays(30);
                        if (context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LogPage()));
                        }
                      },
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('日志'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar with phase-based visual ───
class _AvatarSection extends StatelessWidget {
  final CharacterProvider char;
  const _AvatarSection({required this.char});

  IconData _phaseIcon() {
    if (char.totalLevel >= 30) return Icons.shield;
    if (char.totalLevel >= 11) return Icons.directions_walk;
    return Icons.person_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: EldenTheme.goldBorderDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Phase-based avatar placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  EldenTheme.gold.withOpacity(0.3),
                  EldenTheme.bgDark,
                ],
              ),
              border: Border.all(color: EldenTheme.gold.withOpacity(0.6), width: 2),
            ),
            child: Icon(
              _phaseIcon(),
              size: 56,
              color: EldenTheme.gold,
            ),
          ),
          const SizedBox(height: 12),
          // Phase title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: EldenTheme.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EldenTheme.gold.withOpacity(0.3)),
            ),
            child: Text(
              char.phase,
              style: const TextStyle(
                color: EldenTheme.goldBright,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status card ───
class _StatusCard extends StatelessWidget {
  final CharacterProvider char;
  const _StatusCard({required this.char});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: EldenTheme.parchmentDecoration,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _editName(context, char),
                  child: Row(
                    children: [
                      Text(
                        char.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit, size: 16, color: EldenTheme.textDim.withOpacity(0.6)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${char.title}  ·  Lv.${char.totalLevel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Level badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: EldenTheme.gold, width: 2),
              color: EldenTheme.bgDark,
            ),
            alignment: Alignment.center,
            child: Text(
              '${char.totalLevel}',
              style: const TextStyle(
                color: EldenTheme.gold,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context, CharacterProvider char) {
    final controller = TextEditingController(text: char.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改角色名', style: TextStyle(color: EldenTheme.gold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: EldenTheme.textLight),
          decoration: const InputDecoration(hintText: '输入新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                char.updateName(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('确认', style: TextStyle(color: EldenTheme.gold)),
          ),
        ],
      ),
    );
  }
}

// ─── Experience bar ───
class _ExpBar extends StatelessWidget {
  final CharacterProvider char;
  const _ExpBar({required this.char});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: EldenTheme.parchmentDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('经验值', style: TextStyle(color: EldenTheme.textDim, fontSize: 12)),
              Text(
                '${char.totalExp} / ${char.expToNextLevel}',
                style: const TextStyle(color: EldenTheme.gold, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: EldenTheme.bgDark,
                      border: Border.all(color: EldenTheme.goldDim.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: char.expProgress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [EldenTheme.goldDim, EldenTheme.gold, EldenTheme.goldBright],
                        ),
                        boxShadow: [
                          BoxShadow(color: EldenTheme.gold.withOpacity(0.4), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '距离下一级还需 ${char.expToNextLevel - char.totalExp} 经验',
            style: TextStyle(color: EldenTheme.textDim.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Skill overview (top-level roots) ───
class _SkillOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SkillProvider>(
      builder: (context, sp, _) {
        final roots = sp.roots;
        if (roots.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: EldenTheme.parchmentDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('技能概览', style: TextStyle(color: EldenTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...roots.map((root) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: EldenTheme.goldDim),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(root.name, style: const TextStyle(color: EldenTheme.textLight, fontSize: 14)),
                        ),
                        Text(
                          'Lv.${root.level}',
                          style: const TextStyle(color: EldenTheme.gold, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

// ─── Active buffs ───
class _BuffSection extends StatelessWidget {
  final CharacterProvider char;
  const _BuffSection({required this.char});

  @override
  Widget build(BuildContext context) {
    // Check streak-based buffs from quest provider
    return Consumer<QuestProvider>(
      builder: (context, qp, _) {
        final activeStreaks = qp.streakLogs.where((s) => s.currentStreak >= 7).toList();
        if (activeStreaks.isEmpty && char.activeBuffs.isEmpty) {
          return Container(
            decoration: EldenTheme.parchmentDecoration,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: EldenTheme.textDim.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  '暂无激活的 Buff — 坚持日常任务以触发增益',
                  style: TextStyle(color: EldenTheme.textDim.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          );
        }
        return Container(
          decoration: EldenTheme.goldBorderDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department, size: 18, color: EldenTheme.goldBright),
                  SizedBox(width: 6),
                  Text('激活 Buff', style: TextStyle(color: EldenTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              if (activeStreaks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EldenTheme.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🌳 黄金树的庇护 — 经验获取倍率 ×1.5',
                    style: TextStyle(color: EldenTheme.goldBright, fontSize: 13),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Quick quest summary ───
class _QuestSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuestProvider>(
      builder: (context, qp, _) {
        final active = qp.activeQuests;
        final dailies = qp.dailyQuests;
        return Container(
          decoration: EldenTheme.parchmentDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('任务概况', style: TextStyle(color: EldenTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _summaryRow('进行中', '${active.length}', EldenTheme.gold),
              _summaryRow('日常任务', '${dailies.length}', EldenTheme.green),
              _summaryRow('已完成', '${qp.quests.where((q) => q.status == 'completed').length}', EldenTheme.textDim),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: EldenTheme.textDim, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EquippedEquipmentBuffs extends StatelessWidget {
  const _EquippedEquipmentBuffs();

  @override
  Widget build(BuildContext context) {
    return Consumer<EquipmentProvider>(
      builder: (context, ep, _) {
        final equipped = ep.equipped;
        if (equipped.isEmpty) {
          return Container(
            decoration: EldenTheme.parchmentDecoration,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: EldenTheme.textDim.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  '未装备任何道具 — 去装备页点一下即可装备',
                  style: TextStyle(color: EldenTheme.textDim.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: EldenTheme.goldBorderDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield, size: 18, color: EldenTheme.goldBright),
                  SizedBox(width: 6),
                  Text('装备增益', style: TextStyle(color: EldenTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              ...equipped.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EldenTheme.bgDark.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: EldenTheme.goldDim.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: const TextStyle(color: EldenTheme.textLight, fontWeight: FontWeight.w600)),
                          if (e.buffDescription.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(e.buffDescription, style: const TextStyle(color: EldenTheme.goldBright, fontSize: 12, height: 1.4)),
                          ],
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentMainQuestCard extends StatelessWidget {
  const _CurrentMainQuestCard();

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuestProvider, SkillProvider>(
      builder: (context, qp, sp, _) {
        final activeMain = qp.mainQuests.where((q) => q.status == 'active').toList();
        if (activeMain.isEmpty) {
          return Container(
            decoration: EldenTheme.parchmentDecoration,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 16, color: EldenTheme.textDim.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  '当前没有进行中的主线任务',
                  style: TextStyle(color: EldenTheme.textDim.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          );
        }

        final q = activeMain.first;
        final skillName = q.targetSkillId == null ? null : sp.byId(q.targetSkillId!)?.name;

        return Container(
          decoration: EldenTheme.parchmentDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('当前主线', style: TextStyle(color: EldenTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(q.title, style: const TextStyle(color: EldenTheme.textLight, fontSize: 14, fontWeight: FontWeight.w600)),
              if (q.targetSkillId != null) ...[
                const SizedBox(height: 6),
                Text(
                  '关联技能：${skillName ?? '已删除/不可用'}',
                  style: const TextStyle(color: EldenTheme.textDim, fontSize: 12),
                ),
              ],
              if (q.description != null && q.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(q.description!, style: TextStyle(color: EldenTheme.textDim.withOpacity(0.75), fontSize: 12, height: 1.35)),
              ],
            ],
          ),
        );
      },
    );
  }
}
