import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../services/islamic_calendar_service.dart';
import '../services/quran_service.dart';
import '../services/user_data_service.dart';
import '../widgets/parents_dua_bubble.dart';
import 'category_screen.dart';
import 'dua_hub_screen.dart';
import 'lyric_detail_screen.dart';
import 'quran_hub_screen.dart';
import 'quran_reader_screen.dart';
import 'shia_calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onSelectTab;
  final ValueChanged<String>? onOpenDuaCategory;

  const HomeScreen({
    super.key,
    this.onSelectTab,
    this.onOpenDuaCategory,
  });

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
    UserDataService.instance.ensureLoaded();
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

  Future<void> _openDuaByTitle(String title) async {
    final duas = await DatabaseService.instance.getLyricsByCategory('duas');
    if (!mounted) return;
    final idx = duas.indexWhere(
      (d) => d.title.toLowerCase() == title.toLowerCase(),
    );
    if (idx >= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LyricDetailScreen(
            item: duas[idx],
            playlist: duas,
            initialIndex: idx,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DuaHubScreen(initialCategoryKey: 'duas'),
        ),
      );
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
      body: _cats == null
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : RefreshIndicator(
              color: colors.accent,
              onRefresh: _loadCategories,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  _buildEmeraldSanctuaryHero(colors),
                  const SizedBox(height: 12),
                  _buildDualSpotlightRow(colors),
                  const SizedBox(height: 10),
                  _buildQuickStrip(colors),
                  _buildRecentlyReadSection(colors),
                  const SizedBox(height: 18),
                  ..._buildFeaturedSection(colors),
                  const SizedBox(height: 16),
                  ..._buildOtherCollectionsSection(colors),
                ],
              ),
            ),
    );
  }

  /// Option B Unified Emerald Sanctuary Hero combining Arabic salutation,
  /// Hijri date, and upcoming Shia occasion into one cohesive card (no nested
  /// boxes, no emoji stand-ins, and no redundant search box).
  Widget _buildEmeraldSanctuaryHero(AppColors colors) {
    final now = DateTime.now();
    final hijri = IslamicCalendarService.toHijri(now);
    final upcoming = IslamicCalendarService.nextOccasion(now);

    return Container(
      key: const Key('home_islamic_calendar_card'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF165225),
            Color(0xFF0B2F14),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.42),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3316).withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Icon(
                              Icons.brightness_2_rounded,
                              color: AppTheme.gold,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Shia Recitations Archive',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDCEEE1),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'چراغِ عزا',
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabicTextStyle(
                            fontSize: 13.5,
                            color: AppTheme.gold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'السلام عليك يا أبا عبد الله',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: AppTheme.arabicTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Peace be upon you, O Aba Abdillah (a.s.)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFD5EADB),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.8,
              color: Colors.white.withValues(alpha: 0.14),
            ),
            InkWell(
              key: const Key('home_open_calendar_btn'),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShiaCalendarScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13.5,
                          color: AppTheme.gold,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            hijri.formattedEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          hijri.formattedAr,
                          textDirection: TextDirection.rtl,
                          style: AppTheme.arabicTextStyle(
                            fontSize: 13,
                            color: AppTheme.gold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: upcoming.occasion.isMourning
                                ? const Color(0xFFD5EADB)
                                : AppTheme.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            upcoming.isToday
                                ? '${upcoming.occasion.title} (Today)'
                                : '${upcoming.occasion.title} · In ${upcoming.daysUntil}d',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE6F3EA),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppTheme.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Equal-height dual spotlight cards for Holy Quran & Daily Recommended Dua.
  Widget _buildDualSpotlightRow(AppColors colors) {
    final daily = IslamicCalendarService.dailyDua(DateTime.now());
    return AnimatedBuilder(
      animation: QuranService.instance,
      builder: (context, _) {
        final q = QuranService.instance;
        final lastSurah =
            (q.isLoaded && q.lastReadSurah != null) ? q.getSurah(q.lastReadSurah!) : null;
        final quranSubtitle = lastSurah != null
            ? '${lastSurah.englishName} (${q.lastReadAyah ?? 1})'
            : '114 Surahs · Mushaf';
        final quranActionLabel = lastSurah != null ? 'Resume' : 'Read Quran';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: colors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.gold.withValues(alpha: 0.45), width: 1.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('home_quran_card'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => lastSurah != null
                              ? QuranReaderScreen(
                                  initialSurahNumber: lastSurah.number,
                                  initialAyahNumber: q.lastReadAyah ?? 1,
                                )
                              : const QuranHubScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colors.accentSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.auto_stories_rounded,
                                  size: 18,
                                  color: colors.accent,
                                ),
                              ),
                              Text(
                                'القرآن',
                                textDirection: TextDirection.rtl,
                                style: AppTheme.arabicTextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.accent,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Holy Quran',
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
                                quranSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                quranActionLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.accent,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: colors.accent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: colors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.separator),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('home_daily_dua_btn'),
                    onTap: () => _openDuaByTitle(daily.duaTitle),
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colors.goldSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                  color: colors.gold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.goldSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Daily Dua',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: colors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                daily.duaTitle,
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
                                daily.dayLabel.replaceAll(' Recommended', ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Recite Now',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.accent,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 17,
                                color: colors.accent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Slim horizontal quick-utility strip anchoring Tasbih, Saved, Quran Hub,
  /// and Parents Dua cleanly in-flow with zero floating-button overlap.
  Widget _buildQuickStrip(AppColors colors) {
    Widget stripPill({
      Key? key,
      required IconData icon,
      required Color iconColor,
      required String label,
      required VoidCallback onTap,
      bool goldHighlight = false,
    }) {
      return Material(
        color: goldHighlight ? colors.goldSoft : colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: goldHighlight
                ? colors.gold.withValues(alpha: 0.45)
                : colors.separator,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          stripPill(
            key: const Key('parents_dua_bubble'),
            icon: Icons.volunteer_activism_rounded,
            iconColor: colors.gold,
            label: 'Parents Dua',
            goldHighlight: true,
            onTap: () => showParentsDuaDialog(context),
          ),
          const SizedBox(width: 8),
          stripPill(
            icon: Icons.blur_circular_rounded,
            iconColor: colors.accent,
            label: 'Tasbih',
            onTap: () => widget.onSelectTab?.call(3),
          ),
          const SizedBox(width: 8),
          stripPill(
            icon: Icons.bookmark_rounded,
            iconColor: colors.accent,
            label: 'Saved & Majlis',
            onTap: () => widget.onSelectTab?.call(4),
          ),
          const SizedBox(width: 8),
          stripPill(
            icon: Icons.grid_view_rounded,
            iconColor: colors.gold,
            label: 'All 114 Surahs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranHubScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyReadSection(AppColors colors) {
    return AnimatedBuilder(
      animation: UserDataService.instance,
      builder: (context, _) {
        final recent = UserDataService.instance.recent;
        if (recent.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, size: 16, color: colors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Continue Reciting',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final entry = recent[idx];
                    final isAr = entry.isRtl || AppTheme.containsArabic(entry.title);
                    return Material(
                      color: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: BorderSide(color: colors.separator),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LyricDetailScreen(
                              item: entry.toLyricItem(),
                            ),
                          ),
                        ),
                        child: Container(
                          width: 175,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                entry.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                                style: isAr
                                    ? AppTheme.arabicTextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      )
                                    : TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.categoryKey,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            '${featured.length} Sections',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: featured.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.05,
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
      if (widget.onOpenDuaCategory != null) {
        widget.onOpenDuaCategory!(cat.key);
        return;
      }
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: colors.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppCategories.getIcon(cat.key),
                  color: colors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      cat.count > 0 ? '${cat.count} items' : (urduSubtitle ?? 'Recitations'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (urduSubtitle != null)
                      Text(
                        urduSubtitle!,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.arabicTextStyle(
                          fontSize: 12.5,
                          color: colors.accent,
                          height: 1.15,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
