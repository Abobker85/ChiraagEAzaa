import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/lyric_item.dart';

/// Manages the bundled SQLite database.
///
/// On first launch the DB is copied from assets to the device's
/// writable directory so it can be queried with sqflite.
class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();

  Database? _db;

  static const _dbName = 'chiraag_e_azaa.db';
  static const _dbVersion = 2; // bump when shipping a new DB asset
  static const int customDuaMinId = 900000;
  static const String customDuasSettingKey = 'custom_duas_v1';

  static bool isCustomDuaId(int id) => id >= customDuaMinId;

  // ── Init ──────────────────────────────────────────────────────────────
  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return _openWeb();
    }

    final dbDir = await getDatabasesPath();
    final dbPath = join(dbDir, _dbName);

    // Copy from assets if not yet on device OR version changed OR corrupt
    final shouldCopy = !File(dbPath).existsSync() ||
        await _needsUpdate(dbPath);

    if (shouldCopy) {
      // Preserve user bookmarks and settings when upgrading an existing DB file
      List<Map<String, Object?>> savedBookmarks = const [];
      List<Map<String, Object?>> savedSettings = const [];
      if (File(dbPath).existsSync()) {
        try {
          final oldDb = await openDatabase(dbPath, readOnly: true);
          try {
            savedBookmarks = await oldDb.query('bookmarks');
          } catch (_) {}
          try {
            savedSettings = await oldDb.query('settings');
          } catch (_) {}
          await oldDb.close();
        } catch (_) {}
      }

      debugPrint('DatabaseService: copying DB from assets…');
      final targetFile = File(dbPath);
      if (!targetFile.parent.existsSync()) {
        targetFile.parent.createSync(recursive: true);
      }
      final data = await rootBundle.load('assets/$_dbName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final tempFile = File('$dbPath.tmp');
      await tempFile.writeAsBytes(bytes, flush: true);
      if (targetFile.existsSync()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
      await tempFile.rename(dbPath);
      debugPrint('DatabaseService: DB copied (${bytes.length} bytes)');

      if (savedBookmarks.isNotEmpty || savedSettings.isNotEmpty) {
        try {
          final upgraded = await openDatabase(dbPath, readOnly: false, version: _dbVersion);
          if (savedBookmarks.isNotEmpty) {
            await upgraded.execute('''
              CREATE TABLE IF NOT EXISTS bookmarks (
                lyric_id  INTEGER PRIMARY KEY,
                saved_at  TEXT NOT NULL DEFAULT (datetime('now'))
              )
            ''');
            for (final b in savedBookmarks) {
              await upgraded.insert('bookmarks', b, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
          for (final s in savedSettings) {
            await upgraded.insert('settings', s, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await _reinjectCustomDuas(upgraded);
          await upgraded.close();
        } catch (e) {
          debugPrint('DatabaseService: restore user data warning: $e');
        }
      }
    }

    try {
      return await openDatabase(dbPath, readOnly: false, version: _dbVersion);
    } catch (e) {
      debugPrint('DatabaseService: Failed to open DB ($e), performing clean recovery copy...');
      final targetFile = File(dbPath);
      if (targetFile.existsSync()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }
      final data = await rootBundle.load('assets/$_dbName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await targetFile.writeAsBytes(bytes, flush: true);
      return openDatabase(dbPath, readOnly: false, version: _dbVersion);
    }
  }

  Future<Database> _openWeb() async {
    const dbPath = _dbName;
    final shouldCopy = !await databaseExists(dbPath) || await _needsUpdate(dbPath);

    if (shouldCopy) {
      debugPrint('DatabaseService: importing web DB from assets...');
      final data = await rootBundle.load('assets/$_dbName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await databaseFactory.writeDatabaseBytes(dbPath, bytes);
      debugPrint('DatabaseService: web DB imported (${bytes.length} bytes)');
    }

    return openDatabase(dbPath, readOnly: false, version: _dbVersion);
  }

  /// Compare stored user_version with our expected version.
  Future<bool> _needsUpdate(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() < 1000000) {
        return true;
      }
      final existing = await openDatabase(path, readOnly: true);
      final rows = await existing.rawQuery('PRAGMA user_version');
      await existing.close();
      final ver = rows.first.values.first as int? ?? 0;
      return ver < _dbVersion;
    } catch (_) {
      return true;
    }
  }

  // ── Categories ────────────────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT c.id, c.key, c.label, c.icon, c.sort_order,
             COUNT(l.id) as count
      FROM   categories c
      LEFT JOIN lyrics l ON l.category_key = c.key
      GROUP BY c.id
      ORDER BY c.sort_order
    ''');
    return rows.map(Category.fromMap).toList();
  }

  // ── Artists ───────────────────────────────────────────────────────────
  Future<List<Artist>> getArtists(String categoryKey) async {
    final d = await db;
    final rows = await d.query(
      'artists',
      where: 'category_key = ?',
      whereArgs: [categoryKey],
      orderBy: 'name',
    );
    return rows.map(Artist.fromMap).toList();
  }

  Future<List<String>> getYearsForArtist(
      String categoryKey, String artistName) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT DISTINCT l.year
      FROM lyrics l
      JOIN artists a ON l.artist_id = a.id
      WHERE a.category_key = ? AND a.name = ? AND l.year IS NOT NULL
      ORDER BY l.year
    ''', [categoryKey, artistName]);
    return rows.map((r) => r['year'] as String).toList();
  }

  // ── Lyrics list ───────────────────────────────────────────────────────
  Future<List<LyricItem>> getLyricsByCategory(String categoryKey) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT l.id, l.category_key, l.artist_id, l.year, l.title, l.is_rtl,
             a.name AS artist_name
      FROM   lyrics l
      LEFT JOIN artists a ON l.artist_id = a.id
      WHERE  l.category_key = ?
      ORDER  BY l.id
    ''', [categoryKey]);
    return rows.map(LyricItem.fromMap).toList();
  }

  Future<List<LyricItem>> getLyricsByArtist(
      String categoryKey, String artistName, {String? year}) async {
    final d = await db;
    final args = <dynamic>[categoryKey, artistName];
    var yearClause = '';
    if (year != null) {
      yearClause = 'AND l.year = ?';
      args.add(year);
    }
    final rows = await d.rawQuery('''
      SELECT l.id, l.category_key, l.artist_id, l.year, l.title, l.is_rtl,
             a.name AS artist_name
      FROM   lyrics l
      JOIN   artists a ON l.artist_id = a.id
      WHERE  a.category_key = ? AND a.name = ? $yearClause
      ORDER  BY l.id
    ''', args);
    return rows.map(LyricItem.fromMap).toList();
  }

  // ── Lyric detail (content) ────────────────────────────────────────────
  Future<LyricDetail?> getLyricDetail(int id) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT l.id, l.category_key, l.artist_id, l.year, l.title,
             l.content_html, l.is_rtl, a.name AS artist_name
      FROM   lyrics l
      LEFT JOIN artists a ON l.artist_id = a.id
      WHERE  l.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final m = rows.first;
    return LyricDetail(
      item: LyricItem.fromMap(m),
      contentHtml: m['content_html'] as String? ?? '',
    );
  }

  // ── Full-Text Search ──────────────────────────────────────────────────
  Future<List<LyricItem>> search(String query, {int limit = 100}) async {
    if (query.trim().isEmpty) return [];
    final d = await db;
    // Use FTS5 with prefix matching
    final ftsQuery = '${query.trim().replaceAll("'", "''")}*';
    final rows = await d.rawQuery('''
      SELECT l.id, l.category_key, l.artist_id, l.year, l.title, l.is_rtl,
             a.name AS artist_name
      FROM   lyrics l
      LEFT JOIN artists a ON l.artist_id = a.id
      WHERE  l.id IN (
        SELECT rowid FROM lyrics_fts WHERE lyrics_fts MATCH ?
        LIMIT ?
      )
    ''', [ftsQuery, limit]);
    return rows.map(LyricItem.fromMap).toList();
  }

  // ── Bookmarks (stored in DB) ──────────────────────────────────────────
  Future<void> ensureBookmarksTable() async {
    final d = await db;
    await d.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        lyric_id  INTEGER PRIMARY KEY,
        saved_at  TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
  }

  Future<List<LyricItem>> getBookmarks() async {
    await ensureBookmarksTable();
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT l.id, l.category_key, l.artist_id, l.year, l.title, l.is_rtl,
             a.name AS artist_name
      FROM   bookmarks b
      JOIN   lyrics l ON l.id = b.lyric_id
      LEFT JOIN artists a ON l.artist_id = a.id
      ORDER  BY b.saved_at DESC
    ''');
    return rows.map(LyricItem.fromMap).toList();
  }

  Future<void> addBookmark(int lyricId) async {
    await ensureBookmarksTable();
    final d = await db;
    await d.insert('bookmarks', {'lyric_id': lyricId},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    SavedManager.instance.add(lyricId);
  }

  Future<void> removeBookmark(int lyricId) async {
    await ensureBookmarksTable();
    final d = await db;
    await d.delete('bookmarks', where: 'lyric_id = ?', whereArgs: [lyricId]);
    SavedManager.instance.remove(lyricId);
  }

  Future<void> loadBookmarkIds() async {
    await ensureBookmarksTable();
    final d = await db;
    final rows = await d.query('bookmarks', columns: ['lyric_id']);
    SavedManager.instance
        .loadIds(rows.map((r) => r['lyric_id'] as int).toList());
  }

  // ── Settings (stored in DB) ───────────────────────────────────────────
  Future<String?> getSetting(String key) async {
    final d = await db;
    final rows = await d.query('settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final d = await db;
    await d.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Custom User Duas (saved in DB + FTS index + preserved on upgrades) ─
  static String _buildCustomDuaHtml({
    required String subtitle,
    required String arabic,
    required String roman,
    required String english,
  }) {
    final buf = StringBuffer();
    if (subtitle.trim().isNotEmpty) {
      buf.writeln('<p>${subtitle.trim()}</p>');
    }
    if (arabic.trim().isNotEmpty) {
      buf.writeln('<p>${arabic.trim()}</p>');
    }
    if (roman.trim().isNotEmpty) {
      buf.writeln('<p>${roman.trim()}</p>');
    }
    if (english.trim().isNotEmpty) {
      buf.writeln('<p>${english.trim()}</p>');
    }
    return buf.toString().trim();
  }

  Future<void> _reinjectCustomDuas(Database targetDb) async {
    try {
      final rows = await targetDb.query(
        'settings',
        where: 'key = ?',
        whereArgs: [customDuasSettingKey],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final raw = rows.first['value'] as String? ?? '';
      if (raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      for (final entry in list) {
        final m = entry as Map<String, dynamic>;
        final id = (m['id'] as num).toInt();
        final cat = m['categoryKey'] as String? ?? 'duas';
        final title = m['title'] as String? ?? '';
        final html = _buildCustomDuaHtml(
          subtitle: m['subtitle'] as String? ?? '',
          arabic: m['arabic'] as String? ?? '',
          roman: m['roman'] as String? ?? '',
          english: m['english'] as String? ?? '',
        );
        await targetDb.insert(
          'lyrics',
          {
            'id': id,
            'category_key': cat,
            'artist_id': null,
            'year': null,
            'title': title,
            'content_html': html,
            'is_rtl': (m['arabic'] as String? ?? '').trim().isNotEmpty ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await targetDb.execute("INSERT INTO lyrics_fts(lyrics_fts) VALUES('rebuild')");
    } catch (e) {
      debugPrint('DatabaseService: reinject custom duas error: $e');
    }
  }

  Future<LyricItem> addCustomDua({
    required String categoryKey,
    required String title,
    String subtitle = '',
    String arabic = '',
    String roman = '',
    String english = '',
  }) async {
    final d = await db;
    final cleanTitle = title.trim();
    final cleanSub = subtitle.trim();
    final cleanAr = arabic.trim();
    final cleanRo = roman.trim();
    final cleanEn = english.trim();

    final maxRows = await d.rawQuery(
      'SELECT MAX(id) AS max_id FROM lyrics WHERE id >= ?',
      [customDuaMinId],
    );
    final currentMax = maxRows.first['max_id'] as int?;
    final nextId = (currentMax == null) ? customDuaMinId : currentMax + 1;
    final html = _buildCustomDuaHtml(
      subtitle: cleanSub,
      arabic: cleanAr,
      roman: cleanRo,
      english: cleanEn,
    );
    final isRtl = cleanAr.isNotEmpty ? 1 : 0;

    await d.insert(
      'lyrics',
      {
        'id': nextId,
        'category_key': categoryKey,
        'artist_id': null,
        'year': null,
        'title': cleanTitle,
        'content_html': html,
        'is_rtl': isRtl,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await d.execute(
      'INSERT INTO lyrics_fts(rowid, title) VALUES(?, ?)',
      [nextId, cleanTitle],
    );

    // Persist in settings so it survives future DB asset upgrades
    final existingRaw = await getSetting(customDuasSettingKey);
    final list = (existingRaw != null && existingRaw.isNotEmpty)
        ? List<Map<String, dynamic>>.from(
            (jsonDecode(existingRaw) as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : <Map<String, dynamic>>[];

    list.add({
      'id': nextId,
      'categoryKey': categoryKey,
      'title': cleanTitle,
      'subtitle': cleanSub,
      'arabic': cleanAr,
      'roman': cleanRo,
      'english': cleanEn,
    });
    await setSetting(customDuasSettingKey, jsonEncode(list));

    return LyricItem(
      id: nextId,
      categoryKey: categoryKey,
      title: cleanTitle,
      isRtl: isRtl == 1,
    );
  }

  Future<void> deleteCustomDua(int id) async {
    if (!isCustomDuaId(id)) return;
    final d = await db;
    await d.delete('lyrics', where: 'id = ?', whereArgs: [id]);
    await removeBookmark(id);
    await d.execute("INSERT INTO lyrics_fts(lyrics_fts) VALUES('rebuild')");

    final existingRaw = await getSetting(customDuasSettingKey);
    if (existingRaw != null && existingRaw.isNotEmpty) {
      final list = List<Map<String, dynamic>>.from(
        (jsonDecode(existingRaw) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      )..removeWhere((m) => (m['id'] as num?)?.toInt() == id);
      await setSetting(customDuasSettingKey, jsonEncode(list));
    }
  }
}
