class Category {
  final int id;
  final String key;
  final String label;
  final String icon;
  final int sortOrder;
  int count;

  Category({
    required this.id,
    required this.key,
    required this.label,
    required this.icon,
    required this.sortOrder,
    this.count = 0,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
    id:        m['id'] as int,
    key:       m['key'] as String,
    label:     m['label'] as String,
    icon:      m['icon'] as String,
    sortOrder: m['sort_order'] as int,
    count:     m['count'] as int? ?? 0,
  );
}

class Artist {
  final int id;
  final String categoryKey;
  final String name;

  const Artist({required this.id, required this.categoryKey, required this.name});

  factory Artist.fromMap(Map<String, dynamic> m) => Artist(
    id:          m['id'] as int,
    categoryKey: m['category_key'] as String,
    name:        m['name'] as String,
  );
}

class LyricItem {
  final int id;
  final String categoryKey;
  final int? artistId;
  final String? artistName;
  final String? year;
  final String title;
  final bool isRtl;

  const LyricItem({
    required this.id,
    required this.categoryKey,
    this.artistId,
    this.artistName,
    this.year,
    required this.title,
    this.isRtl = false,
  });

  factory LyricItem.fromMap(Map<String, dynamic> m) => LyricItem(
    id:          m['id'] as int,
    categoryKey: m['category_key'] as String,
    artistId:    m['artist_id'] as int?,
    artistName:  m['artist_name'] as String?,
    year:        m['year'] as String?,
    title:       m['title'] as String,
    isRtl:       (m['is_rtl'] as int? ?? 0) == 1,
  );

  String get subtitle {
    final parts = <String>[];
    if (artistName != null) parts.add(artistName!);
    if (year != null) parts.add(year!);
    return parts.join(' · ');
  }

  @override
  bool operator ==(Object other) => other is LyricItem && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class LyricDetail {
  final LyricItem item;
  final String contentHtml;

  const LyricDetail({required this.item, required this.contentHtml});
}

// In-memory saved manager (backed by DB via DatabaseService)
class SavedManager {
  SavedManager._();
  static final instance = SavedManager._();
  final Set<int> _savedIds = {};

  void loadIds(List<int> ids) => _savedIds
    ..clear()
    ..addAll(ids);

  bool isSaved(int id) => _savedIds.contains(id);

  void add(int id) => _savedIds.add(id);
  void remove(int id) => _savedIds.remove(id);
}
