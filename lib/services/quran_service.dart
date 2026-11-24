import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/quran_models.dart';
import 'database_service.dart';

/// Offline-first Holy Quran data service loading all 114 Surahs (6,236 Ayahs)
/// in Arabic, Roman English transliteration, and English translation from the
/// bundled compressed asset, with SQLite bookmark and last-read persistence.
class QuranService extends ChangeNotifier {
  QuranService._();
  static final QuranService instance = QuranService._();

  static const String _assetPath = 'assets/quran/quran_complete.json.gz';

  static const List<QuranReciter> reciters = [
    QuranReciter(id: 'ar.alafasy', name: 'Mishary Rashid Alafasy', style: 'Murattal'),
    QuranReciter(id: 'ar.abdulbasitmurattal', name: 'Abdul Basit', style: 'Murattal'),
    QuranReciter(id: 'ar.minshawi', name: 'Muhammad Siddiq Al-Minshawi', style: 'Murattal'),
  ];

  List<QuranSurah>? _surahs;
  List<QuranJuzEntry>? _juzIndex;
  final Set<String> _bookmarkedKeys = {};
  final Set<int> _completedParas = {};
  int? _lastReadSurah;
  int? _lastReadAyah;
  bool _showRoman = true;
  bool _showEnglish = true;
  String _selectedReciterId = 'ar.alafasy';

  bool get isLoaded => _surahs != null;
  List<QuranSurah> get surahs => _surahs ?? const [];
  List<QuranJuzEntry> get juzList => _juzIndex ?? const [];
  Set<String> get bookmarkedKeys => Set.unmodifiable(_bookmarkedKeys);
  Set<int> get completedParas => Set.unmodifiable(_completedParas);
  bool isParaCompleted(int juz) => _completedParas.contains(juz);
  int? get lastReadSurah => _lastReadSurah;
  int? get lastReadAyah => _lastReadAyah;
  bool get showRoman => _showRoman;
  bool get showEnglish => _showEnglish;
  QuranReciter get selectedReciter => reciters.firstWhere(
        (r) => r.id == _selectedReciterId,
        orElse: () => reciters.first,
      );

  Future<void> ensureLoaded() async {
    if (_surahs != null) return;
    final byteData = await rootBundle.load(_assetPath);
    final compressed = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final raw = const GZipDecoder().decodeBytes(compressed);
    final decoded = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    final surahList = (decoded['surahs'] as List<dynamic>)
        .map((e) => QuranSurah.fromJson(e as Map<String, dynamic>))
        .toList();

    _surahs = surahList;
    _juzIndex = _buildJuzIndex(surahList);
    await _loadUserState();
    notifyListeners();
  }

  List<QuranJuzEntry> _buildJuzIndex(List<QuranSurah> surahs) {
    final seen = <int>{};
    final result = <QuranJuzEntry>[];
    for (final s in surahs) {
      for (final a in s.ayahs) {
        if (seen.add(a.juz)) {
          result.add(QuranJuzEntry(
            juzNumber: a.juz,
            startSurahNumber: s.number,
            startSurahEnglish: s.englishName,
            startSurahArabic: s.arabicName,
            startAyahNumber: a.numberInSurah,
            previewArabic: a.arabic,
          ));
        }
      }
    }
    result.sort((a, b) => a.juzNumber.compareTo(b.juzNumber));
    return result;
  }

  QuranSurah? getSurah(int number) {
    if (_surahs == null || number < 1 || number > _surahs!.length) return null;
    return _surahs![number - 1];
  }

  bool isBookmarked(int surahNumber, int ayahNumber) =>
      _bookmarkedKeys.contains('$surahNumber:$ayahNumber');

