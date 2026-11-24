import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'database_service.dart';

class MajlisPlaylist {
  final String id;
  final String name;
  final List<int> lyricIds;

  const MajlisPlaylist({
    required this.id,
    required this.name,
    required this.lyricIds,
  });

  MajlisPlaylist copyWith({String? name, List<int>? lyricIds}) => MajlisPlaylist(
        id: id,
        name: name ?? this.name,
        lyricIds: lyricIds ?? this.lyricIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lyricIds': lyricIds,
      };

  factory MajlisPlaylist.fromJson(Map<String, dynamic> m) => MajlisPlaylist(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? 'Majlis',
        lyricIds: (m['lyricIds'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
      );
}

/// Offline custom Majlis Playlists (folders of Nouhay, Marsias, Duas, Ziyaraat)
/// persisted in SQLite `settings` table.
class MajlisPlaylistService extends ChangeNotifier {
  MajlisPlaylistService._();
  static final instance = MajlisPlaylistService._();

  static const String _storageKey = 'majlis_playlists';
  final List<MajlisPlaylist> _playlists = [];
  bool _loaded = false;

  List<MajlisPlaylist> get playlists => List.unmodifiable(_playlists);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await DatabaseService.instance.getSetting(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _playlists
          ..clear()
          ..addAll(
            decoded.map((e) => MajlisPlaylist.fromJson(e as Map<String, dynamic>)),
          );
      }
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('MajlisPlaylistService: load error: $e');
    }
  }

  Future<void> _persist() async {
    await DatabaseService.instance.setSetting(
      _storageKey,
      jsonEncode(_playlists.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await ensureLoaded();
    _playlists.insert(
      0,
      MajlisPlaylist(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmed,
        lyricIds: const [],
      ),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> deletePlaylist(String id) async {
    await ensureLoaded();
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleItemInPlaylist(String playlistId, int lyricId) async {
    await ensureLoaded();
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx < 0) return;
    final current = List<int>.from(_playlists[idx].lyricIds);
    if (current.contains(lyricId)) {
      current.remove(lyricId);
    } else {
      current.add(lyricId);
    }
    _playlists[idx] = _playlists[idx].copyWith(lyricIds: current);
    notifyListeners();
    await _persist();
  }
}
