import 'package:flutter/material.dart';
import '../models/quran_models.dart';
import '../services/database_service.dart';
import '../services/quran_service.dart';
import '../theme.dart';
import 'lyric_detail_screen.dart';
import 'quran_reader_screen.dart';

/// Holy Quran Hub with Surah Wise (114), Para / Juz Wise (30), Saved Ayahs,
/// Continue Reading banner, and instant search across Surahs and Ayahs.
class QuranHubScreen extends StatefulWidget {
  const QuranHubScreen({super.key});

  @override
  State<QuranHubScreen> createState() => _QuranHubScreenState();
}

class _QuranHubScreenState extends State<QuranHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    await QuranService.instance.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSurah(int surahNumber, {int ayahNumber = 1}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
          initialSurahNumber: surahNumber,
          initialAyahNumber: ayahNumber,
        ),
      ),
    );
  }

  Future<void> _openQuranDua(String title) async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: QuranService.instance,
      builder: (context, _) {
        final q = QuranService.instance;
        return Scaffold(
          backgroundColor: colors.bg,
          appBar: AppBar(
            backgroundColor: colors.card,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'القرآن الكريم',
              textDirection: TextDirection.rtl,
              style: AppTheme.arabicTextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.accent,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(112),
              child: Column(
                children: [
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
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search Surah name, number or Ayah...',
                          hintStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.accent),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 16, color: colors.textSecondary),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    height: 42,
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
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: colors.textSecondary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      tabs: const [
                        Tab(text: 'Surah Wise'),
                        Tab(text: 'Para Wise'),
                        Tab(text: 'Khatm'),
                        Tab(text: 'Saved'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator(color: colors.accent))
              : _query.trim().isNotEmpty
                  ? _buildSearchResults(q, colors)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSurahList(q, colors),
                        _buildParaList(q, colors),
                        _buildKhatmTracker(q, colors),
                        _buildSavedList(q, colors),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildSurahList(QuranService q, AppColors colors) {
    final lastSurah = q.lastReadSurah != null ? q.getSurah(q.lastReadSurah!) : null;
    final headerCount = 1 + (lastSurah != null ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: q.surahs.length + headerCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildQuranDuaShortcuts(colors);
        }
        if (lastSurah != null && index == 1) {
          return _buildContinueReadingBanner(lastSurah, q.lastReadAyah ?? 1, colors);
        }
        final surah = q.surahs[index - headerCount];
        return _surahTile(surah, colors);
      },
    );
  }

  Widget _buildQuranDuaShortcuts(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: const Key('hub_dua_before_quran'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openQuranDua('Dua Before Reciting Holy Quran'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 15, color: colors.gold),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Before Quran Dua',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              key: const Key('hub_dua_after_quran'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openQuranDua('Dua After Reciting Holy Quran'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded, size: 15, color: colors.gold),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'After Quran Dua',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
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

  Widget _buildKhatmTracker(QuranService q, AppColors colors) {
    final done = q.completedParas.length;
    final progress = done / 30.0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.gold.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: colors.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khatm-e-Quran Tracker',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tap each Para as you complete it for Isaal-e-Sawab',
                          style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (done > 0)
                    TextButton(
                      onPressed: q.resetKhatm,
                      child: Text(
                        'Reset',
                        style: TextStyle(fontSize: 12, color: colors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$done of 30 Paras Completed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colors.inputFill,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.05,
          ),
          itemCount: 30,
          itemBuilder: (context, idx) {
            final juz = idx + 1;
            final isDone = q.isParaCompleted(juz);
            return Material(
              color: isDone ? colors.accent : colors.card,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: Key('khatm_para_$juz'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => q.toggleParaCompleted(juz),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone ? colors.accent : colors.separator,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDone)
                        const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                      Text(
                        'Para $juz',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDone ? Colors.white : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContinueReadingBanner(QuranSurah surah, int ayahNum, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF165225), Color(0xFF0D3316)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.45)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSurah(surah.number, ayahNumber: ayahNum),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONTINUE READING',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.englishName} · Ayah $ayahNum',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  surah.arabicName,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _surahTile(QuranSurah surah, AppColors colors) {
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
          onTap: () => _openSurah(surah.number),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${surah.number}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
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
                        surah.englishName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '${surah.englishTranslation} · ${surah.ayahCount} Ayahs',
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
                const SizedBox(width: 8),
                Text(
                  surah.arabicName,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicTextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParaList(QuranService q, AppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: q.juzList.length,
      itemBuilder: (context, index) {
        final juz = q.juzList[index];
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
              onTap: () => _openSurah(
                juz.startSurahNumber,
                ayahNumber: juz.startAyahNumber,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.goldSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.gold.withValues(alpha: 0.35)),
                      ),
                      child: Center(
                        child: Text(
                          '${juz.juzNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.gold,
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
                            'Para ${juz.juzNumber} (Juz ${juz.juzNumber})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Starts at ${juz.startSurahEnglish} (${juz.startSurahNumber}:${juz.startAyahNumber})',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedList(QuranService q, AppColors colors) {
    final saved = q.getBookmarkedAyahs();
    if (saved.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border_rounded, size: 48, color: colors.textTertiary),
              const SizedBox(height: 12),
              Text(
                'No bookmarked ayahs yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the bookmark icon on any Ayah while reading to save it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: saved.length,
      itemBuilder: (context, i) {
        final ayah = saved[i];
        final surah = q.getSurah(ayah.surahNumber);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.separator),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openSurah(ayah.surahNumber, ayahNumber: ayah.numberInSurah),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${surah?.englishName ?? 'Surah ${ayah.surahNumber}'} · Ayah ${ayah.numberInSurah}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ayah.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.arabicTextStyle(
                      fontSize: 22,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ayah.english,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(QuranService q, AppColors colors) {
    final queryLower = _query.trim().toLowerCase();
    final matchingSurahs = q.surahs.where((s) {
      return s.number.toString() == queryLower ||
          s.englishName.toLowerCase().contains(queryLower) ||
          s.englishTranslation.toLowerCase().contains(queryLower) ||
          s.arabicName.contains(_query.trim());
    }).toList();

    final matchingAyahs = q.searchAyahs(_query, limit: 25);

    if (matchingSurahs.isEmpty && matchingAyahs.isEmpty) {
      return Center(
        child: Text(
          'No Quran matches for "$_query"',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        if (matchingSurahs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'SURAHS (${matchingSurahs.length})',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          ...matchingSurahs.map((s) => _surahTile(s, colors)),
        ],
        if (matchingAyahs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Text(
              'AYAHS (${matchingAyahs.length})',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
          ...matchingAyahs.map((a) {
            final surah = q.getSurah(a.surahNumber);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.separator),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openSurah(a.surahNumber, ayahNumber: a.numberInSurah),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${surah?.englishName ?? ''} (${a.surahNumber}:${a.numberInSurah})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.arabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.arabicTextStyle(
                          fontSize: 21,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.roman,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