  List<QuranAyah> getBookmarkedAyahs() {
    if (_surahs == null || _bookmarkedKeys.isEmpty) return const [];
    final out = <QuranAyah>[];
    for (final key in _bookmarkedKeys) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final sNum = int.tryParse(parts[0]);
      final aNum = int.tryParse(parts[1]);
      if (sNum == null || aNum == null) continue;
      final surah = getSurah(sNum);
      if (surah != null && aNum >= 1 && aNum <= surah.ayahs.length) {
        out.add(surah.ayahs[aNum - 1]);
      }
    }
    out.sort((a, b) => a.globalNumber.compareTo(b.globalNumber));
    return out;
  }

  List<QuranAyah> searchAyahs(String query, {int limit = 40}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || _surahs == null) return const [];
    final matches = <QuranAyah>[];
    for (final s in _surahs!) {
      for (final a in s.ayahs) {
        if (a.arabic.contains(q) ||
            a.roman.toLowerCase().contains(q) ||
            a.english.toLowerCase().contains(q)) {
          matches.add(a);
          if (matches.length >= limit) return matches;
        }
      }
    }
    return matches;
  }

  Future<void> toggleBookmark(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';
    if (_bookmarkedKeys.contains(key)) {
      _bookmarkedKeys.remove(key);
    } else {
      _bookmarkedKeys.add(key);
    }
    notifyListeners();
    await DatabaseService.instance.setSetting(
      'quran_bookmarks',
      jsonEncode(_bookmarkedKeys.toList()),
    );
  }

  Future<void> saveLastRead(int surahNumber, int ayahNumber) async {
    _lastReadSurah = surahNumber;
    _lastReadAyah = ayahNumber;
    notifyListeners();
    await DatabaseService.instance.setSetting('quran_last_read', '$surahNumber:$ayahNumber');
  }

  Future<void> setShowRoman(bool value) async {
    _showRoman = value;
    notifyListeners();
    await DatabaseService.instance.setSetting('quran_show_roman', value.toString());
  }

  Future<void> setShowEnglish(bool value) async {
    _showEnglish = value;
    notifyListeners();
    await DatabaseService.instance.setSetting('quran_show_english', value.toString());
  }

  Future<void> setReciter(String reciterId) async {
    _selectedReciterId = reciterId;
    notifyListeners();
    await DatabaseService.instance.setSetting('quran_reciter', reciterId);
  }

  Future<void> toggleParaCompleted(int juz) async {
    if (juz < 1 || juz > 30) return;
    if (_completedParas.contains(juz)) {
      _completedParas.remove(juz);
    } else {
      _completedParas.add(juz);
    }
    notifyListeners();
    await DatabaseService.instance.setSetting(
      'quran_khatm_paras',
      jsonEncode(_completedParas.toList()..sort()),
    );
  }

  Future<void> resetKhatm() async {
    _completedParas.clear();
    notifyListeners();
    await DatabaseService.instance.setSetting('quran_khatm_paras', '[]');
  }

  Future<void> _loadUserState() async {
    try {
      final db = DatabaseService.instance;
      final bmRaw = await db.getSetting('quran_bookmarks');
      if (bmRaw != null && bmRaw.isNotEmpty) {
        final decoded = (jsonDecode(bmRaw) as List<dynamic>).cast<String>();
        _bookmarkedKeys
          ..clear()
          ..addAll(decoded);
      }
      final lastRaw = await db.getSetting('quran_last_read');
      if (lastRaw != null && lastRaw.contains(':')) {
        final parts = lastRaw.split(':');
        _lastReadSurah = int.tryParse(parts[0]);
        _lastReadAyah = int.tryParse(parts[1]);
      }
      final roRaw = await db.getSetting('quran_show_roman');
      if (roRaw != null) _showRoman = roRaw == 'true';
      final enRaw = await db.getSetting('quran_show_english');
      if (enRaw != null) _showEnglish = enRaw == 'true';
      final recRaw = await db.getSetting('quran_reciter');
      if (recRaw != null && recRaw.isNotEmpty) _selectedReciterId = recRaw;
      final khatmRaw = await db.getSetting('quran_khatm_paras');
      if (khatmRaw != null && khatmRaw.isNotEmpty) {
        final decoded = (jsonDecode(khatmRaw) as List<dynamic>).cast<int>();
        _completedParas
          ..clear()
          ..addAll(decoded);
      }
    } catch (e) {
      debugPrint('QuranService: error loading state: $e');
    }
  }

  /// Converts western digits to Eastern Arabic-Indic digits for ayah medallions.
  static String toArabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? c : digits[d];
    }).join();
  }
}
