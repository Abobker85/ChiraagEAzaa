import 'package:flutter/foundation.dart';
import 'database_service.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();
  AppSettings._();

  double ltrFontSize    = 19;
  double rtlFontSize    = 46;
  double arabicFontSize = 52;
  double paraSpacing    = 0;
  double lineHeight     = 1.9;

  Future<void> load() async {
    final db = DatabaseService.instance;
    ltrFontSize    = double.tryParse(await db.getSetting('ltr_font_size')    ?? '') ?? 19;
    rtlFontSize    = double.tryParse(await db.getSetting('rtl_font_size')    ?? '') ?? 46;
    arabicFontSize = double.tryParse(await db.getSetting('arabic_font_size') ?? '') ?? 52;
    paraSpacing    = double.tryParse(await db.getSetting('para_spacing')     ?? '') ?? 0;
    lineHeight     = double.tryParse(await db.getSetting('line_height')      ?? '') ?? 1.9;
    notifyListeners();
  }

  Future<void> save() async {
    final db = DatabaseService.instance;
    await db.setSetting('ltr_font_size',    ltrFontSize.toString());
    await db.setSetting('rtl_font_size',    rtlFontSize.toString());
    await db.setSetting('arabic_font_size', arabicFontSize.toString());
    await db.setSetting('para_spacing',     paraSpacing.toString());
    await db.setSetting('line_height',      lineHeight.toString());
    notifyListeners();
  }

  Future<void> reset() async {
    ltrFontSize = 19; rtlFontSize = 46; arabicFontSize = 52;
    paraSpacing = 0;  lineHeight  = 1.9;
    await save();
  }
}
