import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();

    final data = await rootBundle.load('assets/chiraag_e_azaa.db');
    tempDir = await Directory.systemTemp.createTemp('chiraag_db_test_');
    final dbFile = File('${tempDir.path}${Platform.pathSeparator}chiraag_e_azaa.db');
    await dbFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );

    db = await databaseFactoryFfi.openDatabase(
      dbFile.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
  });

  tearDownAll(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('bundled SQLite database has the required schema and content', () async {
    final tables = await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type IN ('table', 'virtual table')
    ''');
    final tableNames = tables.map((row) => row['name'] as String).toSet();

    expect(tableNames, containsAll(['categories', 'artists', 'lyrics', 'lyrics_fts', 'settings']));
    expect(await _countRows(db, 'categories'), greaterThan(0));
    expect(await _countRows(db, 'artists'), greaterThan(0));
    expect(await _countRows(db, 'lyrics'), greaterThan(0));
    expect(await _countRows(db, 'lyrics_fts'), greaterThan(0));
  });

  test('category query used by the home screen returns usable rows', () async {
    final rows = await db.rawQuery('''
      SELECT c.id, c.key, c.label, c.icon, c.sort_order,
             COUNT(l.id) as count
      FROM   categories c
      LEFT JOIN lyrics l ON l.category_key = c.key
      GROUP BY c.id
      ORDER BY c.sort_order
    ''');

    expect(rows, isNotEmpty);
    expect(rows.first.keys, containsAll(['id', 'key', 'label', 'icon', 'sort_order', 'count']));
    expect(rows.first['count'], isA<int>());
  });

  test('lyric detail query returns title and HTML content', () async {
    final idRow = await db.rawQuery('SELECT id FROM lyrics ORDER BY id LIMIT 1');
    final lyricId = idRow.first['id'] as int;

    final rows = await db.rawQuery('''
      SELECT l.id, l.category_key, l.artist_id, l.year, l.title,
             l.content_html, l.is_rtl, a.name AS artist_name
      FROM   lyrics l
      LEFT JOIN artists a ON l.artist_id = a.id
      WHERE  l.id = ?
    ''', [lyricId]);

    expect(rows, hasLength(1));
    expect(rows.first['title'], isA<String>());
    expect(rows.first['content_html'], isA<String>());
  });
}

Future<int> _countRows(Database db, String tableName) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $tableName');
  return rows.first['count'] as int;
}