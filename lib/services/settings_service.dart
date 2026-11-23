import 'package:flutter/material.dart';
import 'database_service.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  double ltrFontSize = 17;
  double rtlFontSize = 22;
  double arabicFontSize = 26;
  double paraSpacing = 4;
  double lineHeight = 1.9;
  bool dailyRemindersEnabled = true;
  ThemeMode themeMode = ThemeMode.system;
  String readerSurface = 'paper'; // 'paper' | 'light' | 'dark'

  Future<void> load() async {
    final db = DatabaseService.instance;
    ltrFontSize = double.tryParse(await db.getSetting('ltr_font_size') ?? '') ?? 17;
    rtlFontSize = double.tryParse(await db.getSetting('rtl_font_size') ?? '') ?? 22;
    arabicFontSize = double.tryParse(await db.getSetting('arabic_font_size') ?? '') ?? 26;
    paraSpacing = double.tryParse(await db.getSetting('para_spacing') ?? '') ?? 4;
    lineHeight = double.tryParse(await db.getSetting('line_height') ?? '') ?? 1.9;
    final remVal = await db.getSetting('daily_reminders_enabled');
    dailyRemindersEnabled = remVal == null || remVal == 'true';
    themeMode = _parseThemeMode(await db.getSetting('theme_mode'));
    readerSurface = await db.getSetting('reader_surface') ?? 'paper';
    notifyListeners();
  }

  Future<void> save() async {
    final db = DatabaseService.instance;
    await db.setSetting('ltr_font_size', ltrFontSize.toString());
    await db.setSetting('rtl_font_size', rtlFontSize.toString());
    await db.setSetting('arabic_font_size', arabicFontSize.toString());
    await db.setSetting('para_spacing', paraSpacing.toString());
    await db.setSetting('line_height', lineHeight.toString());
    await db.setSetting('daily_reminders_enabled', dailyRemindersEnabled.toString());
    await db.setSetting('theme_mode', _serializeThemeMode(themeMode));
    await db.setSetting('reader_surface', readerSurface);
    notifyListeners();
  }

  Future<void> reset() async {
    ltrFontSize = 17;
    rtlFontSize = 22;
    arabicFontSize = 26;
    paraSpacing = 4;
    lineHeight = 1.9;
    dailyRemindersEnabled = true;
    themeMode = ThemeMode.system;
    readerSurface = 'paper';
    await save();
  }

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
