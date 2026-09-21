import 'package:flutter/foundation.dart';
import 'database_service.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  double ltrFontSize    = 17;
  double rtlFontSize    = 22;
  double arabicFontSize = 26;
  double paraSpacing    = 4;
  double lineHeight     = 1.9;
  bool dailyRemindersEnabled = true;

  Future<void> load() async {
    final db = DatabaseService.instance;
    ltrFontSize           = double.tryParse(await db.getSetting('ltr_font_size')    ?? '') ?? 17;
    rtlFontSize           = double.tryParse(await db.getSetting('rtl_font_size')    ?? '') ?? 22;
    arabicFontSize        = double.tryParse(await db.getSetting('arabic_font_size') ?? '') ?? 26;
    paraSpacing           = double.tryParse(await db.getSetting('para_spacing')     ?? '') ?? 4;
    lineHeight            = double.tryParse(await db.getSetting('line_height')      ?? '') ?? 1.9;
    final remVal          = await db.getSetting('daily_reminders_enabled');
    dailyRemindersEnabled = remVal == null || remVal == 'true';
    notifyListeners();
  }

  Future<void> save() async {
    final db = DatabaseService.instance;
    await db.setSetting('ltr_font_size',           ltrFontSize.toString());
    await db.setSetting('rtl_font_size',           rtlFontSize.toString());
    await db.setSetting('arabic_font_size',        arabicFontSize.toString());
    await db.setSetting('para_spacing',            paraSpacing.toString());
    await db.setSetting('line_height',             lineHeight.toString());
    await db.setSetting('daily_reminders_enabled', dailyRemindersEnabled.toString());
    notifyListeners();
  }

  Future<void> reset() async {
    ltrFontSize           = 17;
    rtlFontSize           = 22;
    arabicFontSize        = 26;
    paraSpacing           = 4;
    lineHeight            = 1.9;
    dailyRemindersEnabled = true;
    await save();
  }
}
