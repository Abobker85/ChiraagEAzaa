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
  State<DuaHubScreen> createState() => _DuaHubScreenState();
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

class _DuaHubScreenState extends State<DuaHubScreen>
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
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Dua & Spiritual Portal',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton.icon(
            key: const Key('dua_hub_add_custom_btn'),
            onPressed: _openAddCustomDua,
            icon: Icon(Icons.add_circle_outline_rounded, size: 18, color: colors.accent),
            label: Text(
              'Add Dua',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.accent,
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
          preferredSize: const Size.fromHeight(114),
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
                      hintText: 'Search recitations in current tab...',
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
              // Segmented TabBar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 44,
                decoration: BoxDecoration(
                  color: colors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.separator),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: _tabs.map((tab) {
                    final count = _cache[tab.key]?.length ?? 0;
                    return Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tab.iconData, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tab.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _tabs[_tabController.index].key == tab.key
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : colors.accentSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _tabs[_tabController.index].key == tab.key
                                      ? Colors.white
                                      : colors.accent,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.accentBadge,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: colors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Icon(tab.iconData, size: 18, color: colors.accent),
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
                Text(
                  'Swipe between pages while reading • $count recitations',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.separator),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: colors.separator),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        textDirection: AppTheme.containsArabic(item.title)
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: AppTheme.containsArabic(item.title)
                            ? AppTheme.arabicTextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
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
