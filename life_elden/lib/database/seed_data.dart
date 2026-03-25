/// Seed data for LifeElden initial database population.
class SeedData {
  // ── Skill tree seeds ──
  // IDs are assigned by SQLite auto-increment; parent_id references are
  // resolved by insertion order below.
  static const List<Map<String, dynamic>> skills = [
    // Root nodes (parent_id = null)
    {'id': 1, 'name': 'AI 应用开发', 'parent_id': null, 'current_exp': 0, 'level': 1},
    {'id': 2, 'name': '后端工程', 'parent_id': null, 'current_exp': 0, 'level': 1},
    {'id': 3, 'name': '生存与基础', 'parent_id': null, 'current_exp': 0, 'level': 1},
    // Children of AI 应用开发 (id=1)
    {'id': 4, 'name': 'RAG/Agent 架构', 'parent_id': 1, 'current_exp': 0, 'level': 1},
    {'id': 5, 'name': 'Prompt Engineering', 'parent_id': 1, 'current_exp': 0, 'level': 1},
    {'id': 6, 'name': '模型本地部署', 'parent_id': 1, 'current_exp': 0, 'level': 1},
    // Children of 后端工程 (id=2)
    {'id': 7, 'name': 'Java 核心', 'parent_id': 2, 'current_exp': 0, 'level': 1},
    {'id': 8, 'name': '多租户权限管理架构', 'parent_id': 2, 'current_exp': 0, 'level': 1},
    {'id': 9, 'name': 'SQL 性能优化', 'parent_id': 2, 'current_exp': 0, 'level': 1},
    // Children of 生存与基础 (id=3)
    {'id': 10, 'name': 'Linux 终端命令', 'parent_id': 3, 'current_exp': 0, 'level': 1},
    {'id': 11, 'name': '健康追踪（饮食/睡眠/运动）', 'parent_id': 3, 'current_exp': 0, 'level': 1},
  ];

  // ── Equipment seeds ──
  static const List<Map<String, dynamic>> equipment = [
    {
      'name': 'P8 级大佬的指引',
      'rarity': 'Epic',
      'buff_description': '[面试通关率 +20%]，[技术视野扩展 +50%]',
      'is_equipped': 0,
    },
    {
      'name': '高考 613 的底蕴',
      'rarity': 'Rare',
      'buff_description': '[基础知识学习速度 +10%]',
      'is_equipped': 0,
    },
  ];

  // ── Quest seeds ──
  // target_skill_id references skill IDs above
  static const List<Map<String, dynamic>> quests = [
    {
      'title': '完成 IntelliVault 企业级智能知识库系统核心模块',
      'type': 'main',
      'status': 'active',
      'target_skill_id': 1, // AI 应用开发
      'exp_reward': 500,
      'description': '主线任务：完成核心模块开发，获取大量 AI 应用开发经验。',
    },
    {
      'title': '斩获 Java/AI 后端开发实习 Offer',
      'type': 'main',
      'status': 'active',
      'target_skill_id': 2, // 后端工程
      'exp_reward': 1000,
      'description': '主线任务：角色直接突破当前阶级。',
    },
    {
      'title': '完成 30 分钟 Linux 常见命令实操',
      'type': 'daily',
      'status': 'active',
      'target_skill_id': 10, // Linux 终端命令
      'exp_reward': 10,
      'description': '日常任务：每日 Linux 实操训练。',
    },
    {
      'title': 'C# 传统工业软件实习日常打卡与 SQL 优化实战',
      'type': 'daily',
      'status': 'active',
      'target_skill_id': 9, // SQL 性能优化
      'exp_reward': 15,
      'description': '日常任务：实习打卡 + SQL 优化。',
    },
    {
      'title': '通关一局《文明6》或解决 Minecraft 启动报错',
      'type': 'side',
      'status': 'active',
      'target_skill_id': null,
      'exp_reward': 0,
      'description': '支线任务：精神恢复，消除 [疲惫] 状态。',
    },
  ];

  // ── Character defaults (stored in shared_preferences-like table) ──
  static const Map<String, dynamic> defaultCharacter = {
    'name': 'Jiang Yiwu',
    'total_level': 1,
    'total_exp': 0,
    'title': '无用之人',
  };
}
