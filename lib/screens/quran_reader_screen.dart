import 'package:flutter/gestures.dart';
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

  // Default to authentic continuous Mushaf page layout; user can toggle to verse-by-verse.
  bool _mushafMode = true;
  int? _selectedAyahNumber;
  final List<TapGestureRecognizer> _recognizers = [];

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
    _disposeRecognizers();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  void _goToSurah(int nextNum) {
    if (nextNum < 1 || nextNum > 114) return;
    HapticFeedback.selectionClick();
    setState(() {
      _surahNumber = nextNum;
      _selectedAyahNumber = null;
    });
    QuranService.instance.saveLastRead(nextNum, 1);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
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

  /// Opens a bottom sheet with Roman transliteration, English translation,
  /// audio playback, bookmark, and copy actions when an Ayah is tapped in Mushaf mode.
  void _showAyahDetailSheet(QuranSurah surah, QuranAyah ayah) {
    HapticFeedback.selectionClick();
    setState(() => _selectedAyahNumber = ayah.numberInSurah);
    QuranService.instance.saveLastRead(surah.number, ayah.numberInSurah);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: Listenable.merge([QuranService.instance, QuranAudioService.instance]),
          builder: (context, _) {
            final colors = AppColors.of(context);
            final q = QuranService.instance;
            final audio = QuranAudioService.instance;
            final isBookmarked = q.isBookmarked(surah.number, ayah.numberInSurah);
            final isPlaying = audio.isPlaying && audio.playingAyahGlobal == ayah.globalNumber;

            return Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: colors.separator)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${surah.englishName} · ${surah.number}:${ayah.numberInSurah} · Para ${ayah.juz}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Close',
                          icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        '${ayah.arabic} ۝${QuranService.toArabicDigits(ayah.numberInSurah)}',
                        textAlign: TextAlign.right,
                        style: AppTheme.arabicTextStyle(
                          fontSize: 24,
                          height: 1.8,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ayah.roman,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        color: colors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ayah.english,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => audio.playAyah(ayah),
                            icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            label: Text(isPlaying ? 'Pause' : 'Play Ayah'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Ayah',
                          onPressed: () => q.toggleBookmark(surah.number, ayah.numberInSurah),
                          icon: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton.filledTonal(
                          tooltip: 'Copy Ayah',
                          onPressed: () {
                            _copyAyah(ayah, surah);
                            Navigator.pop(ctx);
                          },
                          icon: Icon(Icons.copy_rounded, color: colors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _selectedAyahNumber = null);
    });
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
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Mushaf Page'),
                          icon: Icon(Icons.menu_book_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Translation'),
                          icon: Icon(Icons.translate_rounded, size: 16),
                        ),
                      ],
                      selected: {_mushafMode},
                      onSelectionChanged: (sel) {
                        setState(() => _mushafMode = sel.first);
                      },
                    ),
                    const SizedBox(height: 12),
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
                    if (!_mushafMode) ...[
                      const SizedBox(height: 10),
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
                    ],
                    const SizedBox(height: 10),
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
                      value: s.arabicFontSize.clamp(24.0, 52.0),
                      min: 24,
                      max: 52,
                      divisions: 14,
                      activeColor: colors.accent,
                      onChanged: (v) {
                        s.arabicFontSize = v;
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
                : const Color(0xFFFAF6EC);
        final readerText = isNight ? const Color(0xFFF2F5F3) : const Color(0xFF141816);
        final readerSub = isNight ? const Color(0xFFB8C4BC) : const Color(0xFF424D46);
        final cardBg = isNight ? const Color(0xFF1B221D) : const Color(0xFFFFFDF7);

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
                        'Surah ${surah.number} · ${surah.ayahCount} Ayahs · Para ${surah.ayahs.first.juz}',
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
            actions: [
              // Quick toggle between Mushaf Page and Translation View
              IconButton(
                key: const Key('quran_view_mode_toggle'),
                tooltip: _mushafMode ? 'Switch to Roman & English View' : 'Switch to Mushaf Page',
                icon: Icon(
                  _mushafMode ? Icons.translate_rounded : Icons.menu_book_rounded,
                  size: 21,
                  color: colors.accent,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _mushafMode = !_mushafMode);
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 21),
                tooltip: 'Display & Font Settings',
                onPressed: _showDisplaySettingsSheet,
              ),
            ],
          ),
          body: surah == null
              ? Center(child: CircularProgressIndicator(color: colors.accent))
              : _mushafMode
                  ? _buildMushafPageView(
                      surah: surah,
                      colors: colors,
                      pageBg: cardBg,
                      readerText: readerText,
                      readerSub: readerSub,
                      arabicSize: s.arabicFontSize.clamp(24.0, 52.0),
                      audio: audio,
                    )
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
                          arabicSize: s.arabicFontSize.clamp(24.0, 52.0),
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

  static const String _uthmaniBismillah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  /// Strips the prepended Bismillah from Ayah 1 of Surahs 2–114 (except Surah 9)
  /// since the Surah header already renders Bismillah prominently above the text.
  String _displayArabic(QuranSurah surah, QuranAyah ayah) {
    if (surah.number != 1 && surah.number != 9 && ayah.numberInSurah == 1) {
      final trimmed = ayah.arabic.trimLeft();
      if (trimmed.startsWith(_uthmaniBismillah)) {
        final rest = trimmed.substring(_uthmaniBismillah.length).trimLeft();
        if (rest.isNotEmpty) return rest;
      }
    }
    return ayah.arabic;
  }

  /// Authentic continuous Mushaf page layout with ornamental double gold border
  /// and inline tappable ayahs + medallions (`۝١`, `۝٢`, ...).
  Widget _buildMushafPageView({
    required QuranSurah surah,
    required AppColors colors,
    required Color pageBg,
    required Color readerText,
    required Color readerSub,
    required double arabicSize,
    required QuranAudioService audio,
  }) {
    _disposeRecognizers();
    final showBismillah = surah.number != 1 && surah.number != 9;
    final goldBorder = colors.gold.withValues(alpha: 0.72);
    final spans = <InlineSpan>[];

    for (final ayah in surah.ayahs) {
      final isHighlighted = _selectedAyahNumber == ayah.numberInSurah ||
          (audio.isPlaying && audio.playingAyahGlobal == ayah.globalNumber);
      final rec = TapGestureRecognizer()
        ..onTap = () => _showAyahDetailSheet(surah, ayah);
      _recognizers.add(rec);

      spans.add(
        TextSpan(
          text: '${_displayArabic(surah, ayah)} ',
          recognizer: rec,
          style: AppTheme.arabicTextStyle(
            fontSize: arabicSize,
            height: 2.05,
            color: readerText,
          ).copyWith(
            backgroundColor: isHighlighted ? colors.accentSoft : null,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: '۝${QuranService.toArabicDigits(ayah.numberInSurah)} ',
          recognizer: rec,
          style: AppTheme.arabicTextStyle(
            fontSize: (arabicSize * 0.88).clamp(20.0, 42.0),
            height: 2.05,
            color: colors.gold,
          ).copyWith(
            backgroundColor: isHighlighted ? colors.accentSoft : null,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
      child: Column(
        children: [
          // Outer Mushaf Gold Frame
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: pageBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: goldBorder, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: goldBorder.withValues(alpha: 0.55), width: 0.9),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ornamental Surah Title Cartouche
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.accentSoft.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: goldBorder, width: 1.1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          surah.arabicName,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: AppTheme.arabicTextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${surah.englishName} · ${surah.revelationType} · ${surah.ayahCount} Ayahs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: readerSub,
                          ),
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
                        fontSize: (arabicSize * 0.92).clamp(22.0, 42.0),
                        fontWeight: FontWeight.w600,
                        color: colors.gold,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Continuous Flowing Mushaf Text
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text.rich(
                      TextSpan(children: spans),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Tap any Ayah for Roman, English & Audio',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSurahFooterNav(colors),
        ],
      ),
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
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              '${_displayArabic(surah, ayah)}  ۝$arabicBadge',
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
