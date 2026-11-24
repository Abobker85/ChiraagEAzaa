import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DuaVerse {
  final String arabic;
  final String roman;
  final String english;

  const DuaVerse({
    required this.arabic,
    required this.roman,
    required this.english,
  });

  factory DuaVerse.fromJson(Map<String, dynamic> m) => DuaVerse(
        arabic: (m['arabic'] as String? ?? '').trim(),
        roman: (m['roman'] as String? ?? '').trim(),
        english: (m['english'] as String? ?? '').trim(),
      );
}

class MultilangDua {
  final String title;
  final String subtitle;
  final List<DuaVerse> verses;

  const MultilangDua({
    required this.title,
    required this.subtitle,
    required this.verses,
  });

  factory MultilangDua.fromJson(Map<String, dynamic> m) => MultilangDua(
        title: (m['title'] as String? ?? '').trim(),
        subtitle: (m['subtitle'] as String? ?? '').trim(),
        verses: (m['verses'] as List<dynamic>? ?? [])
            .map((e) => DuaVerse.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Offline loader for 3-language Duas (Arabic, Roman Transliteration, English)
/// bundled in `assets/duas/duas_multilang.json`.
class DuaLanguageService extends ChangeNotifier {
  DuaLanguageService._();
  static final instance = DuaLanguageService._();

  final Map<String, MultilangDua> _byNormalizedTitle = {};
  bool _loaded = false;

  bool showArabic = true;
  bool showRoman = true;
  bool showEnglish = true;

  bool get isLoaded => _loaded;

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/duas/duas_multilang.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final list = decoded['duas'] as List<dynamic>? ?? [];
      for (final item in list) {
        final dua = MultilangDua.fromJson(item as Map<String, dynamic>);
        _byNormalizedTitle[_norm(dua.title)] = dua;
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('DuaLanguageService: failed to load duas_multilang.json: $e');
    }
  }

  MultilangDua? getByTitle(String title) => _byNormalizedTitle[_norm(title)];

  void toggleArabic() {
    if (showArabic && !showRoman && !showEnglish) return;
    showArabic = !showArabic;
    notifyListeners();
  }

  void toggleRoman() {
    if (showRoman && !showArabic && !showEnglish) return;
    showRoman = !showRoman;
    notifyListeners();
  }

  void toggleEnglish() {
    if (showEnglish && !showArabic && !showRoman) return;
    showEnglish = !showEnglish;
    notifyListeners();
  }
}
