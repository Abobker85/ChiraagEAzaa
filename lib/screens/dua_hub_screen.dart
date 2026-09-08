import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
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
  final String icon;

  const _DuaTabDefinition({
    required this.key,
    required this.title,
    required this.urduTitle,
    required this.icon,
  });
}

class _DuaHubScreenState extends State<DuaHubScreen>
    with SingleTickerProviderStateMixin {
  static const List<_DuaTabDefinition> _tabs = [
    _DuaTabDefinition(
      key: 'duas',
      title: 'Duas',
      urduTitle: 'دعائیں و اعمال',
      icon: '🤲',
    ),
    _DuaTabDefinition(
      key: 'ziyaraat',
      title: 'Ziyaraat',
      urduTitle: 'زیارات مقدسہ',
      icon: '🕋',
    ),
    _DuaTabDefinition(
      key: 'munaejaat',
      title: 'Munajaat',
      urduTitle: 'مناجات و استغاثہ',
      icon: '🌹',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dua & Spiritual Portal',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reload Recitations',
            onPressed: _loadAllCategories,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Real-time Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search recitations in current tab...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.green,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
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
                  color: AppTheme.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.green,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.green.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: _tabs.map((tab) {
                    final count = _cache[tab.key]?.length ?? 0;
                    return Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tab.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(tab.title),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: _tabs[_tabController.index].key == tab.key
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppTheme.greenPale,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _tabs[_tabController.index].key == tab.key
                                      ? Colors.white
                                      : AppTheme.green,
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.green),
            )
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _buildTabList(tab)).toList(),
            ),
    );
  }

  Widget _buildTabList(_DuaTabDefinition tab) {
    final items = _filteredItems(tab.key);
    final allItems = _cache[tab.key] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tab.icon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matches found for "$_searchQuery"'
                    : 'No recitations available in this section',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.green,
      onRefresh: _loadAllCategories,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: items.length + 1, // +1 for header info card
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeaderInfoCard(tab, allItems.length);
          }
          final item = items[index - 1];
          final origIndex = allItems.indexOf(item);
          final safeIndex = origIndex >= 0 ? origIndex : index - 1;

          return _buildRecitationCard(
            item: item,
            playlist: allItems,
            index: safeIndex,
            totalCount: allItems.length,
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfoCard(_DuaTabDefinition tab, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.greenPale.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greenBadge.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(tab.icon, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.urduTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.green,
                  ),
                ),
                Text(
                  'Swipe between pages while reading • $count recitations',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.9),
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
    required LyricItem item,
    required List<LyricItem> playlist,
    required int index,
    required int totalCount,
  }) {
    final isSaved = SavedManager.instance.isSaved(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                    color: AppTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSaved)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.bookmark_rounded,
                      color: AppTheme.green,
                      size: 18,
                    ),
                  ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textTertiary,
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
