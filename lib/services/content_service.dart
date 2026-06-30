import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lyric_item.dart';

/// Loads and caches lyrics index (id, category, title) from bundled JSON.
/// Full lyric content is loaded on demand from assets/data/content.json
class ContentService {
  ContentService._();
  static final instance = ContentService._();

  List<LyricItem>? _index;
  Map<String, dynamic>? _content;

  Future<List<LyricItem>> get index async {
    if (_index != null) return _index!;
    final raw = await rootBundle.loadString('assets/data/index.json');
    final List<dynamic> list = jsonDecode(raw);
    _index = list.map((e) {
      // Each entry is [id, category, title]
      return LyricItem(
        id: e[0] as int,
        categoryKey: e[1] as String,
        title: e[2] as String,
      );
    }).toList();
    return _index!;
  }

  Future<String?> getLyricContent(int id) async {
    if (_content == null) {
      final raw = await rootBundle.loadString('assets/data/content.json');
      _content = jsonDecode(raw) as Map<String, dynamic>;
    }
    return _content![id.toString()] as String?;
  }

  Future<List<LyricItem>> itemsFor(String path) async {
    final all = await index;
    if (path == '__all__') return all;
    return all
        .where((item) =>
        item.categoryKey == path || item.categoryKey.startsWith('$path/'))
        .toList();
  }

  Future<List<LyricItem>> search(String query) async {
    if (query.isEmpty) return [];
    final all = await index;
    final lo = query.toLowerCase();
    return all
        .where((item) => item.title.toLowerCase().contains(lo))
        .take(100)
        .toList();
  }

  Future<Map<String, List<String>>> artistsFor(String top) async {
    final items = await itemsFor(top);
    final Map<String, List<String>> map = {};
    for (final item in items) {
      final parts = item.categoryKey.split('/');
      if (parts.length >= 2) {
        final artist = parts[1];
        map.putIfAbsent(artist, () => []);
        if (parts.length >= 3) map[artist]!.add(parts[2]);
      }
    }
    return map;
  }

  int countFor(String top) {
    if (_index == null) return 0;
    return _index!.where((item) => item.categoryKey.split('/').first == top).length;
  }
}

bool isRTLText(String text) {
  final rtl = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
  return rtl.hasMatch(text);
}
