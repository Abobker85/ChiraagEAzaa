import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quran_models.dart';
import '../services/quran_audio_service.dart';
import '../services/quran_service.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/quran_audio_bar.dart';

class QuranReaderScreen extends StatefulWidget {
  final int initialSurahNumber;
  final int initialAyahNumber;

  const QuranReaderScreen({
    super.key,
    required this.initialSurahNumber,
    this.initialAyahNumber = 1,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late int _surahNumber;
  final ScrollController _scrollController = ScrollController();

  QuranSurah? get _surah => QuranService.instance.getSurah(_surahNumber);

  @override
  void initState() {
    super.initState();
    _surahNumber = widget.initialSurahNumber.clamp(1, 114);
    QuranService.instance.ensureLoaded().then((_) {
      if (mounted) {
        QuranService.instance.saveLastRead(_surahNumber, widget.initialAyahNumber);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToSurah(int nextNum) {
    if (nextNum < 1 || nextNum > 114) return;
    HapticFeedback.selectionClick();
    setState(() => _surahNumber = nextNum);
    QuranService.instance.saveLastRead(nextNum, 1);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _showDisplaySettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: Listenable.merge([AppSettings.instance, QuranService.instance]),
          builder: (context, _) {
            final s = AppSettings.instance;
            final q = QuranService.instance;
            final colors = AppColors.of(context);
            return Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: colors.separator)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.separator,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Quran Display & Typography',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'paper', label: Text('Paper')),
                        ButtonSegment(value: 'light', label: Text('Light')),
                        ButtonSegment(value: 'dark', label: Text('Night')),
                      ],
                      selected: {s.readerSurface},
                      onSelectionChanged: (sel) {
                        s.readerSurface = sel.first;
                        s.save();
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Roman English Transliteration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      activeThumbColor: colors.accent,
                      activeTrackColor: colors.accentSoft,
                      value: q.showRoman,
                      onChanged: (v) => q.setShowRoman(v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'English Translation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      activeThumbColor: colors.accent,
                      activeTrackColor: colors.accentSoft,
                      value: q.showEnglish,
                      onChanged: (v) => q.setShowEnglish(v),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Arabic Script Size',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${s.arabicFontSize.toInt()} pt',
                          style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: s.arabicFontSize.clamp(24.0, 56.0),
                      min: 24,
                      max: 56,
                      divisions: 16,
                      activeColor: colors.accent,
                      onChanged: (v) {
                        s.arabicFontSize = v;
                        s.save();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Roman / English Size',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${s.ltrFontSize.toInt()} pt',
                          style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: s.ltrFontSize.clamp(13.0, 24.0),
                      min: 13,
                      max: 24,
                      divisions: 11,
                      activeColor: colors.accent,
                      onChanged: (v) {
                        s.ltrFontSize = v;
                        s.save();
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentSoft,
                        foregroundColor: colors.accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _copyAyah(QuranAyah ayah, QuranSurah surah) {
    final text = '${surah.englishName} (${surah.number}:${ayah.numberInSurah})\n'
        '${ayah.arabic}\n\n'
        '${ayah.roman}\n\n'
        '${ayah.english}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayah copied (Arabic + Roman + English)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final surah = _surah;

    return AnimatedBuilder(
      animation: Listenable.merge([
        AppSettings.instance,
        QuranService.instance,
        QuranAudioService.instance,
      ]),
      builder: (context, _) {
        final s = AppSettings.instance;
        final q = QuranService.instance;
        final audio = QuranAudioService.instance;
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        final isNight = s.readerSurface == 'dark' ||
            (s.readerSurface != 'light' && isDarkTheme);
        final readerBg = s.readerSurface == 'dark'
            ? const Color(0xFF141815)
            : s.readerSurface == 'light'
                ? (isDarkTheme ? colors.bg : Colors.white)
                : colors.paperBg;
        final readerText = isNight ? const Color(0xFFF2F5F3) : const Color(0xFF141816);
        final readerSub = isNight ? const Color(0xFFB8C4BC) : const Color(0xFF424D46);
        final cardBg = isNight ? const Color(0xFF1C231E) : Colors.white;

        return Scaffold(
          backgroundColor: readerBg,
          appBar: AppBar(
            backgroundColor: colors.card,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: surah == null
                ? const Text('Holy Quran')
                : Column(
                    children: [
                      Text(
                        surah.englishName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Surah ${surah.number} · ${surah.ayahCount} Ayahs',
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 21),
                tooltip: 'Display & Font Settings',
                onPressed: _showDisplaySettingsSheet,
              ),
            ],
          ),
          body: surah == null
              ? Center(child: CircularProgressIndicator(color: colors.accent))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                  itemCount: surah.ayahs.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSurahHeader(surah, colors, cardBg, readerSub);
                    }
                    if (index == surah.ayahs.length + 1) {
                      return _buildSurahFooterNav(colors);
                    }
                    final ayah = surah.ayahs[index - 1];
                    final isSaved = q.isBookmarked(surah.number, ayah.numberInSurah);
                    final isPlayingAyah =
                        audio.isPlaying && audio.playingAyahGlobal == ayah.globalNumber;
                    return _buildAyahCard(
                      surah: surah,
                      ayah: ayah,
                      colors: colors,
                      cardBg: cardBg,
                      readerText: readerText,
                      readerSub: readerSub,
                      arabicSize: s.arabicFontSize.clamp(24.0, 56.0),
                      latinSize: s.ltrFontSize.clamp(13.0, 24.0),
                      showRoman: q.showRoman,
                      showEnglish: q.showEnglish,
                      isBookmarked: isSaved,
                      isPlaying: isPlayingAyah,
                    );
                  },
                ),
          bottomNavigationBar: surah == null ? null : QuranAudioBar(surah: surah),
        );
      },
    );
  }

  Widget _buildSurahHeader(
    QuranSurah surah,
    AppColors colors,
    Color cardBg,
    Color subColor,
  ) {
    final showBismillah = surah.number != 1 && surah.number != 9;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.gold.withValues(alpha: 0.65),
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              Text(
                surah.arabicName,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: AppTheme.arabicTextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${surah.englishName} · ${surah.englishTranslation}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${surah.revelationType} · ${surah.ayahCount} Ayahs',
                style: TextStyle(fontSize: 11.5, color: colors.gold),
              ),
            ],
          ),
        ),
        if (showBismillah) ...[
          const SizedBox(height: 14),
          Text(
            'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: AppTheme.arabicTextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: colors.gold,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildAyahCard({
    required QuranSurah surah,
    required QuranAyah ayah,
    required AppColors colors,
    required Color cardBg,
    required Color readerText,
    required Color readerSub,
    required double arabicSize,
    required double latinSize,
    required bool showRoman,
    required bool showEnglish,
    required bool isBookmarked,
    required bool isPlaying,
  }) {
    final arabicBadge = QuranService.toArabicDigits(ayah.numberInSurah);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isPlaying ? colors.accentSoft.withValues(alpha: 0.45) : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? colors.accent : colors.separator,
          width: isPlaying ? 1.3 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top action bar: Ayah number pill + Play / Bookmark / Copy
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${surah.number}:${ayah.numberInSurah}  ·  Para ${ayah.juz}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: isPlaying ? 'Pause Ayah' : 'Play Ayah',
                icon: Icon(
                  isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_outline_rounded,
                  size: 21,
                  color: colors.accent,
                ),
                onPressed: () {
                  QuranService.instance.saveLastRead(surah.number, ayah.numberInSurah);
                  QuranAudioService.instance.playAyah(ayah);
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Ayah',
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 20,
                  color: isBookmarked ? colors.accent : colors.textSecondary,
                ),
                onPressed: () =>
                    QuranService.instance.toggleBookmark(surah.number, ayah.numberInSurah),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy Ayah',
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
                onPressed: () => _copyAyah(ayah, surah),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Arabic Calligraphy with traditional ayah end medallion
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              '${ayah.arabic}  ۝$arabicBadge',
              textAlign: TextAlign.right,
              style: AppTheme.arabicTextStyle(
                fontSize: arabicSize,
                height: 1.9,
                color: readerText,
              ),
            ),
          ),
          if (showRoman) ...[
            const SizedBox(height: 10),
            Text(
              ayah.roman,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: latinSize,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: colors.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (showEnglish) ...[
            const SizedBox(height: 8),
            Text(
              ayah.english,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: latinSize,
                height: 1.55,
                color: readerSub,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSurahFooterNav(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _surahNumber > 1 ? () => _goToSurah(_surahNumber - 1) : null,
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
            label: const Text('Previous Surah'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accent,
              side: BorderSide(color: colors.separator),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _surahNumber < 114 ? () => _goToSurah(_surahNumber + 1) : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: const Text('Next Surah'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accent,
              side: BorderSide(color: colors.separator),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
