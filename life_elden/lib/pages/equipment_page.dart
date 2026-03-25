import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/elden_theme.dart';
import '../providers/equipment_provider.dart';
import '../models/equipment.dart';

class EquipmentPage extends StatelessWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('装 备 库')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<EquipmentProvider>(
        builder: (context, ep, _) {
          if (ep.items.isEmpty) {
            return const Center(
              child: Text('背包空空如也，点击 + 录入资源', style: TextStyle(color: EldenTheme.textDim)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ep.items.length,
            itemBuilder: (context, i) => _EquipmentCard(equipment: ep.items[i]),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final buffCtrl = TextEditingController();
    String rarity = 'Common';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('录入新装备', style: TextStyle(color: EldenTheme.gold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: EldenTheme.textLight),
                  decoration: const InputDecoration(labelText: '装备名称'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: rarity,
                  dropdownColor: EldenTheme.bgCard,
                  decoration: const InputDecoration(labelText: '稀有度'),
                  items: ['Common', 'Rare', 'Epic', 'Legendary']
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: TextStyle(color: EldenTheme.rarityColor(r))),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => rarity = v ?? 'Common'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: buffCtrl,
                  style: const TextStyle(color: EldenTheme.textLight),
                  decoration: const InputDecoration(
                    labelText: '词条/Buff 描述',
                    hintText: '例：[学习速度 +10%]',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  context.read<EquipmentProvider>().addEquipment(Equipment(
                        name: nameCtrl.text.trim(),
                        rarity: rarity,
                        buffDescription: buffCtrl.text.trim(),
                      ));
                }
                Navigator.pop(ctx);
              },
              child: const Text('录入', style: TextStyle(color: EldenTheme.gold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  const _EquipmentCard({required this.equipment});

  String _rarityLabel(String rarity) {
    switch (rarity) {
      case 'Legendary':
        return '传说';
      case 'Epic':
        return '史诗';
      case 'Rare':
        return '稀有';
      default:
        return '普通';
    }
  }

  IconData _rarityIcon(String rarity) {
    switch (rarity) {
      case 'Legendary':
        return Icons.star;
      case 'Epic':
        return Icons.diamond;
      case 'Rare':
        return Icons.auto_awesome;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = EldenTheme.rarityColor(equipment.rarity);
    final ep = context.read<EquipmentProvider>();

    return Dismissible(
      key: ValueKey(equipment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: EldenTheme.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: EldenTheme.red),
      ),
      onDismissed: (_) => ep.deleteEquipment(equipment.id!),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: EldenTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 8),
          ],
        ),
        child: InkWell(
          onTap: () => ep.toggleEquip(equipment.id!),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_rarityIcon(equipment.rarity), size: 20, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        equipment.name,
                        style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Rarity badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        _rarityLabel(equipment.rarity),
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (equipment.buffDescription.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EldenTheme.bgDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      equipment.buffDescription,
                      style: const TextStyle(color: EldenTheme.goldBright, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      equipment.isEquipped ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: equipment.isEquipped ? EldenTheme.green : EldenTheme.textDim,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      equipment.isEquipped ? '已装备' : '未装备',
                      style: TextStyle(
                        color: equipment.isEquipped ? EldenTheme.green : EldenTheme.textDim,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
