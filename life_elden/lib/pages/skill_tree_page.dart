import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/elden_theme.dart';
import '../providers/skill_provider.dart';
import '../models/skill.dart';

class SkillTreePage extends StatelessWidget {
  const SkillTreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('技 能 树')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSkillDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: Consumer<SkillProvider>(
        builder: (context, sp, _) {
          final roots = sp.roots;
          if (roots.isEmpty) {
            return const Center(
              child: Text('尚无技能节点，点击 + 创建', style: TextStyle(color: EldenTheme.textDim)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: roots.length,
            itemBuilder: (context, i) => _SkillRootCard(skill: roots[i]),
          );
        },
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context, int? parentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          parentId == null ? '新建根技能' : '新建子技能',
          style: const TextStyle(color: EldenTheme.gold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: EldenTheme.textLight),
          decoration: const InputDecoration(hintText: '技能名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<SkillProvider>().addSkill(controller.text.trim(), parentId);
              }
              Navigator.pop(ctx);
            },
            child: const Text('创建', style: TextStyle(color: EldenTheme.gold)),
          ),
        ],
      ),
    );
  }
}

class _SkillRootCard extends StatefulWidget {
  final Skill skill;
  const _SkillRootCard({required this.skill});

  @override
  State<_SkillRootCard> createState() => _SkillRootCardState();
}

class _SkillRootCardState extends State<_SkillRootCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SkillProvider>();
    final children = sp.childrenOf(widget.skill.id!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: EldenTheme.goldBorderDecoration,
      child: Column(
        children: [
          // Root header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: EldenTheme.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome, size: 20, color: EldenTheme.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.skill.name,
                          style: const TextStyle(
                            color: EldenTheme.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '汇总等级 ${sp.aggregatedLevel(widget.skill.id!)}  ·  汇总经验 ${sp.aggregatedExp(widget.skill.id!)}',
                          style: const TextStyle(color: EldenTheme.textDim, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _LevelBadge(level: widget.skill.level),
                ],
              ),
            ),
          ),
          // Exp bar for root
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SkillExpBar(skill: widget.skill),
          ),
          // Children
          if (_expanded && children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 16, bottom: 12, top: 8),
              child: Column(
                children: children.map((child) => _SkillChildTile(skill: child)).toList(),
              ),
            ),
          // Add child button
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 16, bottom: 12),
              child: InkWell(
                onTap: () => _showAddChildDialog(context, widget.skill.id!),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 16, color: EldenTheme.textDim.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text(
                      '添加子技能',
                      style: TextStyle(color: EldenTheme.textDim.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, int parentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建子技能', style: TextStyle(color: EldenTheme.gold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: EldenTheme.textLight),
          decoration: const InputDecoration(hintText: '技能名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<SkillProvider>().addSkill(controller.text.trim(), parentId);
              }
              Navigator.pop(ctx);
            },
            child: const Text('创建', style: TextStyle(color: EldenTheme.gold)),
          ),
        ],
      ),
    );
  }
}

class _SkillChildTile extends StatelessWidget {
  final Skill skill;
  const _SkillChildTile({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EldenTheme.bgParchment.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EldenTheme.goldDim.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EldenTheme.goldDim,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  skill.name,
                  style: const TextStyle(color: EldenTheme.textLight, fontSize: 14),
                ),
              ),
              _LevelBadge(level: skill.level, small: true),
            ],
          ),
          const SizedBox(height: 6),
          _SkillExpBar(skill: skill, thin: true),
        ],
      ),
    );
  }
}

class _SkillExpBar extends StatelessWidget {
  final Skill skill;
  final bool thin;
  const _SkillExpBar({required this.skill, this.thin = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${skill.currentExp}/${skill.expToNextLevel}',
              style: TextStyle(color: EldenTheme.textDim, fontSize: thin ? 10 : 11),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: thin ? 6 : 10,
            child: Stack(
              children: [
                Container(color: EldenTheme.bgDark),
                FractionallySizedBox(
                  widthFactor: skill.expProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [EldenTheme.goldDim, EldenTheme.gold],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final bool small;
  const _LevelBadge({required this.level, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: EldenTheme.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EldenTheme.gold.withOpacity(0.3)),
      ),
      child: Text(
        'Lv.$level',
        style: TextStyle(
          color: EldenTheme.gold,
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
