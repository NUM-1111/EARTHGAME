import 'package:flutter/material.dart';

/// Elden Ring inspired dark-fantasy theme.
class EldenTheme {
  EldenTheme._();

  // ── Core palette ──
  static const Color bgDark = Color(0xFF1A1410);
  static const Color bgCard = Color(0xFF2A2218);
  static const Color bgParchment = Color(0xFF3A3020);
  static const Color gold = Color(0xFFD4A843);
  static const Color goldBright = Color(0xFFE8C860);
  static const Color goldDim = Color(0xFF8A7030);
  static const Color textLight = Color(0xFFE8DCC8);
  static const Color textDim = Color(0xFF8A7E6A);
  static const Color red = Color(0xFFC04040);
  static const Color green = Color(0xFF5A9A3A);
  static const Color blue = Color(0xFF4A7AB0);
  static const Color purple = Color(0xFF9A5AC0);

  // ── Rarity colors ──
  static Color rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return goldBright;
      case 'epic':
        return purple;
      case 'rare':
        return blue;
      case 'common':
      default:
        return textDim;
    }
  }

  // ── Quest type colors ──
  static Color questTypeColor(String type) {
    switch (type) {
      case 'main':
        return gold;
      case 'side':
        return blue;
      case 'daily':
        return green;
      default:
        return textDim;
    }
  }

  static String questTypeLabel(String type) {
    switch (type) {
      case 'main':
        return '主线';
      case 'side':
        return '支线';
      case 'daily':
        return '日常';
      default:
        return type;
    }
  }

  // ── Decorations ──
  static BoxDecoration get parchmentDecoration => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goldDim.withOpacity(0.4), width: 1),
      );

  static BoxDecoration get goldBorderDecoration => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: gold.withOpacity(0.08), blurRadius: 12, spreadRadius: 1),
        ],
      );

  // ── ThemeData ──
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        primaryColor: gold,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: goldBright,
          surface: bgCard,
          error: red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          foregroundColor: gold,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: goldDim.withOpacity(0.3)),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 1.5),
          headlineMedium: TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1),
          titleLarge: TextStyle(color: textLight, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textLight, fontSize: 15),
          bodyMedium: TextStyle(color: textDim, fontSize: 13),
          labelLarge: TextStyle(color: gold, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: gold, size: 22),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: gold,
          foregroundColor: bgDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgParchment,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: goldDim.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: goldDim.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: gold, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textDim),
          hintStyle: TextStyle(color: textDim.withOpacity(0.6)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: gold.withOpacity(0.4)),
          ),
        ),
      );
}
