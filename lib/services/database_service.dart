import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
  static const _dbVersion = 1; // bump when shipping a new DB asset

  // ── Init ──────────────────────────────────────────────────────────────
  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbDir = await getDatabasesPath();
    final dbPath = join(dbDir, _dbName);

    // Copy from assets if not yet on device OR version changed
    final shouldCopy = !File(dbPath).existsSync() ||
        await _needsUpdate(dbPath);

    if (shouldCopy) {
      debugPrint('DatabaseService: copying DB from assets…');
      final data = await rootBundle.load('assets/$_dbName');
      final bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes, flush: true);
      debugPrint('DatabaseService: DB copied (${bytes.length} bytes)');
    }

    return openDatabase(dbPath, readOnly: false, version: _dbVersion);
  }

  /// Compare stored user_version with our expected version.
  Future<bool> _needsUpdate(String path) async {
    try {
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
}
