import 'package:flutter/material.dart';

class AppTheme {
  static const Color green = Color(0xFF1A5C28);
  static const Color greenLight = Color(0xFF2D7A40);
  static const Color greenPale = Color(0xFFE8F5EC);
  static const Color greenBadge = Color(0xFFC8E6CF);
  static const Color bg = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFFAAAAAA);
  static const Color separator = Color(0x0F000000);
  static const Color errorRed = Color(0xFFC0392B);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: bg,
    ),
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: card,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: green,
      unselectedItemColor: textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
    ),
  );
}

class AppCategories {
  static const List<Map<String, String>> all = [
    {'key': 'nouhay',       'label': 'Nouhay',              'icon': '🌙'},
    {'key': 'nouhaDarHaal', 'label': 'Nouha Dar Haal',       'icon': '💧'},
    {'key': 'marsias',      'label': 'Marsias',              'icon': '📜'},
    {'key': 'manqabat',     'label': 'Manqabat',             'icon': '⭐'},
    {'key': 'qasiday',      'label': 'Qasiday',              'icon': '🕌'},
    {'key': 'duas',         'label': 'Dua & Amal',           'icon': '🤲'},
    {'key': 'salaam',       'label': 'Salaam',               'icon': '✋'},
    {'key': 'munaejaat',    'label': 'Munaejaat',            'icon': '🌹'},
    {'key': 'ziyaraat',     'label': 'Ziyaraat',             'icon': '🕋'},
    {'key': 'oldNouhay',    'label': 'Bayazi Nouhay',        'icon': '📻'},
    {'key': 'urduMarsiye',  'label': 'Urdu Marsiye (مرثی)', 'icon': '📖'},
  ];

  static Map<String, String>? forKey(String key) {
    try {
      return all.firstWhere((c) => c['key'] == key);
    } catch (_) {
      return null;
    }
  }
}
