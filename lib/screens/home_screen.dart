import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import 'category_screen.dart';
import 'dua_hub_screen.dart';
import 'quran_hub_screen.dart';
import '../widgets/parents_dua_bubble.dart';

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
    try {
      final cats = await DatabaseService.instance.getCategories();
      if (mounted) {
        final total = cats.fold<int>(0, (sum, c) => sum + c.count);
        setState(() {
          _cats = cats;
          _totalCount = total;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen: Error loading categories: $e');
      if (mounted) {
        setState(() {
          _cats = [];
          _totalCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: colors.card,
        centerTitle: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chiraag e Azaa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (_totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.accentBadge),
                ),
                child: Text(
                  '$_totalCount items',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
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
            color: colors.separator,
          ),
        ),
      ),
      body: Stack(
        children: [
          _cats == null
              ? Center(child: CircularProgressIndicator(color: colors.accent))
              : RefreshIndicator(
                  color: colors.accent,
                  onRefresh: _loadCategories,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    children: [
                      _buildHeroBanner(colors),
                      const SizedBox(height: 14),
                      _buildQuickUtilities(colors),
                      const SizedBox(height: 14),
                      _buildQuranBannerCard(colors),
                      const SizedBox(height: 22),
                      ..._buildFeaturedSection(colors),
                      const SizedBox(height: 22),
                      ..._buildOtherCollectionsSection(colors),
                    ],
                  ),
                ),
          const ParentsDuaBubble(),
        ],
      ),
    );
  }

  // ── Spiritual Hero Banner ──────────────────────────────────────────────────
  Widget _buildHeroBanner(AppColors colors) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السلام عليك يا أبا عبد الله',
                      textDirection: TextDirection.rtl,
                      style: AppTheme.arabicTextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'چراغِ عزا',
                            style: AppTheme.arabicTextStyle(
                              fontSize: 14,
                              color: const Color(0xFFE8F5EC),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const TextSpan(
                            text: ' • Comprehensive Offline Shia Recitations',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFE8F5EC),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
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
              onTap: () => widget.onSelectTab?.call(2),
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
  Widget _buildQuickUtilities(AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: _quickUtilityCard(
            colors: colors,
            icon: Icons.blur_circular_rounded,
            title: 'Digital Tasbih',
            subtitle: 'Count Dhikr',
            iconColor: colors.accent,
            onTap: () => widget.onSelectTab?.call(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickUtilityCard(
            colors: colors,
            icon: Icons.bookmark_rounded,
            title: 'Saved Lyrics',
            subtitle: 'Quick Bookmarks',
            iconColor: colors.gold,
            onTap: () => widget.onSelectTab?.call(4),
          ),
        ),
      ],
    );
  }

  Widget _quickUtilityCard({
    required AppColors colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.separator),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
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
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Holy Quran Entry Card ──────────────────────────────────────────────────
  Widget _buildQuranBannerCard(AppColors colors) {
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('home_quran_card'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuranHubScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.gold.withValues(alpha: 0.55),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.accentSoft,
                colors.goldSoft.withValues(alpha: 0.65),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppTheme.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Holy Quran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'القرآن الكريم',
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabicTextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '114 Surahs · Arabic, Roman, English & Recitation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Featured Categories Grid ───────────────────────────────────────────────
  List<Widget> _buildFeaturedSection(AppColors colors) {
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
          Text(
            'Featured Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            'Primary Collections',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
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
  List<Widget> _buildOtherCollectionsSection(AppColors colors) {
    if (_cats == null) return [];

    final other = _cats!
        .where((c) => !_featuredKeysOrder.contains(c.key))
        .toList();

    if (other.isEmpty) return [];

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Collections',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${other.length} sections',
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.separator),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            type: MaterialType.transparency,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: other.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 0.5,
                color: colors.separator,
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
                            color: colors.accentSoft,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Icon(
                              AppCategories.getIcon(cat.key),
                              color: colors.accent,
                              size: 20,
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (urdu != null)
                                Text(
                                  urdu,
                                  textDirection: TextDirection.rtl,
                                  style: AppTheme.arabicTextStyle(
                                    fontSize: 14,
                                    color: colors.textSecondary,
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
                              color: colors.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${cat.count}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textTertiary,
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
      ),
    ];
  }

  void _openCategory(Category cat) {
    if (cat.key == 'duas' || cat.key == 'ziyaraat' || cat.key == 'munaejaat') {
      if (widget.onSelectTab != null) {
        widget.onSelectTab!(1);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DuaHubScreen(initialCategoryKey: cat.key),
        ),
      );
      return;
    }
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
    final colors = AppColors.of(context);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.separator),
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
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Icon(
                        AppCategories.getIcon(cat.key),
                        color: colors.accent,
                        size: 20,
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
                        color: colors.accentBadge.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${cat.count}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
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
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    urduSubtitle ?? 'Recitation',
                    textDirection: urduSubtitle != null ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: urduSubtitle != null
                        ? AppTheme.arabicTextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            height: 1.25,
                          )
                        : TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
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
