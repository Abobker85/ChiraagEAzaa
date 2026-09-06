import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onSelectTab;

  const HomeScreen({super.key, this.onSelectTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category>? _cats;
  int _totalCount = 0;

  static const List<String> _featuredKeysOrder = [
    'nouhay',
    'marsias',
    'ziyaraat',
    'duas',
    'manqabat',
    'qasiday',
  ];

  static const Map<String, String> _urduSubtitles = {
    'nouhay': 'نوحہ خوانی',
    'marsias': 'مرثیہ و سوز و سلام',
    'ziyaraat': 'زیارات مقدسہ',
    'duas': 'دعائیں و اعمال',
    'manqabat': 'منقبت اہل بیتؑ',
    'qasiday': 'قصائد مدح',
    'nouhaDarHaal': 'نوحہ در حال',
    'oldNouhay': 'بیاضی نوحے',
    'salaam': 'سلام بر شہداء',
    'munaejaat': 'مناجات و استغاثہ',
    'urduMarsiye': 'اردو مرثیے',
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseService.instance.getCategories();
    if (mounted) {
      final total = cats.fold<int>(0, (sum, c) => sum + c.count);
      setState(() {
        _cats = cats;
        _totalCount = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.card,
        centerTitle: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Chiraag e Azaa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (_totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.greenPale,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.greenBadge),
                ),
                child: Text(
                  '$_totalCount items',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.green,
                  ),
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      body: _cats == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : RefreshIndicator(
              color: AppTheme.green,
              onRefresh: _loadCategories,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 14),
                  _buildQuickUtilities(),
                  const SizedBox(height: 20),
                  ..._buildFeaturedSection(),
                  const SizedBox(height: 20),
                  ..._buildOtherCollectionsSection(),
                ],
              ),
            ),
    );
  }

  // ── Spiritual Hero Banner ──────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF165225),
            Color(0xFF0D3316),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.green.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text('🕯️', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السلام عليك يا أبا عبد الله',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'چراغِ عزا • Comprehensive Offline Shia Recitations',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFE8F5EC),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Interactive Search Bar Trigger
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onSelectTab?.call(1),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppTheme.green,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Search nouhay, marsias, poet or lyrics...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.greenPale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Find',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Utilities ────────────────────────────────────────────────────────
  Widget _buildQuickUtilities() {
    return Row(
      children: [
        Expanded(
          child: _quickUtilityCard(
            icon: Icons.blur_circular_rounded,
            title: 'Digital Tasbih',
            subtitle: 'Count Dhikr',
            iconColor: AppTheme.green,
            onTap: () => widget.onSelectTab?.call(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickUtilityCard(
            icon: Icons.bookmark_rounded,
            title: 'Saved Lyrics',
            subtitle: 'Quick Bookmarks',
            iconColor: const Color(0xFFC07D15),
            onTap: () => widget.onSelectTab?.call(3),
          ),
        ),
      ],
    );
  }

  Widget _quickUtilityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Featured Categories Grid ───────────────────────────────────────────────
  List<Widget> _buildFeaturedSection() {
    if (_cats == null) return [];

    final featuredMap = {for (var c in _cats!) c.key: c};
    final featured = <Category>[];
    for (final key in _featuredKeysOrder) {
      if (featuredMap.containsKey(key)) {
        featured.add(featuredMap[key]!);
      }
    }

    if (featured.isEmpty) return [];

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Featured Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Primary Collections',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: featured.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.42,
        ),
        itemBuilder: (ctx, i) {
          final cat = featured[i];
          final urdu = _urduSubtitles[cat.key];
          return _FeaturedCard(
            cat: cat,
            urduSubtitle: urdu,
            onTap: () => _openCategory(cat),
          );
        },
      ),
    ];
  }

  // ── All Collections List ───────────────────────────────────────────────────
  List<Widget> _buildOtherCollectionsSection() {
    if (_cats == null) return [];

    final other = _cats!
        .where((c) => !_featuredKeysOrder.contains(c.key))
        .toList();

    if (other.isEmpty) return [];

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'All Collections',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${other.length} sections',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.07),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: other.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.black.withValues(alpha: 0.06),
            ),
            itemBuilder: (ctx, i) {
              final cat = other[i];
              final urdu = _urduSubtitles[cat.key];
              return InkWell(
                onTap: () => _openCategory(cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.greenPale,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            cat.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (urdu != null)
                              Text(
                                urdu,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (cat.count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.greenPale,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${cat.count}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.green,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];
  }

  void _openCategory(Category cat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Category cat;
  final String? urduSubtitle;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.cat,
    this.urduSubtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.greenPale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        cat.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  if (cat.count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.greenBadge.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${cat.count}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.green,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    urduSubtitle ?? 'Recitation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
