import 'package:flutter/material.dart';

/// Semantic theme colors supporting iOS 27 Light, Dark, and Liquid Glass surfaces.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color card;
  final Color glassTint;
  final Color glassBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color separator;
  final Color accent;
  final Color accentSoft;
  final Color accentBadge;
  final Color gold;
  final Color goldSoft;
  final Color paperBg;
  final Color inputFill;

  const AppColors({
    required this.bg,
    required this.card,
    required this.glassTint,
    required this.glassBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.separator,
    required this.accent,
    required this.accentSoft,
    required this.accentBadge,
    required this.gold,
    required this.goldSoft,
    required this.paperBg,
    required this.inputFill,
  });

  static const AppColors light = AppColors(
    bg: Color(0xFFF3F5F4),
    card: Color(0xFFFFFFFF),
    glassTint: Color(0xCCFFFFFF),
    glassBorder: Color(0x22000000),
    textPrimary: Color(0xFF141816),
    textSecondary: Color(0xFF5D6660),
    textTertiary: Color(0xFF9AA39D),
    separator: Color(0x14000000),
    accent: Color(0xFF1A5C28),
    accentSoft: Color(0xFFE8F5EC),
    accentBadge: Color(0xFFC8E6CF),
    gold: Color(0xFF9A7B2C),
    goldSoft: Color(0xFFFDF6E2),
    paperBg: Color(0xFFFAF8F2),
    inputFill: Color(0xFFEBEEEC),
  );

  static const AppColors dark = AppColors(
    bg: Color(0xFF0E1210),
    card: Color(0xFF181E1A),
    glassTint: Color(0xC81C2420),
    glassBorder: Color(0x28FFFFFF),
    textPrimary: Color(0xFFF2F5F3),
    textSecondary: Color(0xFFA6B2AA),
    textTertiary: Color(0xFF6F7B73),
    separator: Color(0x1FFFFFFF),
    accent: Color(0xFF45A85C),
    accentSoft: Color(0xFF1B3322),
    accentBadge: Color(0xFF23472C),
    gold: Color(0xFFD8B858),
    goldSoft: Color(0xFF2A2414),
    paperBg: Color(0xFF171612),
    inputFill: Color(0xFF222A25),
  );

  static AppColors of(BuildContext context) {
    final ext = Theme.of(context).extension<AppColors>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  @override
  AppColors copyWith({
    Color? bg,
    Color? card,
    Color? glassTint,
    Color? glassBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? separator,
    Color? accent,
    Color? accentSoft,
    Color? accentBadge,
    Color? gold,
    Color? goldSoft,
    Color? paperBg,
    Color? inputFill,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      separator: separator ?? this.separator,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentBadge: accentBadge ?? this.accentBadge,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      paperBg: paperBg ?? this.paperBg,
      inputFill: inputFill ?? this.inputFill,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentBadge: Color.lerp(accentBadge, other.accentBadge, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      paperBg: Color.lerp(paperBg, other.paperBg, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

class AppTheme {
  static const Color green = Color(0xFF1A5C28);
  static const Color greenLight = Color(0xFF2D7A40);
  static const Color greenPale = Color(0xFFE8F5EC);
  static const Color greenBadge = Color(0xFFC8E6CF);
  static const Color bg = Color(0xFFF3F5F4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF141816);
  static const Color textSecondary = Color(0xFF5D6660);
  static const Color textTertiary = Color(0xFF9AA39D);
  static const Color separator = Color(0x14000000);
  static const Color errorRed = Color(0xFFC0392B);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFDF6E2);
  static const Color goldBorder = Color(0x33D4AF37);

  static const String arabicFontFamily = 'ScheherazadeNew';
  static const String uiFontFamily = 'NotoSansArabic';

  static final RegExp _arabicScriptRegExp = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  /// Returns true if [text] contains any Arabic/Urdu script characters.
  static bool containsArabic(String text) => _arabicScriptRegExp.hasMatch(text);

  /// Shared text style helper for all Arabic and Urdu script text.
  ///
  /// Uses the bundled offline calligraphic Naskh TTF font (Scheherazade New)
  /// and enforces `letterSpacing: 0` so cursive Arabic/Urdu letters connect
  /// cleanly with no inter-letter gaps.
  static TextStyle arabicTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: arabicFontFamily,
      fontFamilyFallback: const [uiFontFamily, 'NotoEmoji'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: 0,
    );
  }

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: uiFontFamily,
    fontFamilyFallback: const [arabicFontFamily, 'NotoEmoji', 'Arial', 'Roboto'],
    extensions: const [AppColors.light],
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
      primary: green,
      surface: AppColors.light.bg,
    ),
    scaffoldBackgroundColor: AppColors.light.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.light.card,
      foregroundColor: AppColors.light.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: const [arabicFontFamily, 'NotoEmoji'],
        color: AppColors.light.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.light.card,
      selectedItemColor: green,
      unselectedItemColor: AppColors.light.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.light.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.light.separator),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: uiFontFamily,
    fontFamilyFallback: const [arabicFontFamily, 'NotoEmoji', 'Arial', 'Roboto'],
    extensions: const [AppColors.dark],
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.dark.accent,
      brightness: Brightness.dark,
      primary: AppColors.dark.accent,
      surface: AppColors.dark.bg,
    ),
    scaffoldBackgroundColor: AppColors.dark.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.dark.card,
      foregroundColor: AppColors.dark.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: uiFontFamily,
        fontFamilyFallback: const [arabicFontFamily, 'NotoEmoji'],
        color: AppColors.dark.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.dark.card,
      selectedItemColor: AppColors.dark.accent,
      unselectedItemColor: AppColors.dark.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.dark.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.dark.separator),
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

  static IconData getIcon(String key) {
    switch (key) {
      case 'nouhay':
        return Icons.nights_stay_rounded;
      case 'nouhaDarHaal':
        return Icons.water_drop_rounded;
      case 'marsias':
        return Icons.menu_book_rounded;
      case 'manqabat':
        return Icons.star_rounded;
      case 'qasiday':
        return Icons.wb_sunny_rounded;
      case 'duas':
        return Icons.auto_stories_rounded;
      case 'salaam':
        return Icons.front_hand_rounded;
      case 'munaejaat':
        return Icons.spa_rounded;
      case 'ziyaraat':
        return Icons.place_rounded;
      case 'oldNouhay':
        return Icons.history_edu_rounded;
      case 'urduMarsiye':
        return Icons.library_books_rounded;
      default:
        return Icons.book_rounded;
    }
  }
}
