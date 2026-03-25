import 'package:flutter/material.dart';
import 'theme/elden_theme.dart';
import 'pages/home_page.dart';
import 'pages/skill_tree_page.dart';
import 'pages/equipment_page.dart';
import 'pages/quest_page.dart';

class LifeEldenApp extends StatelessWidget {
  const LifeEldenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeElden',
      debugShowCheckedModeBanner: false,
      theme: EldenTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    SkillTreePage(),
    EquipmentPage(),
    QuestPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: EldenTheme.gold.withOpacity(0.1),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: EldenTheme.bgDark,
          selectedItemColor: EldenTheme.gold,
          unselectedItemColor: EldenTheme.textDim,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '角色'),
            BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: '技能树'),
            BottomNavigationBarItem(icon: Icon(Icons.shield), label: '装备'),
            BottomNavigationBarItem(icon: Icon(Icons.flag), label: '任务'),
          ],
        ),
      ),
    );
  }
}
