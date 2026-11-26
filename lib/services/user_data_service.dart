import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/lyric_item.dart';
import 'database_service.dart';
import 'dua_language_service.dart';
import 'majlis_playlist_service.dart';
import 'quran_service.dart';

class RecentEntry {
  final int id;
  final String categoryKey;
  final String title;
  final bool isRtl;
  final String? artistName;

  const RecentEntry({
    required this.id,
    required this.categoryKey,
    required this.title,
    required this.isRtl,
    this.artistName,
  });

  LyricItem toLyricItem() => LyricItem(
        id: id,
        categoryKey: categoryKey,
        title: title,
        isRtl: isRtl,
        artistName: artistName,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryKey': categoryKey,
        'title': title,
        'isRtl': isRtl,
        'artistName': artistName,
      };

  factory RecentEntry.fromJson(Map<String, dynamic> m) => RecentEntry(
        id: (m['id'] as num).toInt(),
        categoryKey: m['categoryKey'] as String? ?? 'duas',
        title: m['title'] as String? ?? '',
        isRtl: m['isRtl'] == true,
        artistName: m['artistName'] as String?,
      );
}

/// Manages Recently Read History, Personal Reciter Notes on lyrics, and
/// full offline JSON Backup & Restore of all user data.
class UserDataService extends ChangeNotifier {
  UserDataService._();
  static final instance = UserDataService._();

  static const String _recentKey = 'recent_history_v1';
  static const String _notesKey = 'lyric_notes_v1';
  static const int _maxRecent = 8;

  final List<RecentEntry> _recent = [];
  final Map<int, String> _notes = {};
  bool _loaded = false;

  List<RecentEntry> get recent => List.unmodifiable(_recent);

  String? getNote(int lyricId) => _notes[lyricId];
  bool hasNote(int lyricId) => (_notes[lyricId]?.trim().isNotEmpty ?? false);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final db = DatabaseService.instance;
      final recRaw = await db.getSetting(_recentKey);
      if (recRaw != null && recRaw.isNotEmpty) {
        final decoded = jsonDecode(recRaw) as List<dynamic>;
        _recent
          ..clear()
          ..addAll(decoded.map((e) => RecentEntry.fromJson(e as Map<String, dynamic>)));
      }
      final notesRaw = await db.getSetting(_notesKey);
      if (notesRaw != null && notesRaw.isNotEmpty) {
        final decoded = jsonDecode(notesRaw) as Map<String, dynamic>;
        _notes.clear();
        decoded.forEach((k, v) {
          final id = int.tryParse(k);
          if (id != null && v is String && v.trim().isNotEmpty) {
            _notes[id] = v;
          }
        });
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('UserDataService: load error: $e');
    }
  }

  Future<void> recordRecent(LyricItem item) async {
    await ensureLoaded();
    _recent.removeWhere((e) => e.id == item.id);
    _recent.insert(
      0,
      RecentEntry(
        id: item.id,
        categoryKey: item.categoryKey,
        title: item.title,
        isRtl: item.isRtl,
        artistName: item.artistName,
      ),
    );
    if (_recent.length > _maxRecent) {
      _recent.removeRange(_maxRecent, _recent.length);
    }
    notifyListeners();
    await DatabaseService.instance.setSetting(
      _recentKey,
      jsonEncode(_recent.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveNote(int lyricId, String note) async {
    await ensureLoaded();
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      _notes.remove(lyricId);
    } else {
      _notes[lyricId] = trimmed;
    }
    notifyListeners();
    await DatabaseService.instance.setSetting(
      _notesKey,
      jsonEncode(_notes.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  /// Exports Bookmarks, Custom Duas, Majlis Playlists, Khatm Paras, Quran Bookmarks,
  /// Recently Read, and Personal Notes into a portable JSON string.
  Future<String> exportBackupJson() async {
    await ensureLoaded();
    await MajlisPlaylistService.instance.ensureLoaded();
    await QuranService.instance.ensureLoaded();

    final db = DatabaseService.instance;
    final bookmarks = await db.getBookmarks();
    final customDuasRaw = await db.getSetting(DatabaseService.customDuasSettingKey);
    final customDuas = (customDuasRaw != null && customDuasRaw.isNotEmpty)
        ? jsonDecode(customDuasRaw)
        : <dynamic>[];

    final payload = {
      'app': 'ChiraagEAzaa',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'bookmarkIds': bookmarks.map((b) => b.id).toList(),
      'customDuas': customDuas,
      'majlisPlaylists':
          MajlisPlaylistService.instance.playlists.map((p) => p.toJson()).toList(),
      'khatmParas': QuranService.instance.completedParas.toList()..sort(),
      'quranBookmarks': QuranService.instance.bookmarkedKeys.toList(),
      'notes': _notes.map((k, v) => MapEntry(k.toString(), v)),
      'recent': _recent.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Restores user data from a previously exported JSON backup string.
  /// Returns a human-readable summary of restored counts.
  Future<String> importBackupJson(String rawJson) async {
    final decoded = jsonDecode(rawJson.trim());
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'ChiraagEAzaa') {
      throw const FormatException('Invalid Chiraag e Azaa backup JSON.');
    }

    final db = DatabaseService.instance;
    int restoredBookmarks = 0;
    int restoredCustom = 0;
    int restoredNotes = 0;

    // 1. Bookmarks
    final bmIds = decoded['bookmarkIds'] as List<dynamic>? ?? [];
    for (final id in bmIds) {
      if (id is num) {
        await db.addBookmark(id.toInt());
        restoredBookmarks++;
      }
    }

    // 2. Custom Duas
    final customList = decoded['customDuas'] as List<dynamic>? ?? [];
    for (final entry in customList) {
      if (entry is Map<String, dynamic>) {
        final title = (entry['title'] as String? ?? '').trim();
        if (title.isEmpty) continue;
        final saved = await db.addCustomDua(
          categoryKey: entry['categoryKey'] as String? ?? 'duas',
          title: title,
          subtitle: entry['subtitle'] as String? ?? '',
          arabic: entry['arabic'] as String? ?? '',
          roman: entry['roman'] as String? ?? '',
          english: entry['english'] as String? ?? '',
        );
        DuaLanguageService.instance.registerCustomDua(
          title: saved.title,
          subtitle: entry['subtitle'] as String? ?? '',
          arabic: entry['arabic'] as String? ?? '',
          roman: entry['roman'] as String? ?? '',
          english: entry['english'] as String? ?? '',
        );
        restoredCustom++;
      }
    }

    // 3. Majlis Playlists
    final playlists = decoded['majlisPlaylists'] as List<dynamic>?;
    if (playlists != null) {
      await db.setSetting('majlis_playlists', jsonEncode(playlists));
    }

    // 4. Khatm Paras
    final khatm = decoded['khatmParas'] as List<dynamic>?;
    if (khatm != null) {
      for (final p in khatm) {
        if (p is num && !QuranService.instance.isParaCompleted(p.toInt())) {
          await QuranService.instance.toggleParaCompleted(p.toInt());
        }
      }
    }

    // 5. Personal Notes
    final notesMap = decoded['notes'] as Map<String, dynamic>?;
    if (notesMap != null) {
      for (final entry in notesMap.entries) {
        final id = int.tryParse(entry.key);
        if (id != null && entry.value is String && (entry.value as String).trim().isNotEmpty) {
          await saveNote(id, entry.value as String);
          restoredNotes++;
        }
      }
    }

    notifyListeners();
    return 'Restored $restoredBookmarks bookmarks, $restoredCustom custom items, and $restoredNotes notes.';
  }
}
