import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../services/dua_language_service.dart';
import 'add_custom_dua_screen.dart';
import 'lyric_detail_screen.dart';

/// Unified Spiritual Portal for Duas, Ziyaraat, and Munajaat with tabbed navigation.
class DuaHubScreen extends StatefulWidget {
  final String initialCategoryKey;

  const DuaHubScreen({super.key, this.initialCategoryKey = 'duas'});

  @override
  State<DuaHubScreen> createState() => DuaHubScreenState();
}

class _DuaTabDefinition {
  final String key;
  final String title;
  final String urduTitle;
  final IconData iconData;

  const _DuaTabDefinition({
    required this.key,
    required this.title,
    required this.urduTitle,
    required this.iconData,
  });
}

class DuaHubScreenState extends State<DuaHubScreen>
    with SingleTickerProviderStateMixin {
  static const List<_DuaTabDefinition> _tabs = [
    _DuaTabDefinition(
      key: 'duas',
      title: 'Duas',
      urduTitle: 'دعائیں و اعمال',
      iconData: Icons.auto_stories_rounded,
    ),
    _DuaTabDefinition(
      key: 'ziyaraat',
      title: 'Ziyaraat',
      urduTitle: 'زیارات مقدسہ',
      iconData: Icons.place_rounded,
    ),
    _DuaTabDefinition(
      key: 'munaejaat',
      title: 'Munajaat',
      urduTitle: 'مناجات و استغاثہ',
      iconData: Icons.spa_rounded,
    ),
  ];

  late TabController _tabController;
  final Map<String, List<LyricItem>> _cache = {};
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    int initialIndex = _tabs.indexWhere((t) => t.key == widget.initialCategoryKey);
    if (initialIndex < 0) initialIndex = 0;

    _tabController = TabController(
      length: _tabs.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadAllCategories();
  }

  /// Programmatically switches to the tab matching [categoryKey] ('duas', 'ziyaraat', or 'munaejaat').
  void selectCategory(String categoryKey) {
    final idx = _tabs.indexWhere((t) => t.key == categoryKey);
    if (idx >= 0 && _tabController.index != idx) {
      _tabController.animateTo(idx);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCategories() async {
    setState(() => _loading = true);
    final db = DatabaseService.instance;
    final futures = _tabs.map((t) async {
      final items = await db.getLyricsByCategory(t.key);
      return MapEntry(t.key, items);
    });

    final results = await Future.wait(futures);
    if (mounted) {
      setState(() {
        for (final entry in results) {
          _cache[entry.key] = entry.value;
        }
        _loading = false;
      });
    }
  }

  List<LyricItem> _filteredItems(String key) {
    final list = _cache[key] ?? [];
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openAddCustomDua() async {
    final currentKey = _tabs[_tabController.index].key;
    final saved = await Navigator.push<LyricItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomDuaScreen(initialCategoryKey: currentKey),
      ),
    );
    if (saved != null && mounted) {
      await _loadAllCategories();
      final targetTabIdx = _tabs.indexWhere((t) => t.key == saved.categoryKey);
      if (targetTabIdx >= 0 && targetTabIdx != _tabController.index) {
        _tabController.animateTo(targetTabIdx);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${saved.title}" to index')),
      );
    }
  }

  Future<void> _deleteCustomDua(LyricItem item) async {
    await DatabaseService.instance.deleteCustomDua(item.id);
    DuaLanguageService.instance.unregisterCustomDua(item.title);
    await _loadAllCategories();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: colors.card,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Duas & Devotions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              key: const Key('dua_hub_add_custom_btn'),
              onPressed: _openAddCustomDua,
              style: TextButton.styleFrom(
                backgroundColor: colors.accentSoft,
                foregroundColor: colors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Add Dua',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reload Recitations',
            onPressed: _loadAllCategories,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              // Real-time Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.separator),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search Duas, Ziyaraat or Munajaat...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: colors.accent,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16, color: colors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Untruncated Segmented TabBar (text + count chip, no icon squeezing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(3),
                height: 42,
                decoration: BoxDecoration(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.separator),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: _tabs.map((tab) {
                    final count = _cache[tab.key]?.length ?? 0;
                    final selected = _tabs[_tabController.index].key == tab.key;
                    return Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.title,
                            maxLines: 1,
                            softWrap: false,
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : colors.accentSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : colors.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: colors.accent),
            )
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _buildTabList(tab, colors)).toList(),
            ),
    );
  }

  Widget _buildTabList(_DuaTabDefinition tab, AppColors colors) {
    final items = _filteredItems(tab.key);
    final allItems = _cache[tab.key] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.iconData,
                size: 48,
                color: colors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matches found for "$_searchQuery"'
                    : 'No recitations available in this section',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colors.accent,
      onRefresh: _loadAllCategories,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        itemCount: items.length + 1, // +1 for header info card
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeaderInfoCard(tab, allItems.length, colors);
          }
          final item = items[index - 1];
          final origIndex = allItems.indexOf(item);
          final safeIndex = origIndex >= 0 ? origIndex : index - 1;

          return _buildRecitationCard(
            colors: colors,
            item: item,
            playlist: allItems,
            index: safeIndex,
            totalCount: allItems.length,
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfoCard(_DuaTabDefinition tab, int count, AppColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const [Color(0xFF0E2915), Color(0xFF174523)]
        : const [Color(0xFF0D3B18), Color(0xFF1A5C28)];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.36),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3B18).withValues(alpha: isDark ? 0.32 : 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.45),
              ),
            ),
            child: Center(
              child: Icon(tab.iconData, size: 20, color: const Color(0xFFF6DF96)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.urduTitle,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicTextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Swipe between pages while reading · $count recitations',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: const Color(0xFFE7EFEA).withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecitationCard({
    required AppColors colors,
    required LyricItem item,
    required List<LyricItem> playlist,
    required int index,
    required int totalCount,
  }) {
    final isSaved = SavedManager.instance.isSaved(item.id);
    final isArabicTitle = AppTheme.containsArabic(item.title);
    final indexLabel = (index + 1).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSaved
              ? colors.accent.withValues(alpha: 0.35)
              : colors.separator,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LyricDetailScreen(
                  item: item,
                  playlist: playlist,
                  initialIndex: index,
                ),
              ),
            );
            if (mounted) setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      indexLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isArabicTitle ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        textDirection: isArabicTitle ? TextDirection.rtl : TextDirection.ltr,
                        style: isArabicTitle
                            ? AppTheme.arabicTextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              )
                            : TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (DatabaseService.isCustomDuaId(item.id)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.goldSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.gold,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete Custom Dua',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    onPressed: () => _deleteCustomDua(item),
                  ),
                ],
                if (isSaved)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: colors.accent,
                      size: 18,
                    ),
                  ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.textTertiary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
