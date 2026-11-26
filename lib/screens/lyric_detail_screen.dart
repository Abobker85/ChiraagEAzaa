import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../services/dua_language_service.dart';
import '../services/settings_service.dart';
import '../services/user_data_service.dart';
import '../widgets/auto_scroll_controls.dart';

class LyricDetailScreen extends StatefulWidget {
  final LyricItem item;
  final List<LyricItem>? playlist;
  final int? initialIndex;

  const LyricDetailScreen({
    super.key,
    required this.item,
    this.playlist,
    this.initialIndex,
  });

  /// Sanitizes scraped lyric HTML for full-width LTR rendering in `flutter_html`.
  ///
  /// `flutter_html` 3.0.0 parses CSS percentage widths (e.g. `style=width:100%`)
  /// into `Width(0, Unit.px)` because `ExpressionMapping.expressionToLengthOrPercent`
  /// does not handle `PercentageTerm`, collapsing the container to 0px width and
  /// wrapping text one character per line. Stripping inline `style`, `width`, and
  /// `height` attributes (plus non-content `<script>`, `<style>`, `<iframe>` blocks)
  /// preserves all lyric text while letting the reader own layout and typography.
  static String sanitizeLtrHtml(String raw) {
    var cleaned = raw
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<iframe[\s\S]*?<\/iframe>', caseSensitive: false), '');

    final attrPattern = RegExp(
      r'''\s+(?:style|width|height)\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)''',
      caseSensitive: false,
    );

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'<[a-zA-Z][^>]*>'),
      (match) => match.group(0)!.replaceAll(attrPattern, ''),
    );

    // Ensure any inline Arabic/Urdu text runs inside LTR HTML use the Quranic
    // ScheherazadeNew font via the `.ar` CSS class.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'>([^<]*[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF][^<]*)<'),
      (m) => '><span class="ar">${m.group(1)}</span><',
    );

    return cleaned;
  }

  @override
  State<LyricDetailScreen> createState() => _LyricDetailScreenState();
}

class _LyricDetailScreenState extends State<LyricDetailScreen> {
  late List<LyricItem> _playlist;
  late int _currentIndex;
  late PageController _pageController;

  // Cached content HTML per lyric ID to prevent re-fetching on swipes
  final Map<int, String?> _contentCache = {};
  final AutoScrollController _autoScroll = AutoScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      _playlist = List<LyricItem>.from(widget.playlist!);
      final idx = widget.initialIndex ?? _playlist.indexOf(widget.item);
      _currentIndex = (idx >= 0 && idx < _playlist.length) ? idx : 0;
    } else {
      _playlist = [widget.item];
      _currentIndex = 0;
      _loadPlaylistFromDb();
    }

    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<void> _loadPlaylistFromDb() async {
    final db = DatabaseService.instance;
    final items = await db.getLyricsByCategory(widget.item.categoryKey);
    if (!mounted || items.isEmpty || items.length <= 1) return;
    final idx = items.indexWhere((it) => it.id == widget.item.id);
    setState(() {
      _playlist = items;
      _currentIndex = idx >= 0 ? idx : 0;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  void dispose() {
    _autoScroll.dispose();
    _pageController.dispose();
    _toastEntry?.remove();
    super.dispose();
  }

  LyricItem get _currentItem => _playlist[_currentIndex];

  bool get _isCurrentRtl {
    final catKey = _currentItem.categoryKey.split('/').first;
    return _currentItem.isRtl || catKey == 'duas' || catKey == 'ziyaraat' || catKey == 'munaejaat';
  }

  Future<void> _toggleSave() async {
    final id = _currentItem.id;
    final isSaved = SavedManager.instance.isSaved(id);
    if (isSaved) {
      await DatabaseService.instance.removeBookmark(id);
    } else {
      await DatabaseService.instance.addBookmark(id);
    }
    setState(() {});
    _toast(isSaved ? 'Removed from saved' : 'Saved to bookmarks');
  }

  void _copy(String? html) {
    if (html == null) return;
    final plain = html.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&amp;', '&');
    Clipboard.setData(ClipboardData(text: plain));
    _toast('Copied to clipboard');
  }

  OverlayEntry? _toastEntry;
  void _toast(String msg) {
    _toastEntry?.remove();
    final overlay = Overlay.of(context);
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 90,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2620),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toastEntry!);
    Future.delayed(const Duration(milliseconds: 2200), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  void _showReciterNoteSheet() {
    final item = _currentItem;
    final ctrl = TextEditingController(
      text: UserDataService.instance.getNote(item.id) ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(top: BorderSide(color: colors.separator)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                  Text(
                    'Personal Reciter Note',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const Key('lyric_note_input'),
                    controller: ctrl,
                    minLines: 3,
                    maxLines: 6,
                    autofocus: true,
                    style: TextStyle(fontSize: 14, color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g., Start slow here, Repeat 3x, Recited on 7th Muharram...',
                      hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
                      filled: true,
                      fillColor: colors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (UserDataService.instance.hasNote(item.id))
                        TextButton(
                          onPressed: () async {
                            await UserDataService.instance.saveNote(item.id, '');
                            if (ctx.mounted) Navigator.pop(ctx);
                            _toast('Note cleared');
                          },
                          child: const Text('Clear', style: TextStyle(color: AppTheme.errorRed)),
                        ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('lyric_note_save_btn'),
                        onPressed: () async {
                          await UserDataService.instance.saveNote(item.id, ctrl.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _toast('Note saved');
                        },
                        child: const Text('Save Note'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFontSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: AppSettings.instance,
          builder: (context, _) {
            final s = AppSettings.instance;
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
                      'Reading & Typography',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Reading Surface Selector (Paper / Light / Dark)
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
                    const SizedBox(height: 16),
                    // Roman / English Font Size
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
                      value: s.ltrFontSize.clamp(14.0, 26.0),
                      min: 14,
                      max: 26,
                      divisions: 12,
                      activeColor: colors.accent,
                      onChanged: (v) {
                        s.ltrFontSize = v;
                        s.save();
                      },
                    ),
                    // Arabic Calligraphy Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Arabic Calligraphy Size',
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
                      value: s.arabicFontSize.clamp(28.0, 70.0),
                      min: 28,
                      max: 70,
                      divisions: 21,
                      activeColor: colors.accent,
                      onChanged: (v) {
                        s.arabicFontSize = v;
                        s.save();
                      },
                    ),
                    // Line Spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Line Height (التباعد)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          s.lineHeight.toStringAsFixed(1),
                          style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: s.lineHeight.clamp(1.4, 2.8),
                      min: 1.4,
                      max: 2.8,
                      divisions: 14,
                      activeColor: colors.accent,
                      onChanged: (v) {
                        s.lineHeight = v;
                        s.save();
                      },
                    ),
                    const SizedBox(height: 10),
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

  void _showPlaylistIndexSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _playlist.asMap().entries.where((entry) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase();
              return entry.value.title.toLowerCase().contains(q) ||
                  entry.value.subtitle.toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Header handle
                      const SizedBox(height: 10),
                      Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Table of Recitations (الفهرس)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.greenPale,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_playlist.length} items',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Search inside sheet
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            onChanged: (val) => setModalState(() => query = val),
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Filter recitations...',
                              prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.green),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, thickness: 0.5),
                      // List of items
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 16,
                            color: AppTheme.separator,
                          ),
                          itemBuilder: (context, i) {
                            final entry = filtered[i];
                            final realIndex = entry.key;
                            final item = entry.value;
                            final isCurrent = realIndex == _currentIndex;
                            final isSaved = SavedManager.instance.isSaved(item.id);

                            return ListTile(
                              selected: isCurrent,
                              selectedTileColor: AppTheme.greenPale.withValues(alpha: 0.5),
                              leading: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppTheme.green : AppTheme.bg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${realIndex + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                item.title,
                                textDirection: AppTheme.containsArabic(item.title)
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: AppTheme.containsArabic(item.title)
                                    ? AppTheme.arabicTextStyle(
                                        fontSize: 14,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                        color: isCurrent ? AppTheme.green : AppTheme.textPrimary,
                                      )
                                    : TextStyle(
                                        fontSize: 14,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                        color: isCurrent ? AppTheme.green : AppTheme.textPrimary,
                                      ),
                              ),
                              subtitle: item.subtitle.isNotEmpty
                                  ? Text(
                                      item.subtitle,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSaved)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(Icons.bookmark, color: AppTheme.green, size: 16),
                                    ),
                                  if (isCurrent)
                                    const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 18),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                if (realIndex != _currentIndex) {
                                  _pageController.animateToPage(
                                    realIndex,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = _playlist.length > 1;
    final isSaved = SavedManager.instance.isSaved(_currentItem.id);
    final colors = AppColors.of(context);
    final catKey = _currentItem.categoryKey.split('/').first;
    final isDuaFamily = catKey == 'duas' || catKey == 'ziyaraat' || catKey == 'munaejaat';
    final appBarLabel = isDuaFamily ? 'Supplications' : 'Recitations';

    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final surface = AppSettings.instance.readerSurface;
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        final readerBg = surface == 'dark'
            ? const Color(0xFF141815)
            : surface == 'light'
                ? (isDarkTheme ? colors.bg : Colors.white)
                : (_isCurrentRtl ? colors.paperBg : colors.bg);

        return Scaffold(
          backgroundColor: readerBg,
          appBar: AppBar(
            backgroundColor: colors.card,
            foregroundColor: colors.textPrimary,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              appBarLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.format_size_rounded, size: 20),
                tooltip: 'Text Size',
                onPressed: _showFontSettingsSheet,
              ),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? colors.accent : null,
                  size: 21,
                ),
                tooltip: 'Bookmark',
                onPressed: _toggleSave,
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 19),
                tooltip: 'Copy Text',
                onPressed: () => _copy(_contentCache[_currentItem.id]),
              ),
            ],
          ),
          body: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _playlist.length,
                onPageChanged: (idx) {
                  _autoScroll.pause();
                  setState(() {
                    _currentIndex = idx;
                  });
                  UserDataService.instance.recordRecent(_playlist[idx]);
                },
                itemBuilder: (context, index) {
                  final item = _playlist[index];
                  return _LyricPageView(
                    item: item,
                    indexInPlaylist: index,
                    totalInPlaylist: _playlist.length,
                    autoScroll: _autoScroll,
                    isActive: index == _currentIndex,
                    onTapReciterNote: _showReciterNoteSheet,
                    onContentLoaded: (html) {
                      _contentCache[item.id] = html;
                    },
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Center(child: AutoScrollBar(controller: _autoScroll)),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(colors, hasMultiple),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(AppColors colors, bool hasMultiple) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex >= _playlist.length - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockBg = isDark ? const Color(0xFF142419) : const Color(0xFF0E3D19);
    const activeFg = Colors.white;
    final disabledFg = Colors.white.withValues(alpha: 0.36);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: dockBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.gold.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              if (hasMultiple) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isFirst
                      ? null
                      : () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 14,
                          color: isFirst ? disabledFg : activeFg,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Prev',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isFirst ? disabledFg : activeFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showPlaylistIndexSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 14,
                            color: Color(0xFFF3D57C),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_currentIndex + 1} / ${_playlist.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ] else ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Text Size',
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.format_size_rounded, size: 19, color: Colors.white),
                  onPressed: _showFontSettingsSheet,
                ),
                const Spacer(),
              ],
              AnimatedBuilder(
                animation: _autoScroll,
                builder: (_, __) {
                  final active = _autoScroll.isVisible;
                  return Material(
                    color: active
                        ? const Color(0xFFE7C462)
                        : Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: const Key('lyric_auto_scroll_toggle'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: _autoScroll.togglePanel,
                      child: Tooltip(
                        message: 'Auto-Scroll Teleprompter',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                active
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.slow_motion_video_rounded,
                                size: 15,
                                color: active ? const Color(0xFF142A19) : const Color(0xFFF3D57C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                active ? 'Scrolling' : 'Auto',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: active ? const Color(0xFF142A19) : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (hasMultiple) ...[
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isLast
                      ? null
                      : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut,
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isLast ? disabledFg : activeFg,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isLast ? disabledFg : activeFg,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
                IconButton(
                  key: const Key('lyric_dock_note_btn'),
                  tooltip: 'Personal Reciter Note',
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.sticky_note_2_outlined, size: 19, color: Color(0xFFF3D57C)),
                  onPressed: _showReciterNoteSheet,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
/// Structured recitation content block with script and role awareness.
class _ContentBlock {
  final String text;
  final bool isArabic;
  final bool isInstruction;

  const _ContentBlock({
    required this.text,
    required this.isArabic,
    this.isInstruction = false,
  });
}

/// Internal page view rendering the content of a single recitation.
class _LyricPageView extends StatefulWidget {
  final LyricItem item;
  final int indexInPlaylist;
  final int totalInPlaylist;
  final AutoScrollController autoScroll;
  final bool isActive;
  final VoidCallback onTapReciterNote;
  final ValueChanged<String?> onContentLoaded;

  const _LyricPageView({
    required this.item,
    required this.indexInPlaylist,
    required this.totalInPlaylist,
    required this.autoScroll,
    required this.isActive,
    required this.onTapReciterNote,
    required this.onContentLoaded,
  });

  @override
  State<_LyricPageView> createState() => _LyricPageViewState();
}

class _LyricPageViewState extends State<_LyricPageView> {
  String? _html;
  MultilangDua? _multilangDua;
  List<_ContentBlock> _blocks = [];
  bool _loading = true;
  late bool _isRtl;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  static String _categoryBadgeLabel(String rawKey) {
    final key = rawKey.split('/').first;
    switch (key) {
      case 'duas':
        return 'Duas · دعاء';
      case 'ziyaraat':
        return 'Ziyaraat · زیارت';
      case 'munaejaat':
        return 'Munajaat · مناجات';
      case 'nouhay':
        return 'Nouhay · نوحہ';
      case 'marsias':
        return 'Marsias · مرثیہ';
      case 'manqabat':
        return 'Manqabat · منقبت';
      case 'qasiday':
        return 'Qasiday · قصیدہ';
      case 'salaam':
        return 'Salaam · سلام';
      case 'urdu_poem':
        return 'Urdu · اردو';
      default:
        return key.isEmpty ? 'Recitation' : '${key[0].toUpperCase()}${key.substring(1)}';
    }
  }

  @override
  void initState() {
    super.initState();
    final catKey = widget.item.categoryKey.split('/').first;
    _isRtl = widget.item.isRtl ||
        catKey == 'duas' ||
        catKey == 'ziyaraat' ||
        catKey == 'munaejaat';

    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 400 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });

    if (widget.isActive) {
      widget.autoScroll.attach(_scrollController);
    }

    _load();
  }

  @override
  void didUpdateWidget(covariant _LyricPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) {
      widget.autoScroll.attach(_scrollController);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await DatabaseService.instance.getLyricDetail(widget.item.id);
    if (!mounted) return;
    final catKey = widget.item.categoryKey.split('/').first;
    final isDuaCat = catKey == 'duas' || catKey == 'ziyaraat' || catKey == 'munaejaat';
    if (isDuaCat) {
      await DuaLanguageService.instance.ensureLoaded();
      if (!mounted) return;
    }
    final raw = detail?.contentHtml;
    final multilang = isDuaCat
        ? DuaLanguageService.instance.getByTitle(widget.item.title)
        : null;
    final blocks = raw != null && _isRtl ? _parseBlocks(raw) : <_ContentBlock>[];
    setState(() {
      _html = raw;
      _multilangDua = multilang;
      _blocks = blocks;
      _loading = false;
    });
    if (widget.isActive) {
      UserDataService.instance.recordRecent(widget.item);
    }
    if (multilang != null) {
      final combined = multilang.verses
          .map((v) => '${v.arabic}\n${v.roman}\n${v.english}')
          .join('\n\n');
      widget.onContentLoaded(combined);
    } else {
      widget.onContentLoaded(raw);
    }
  }

  List<_ContentBlock> _parseBlocks(String raw) {
    // 1. Decode HTML entities first so Arabic entity codes turn into Arabic characters
    var text = _cleanHtmlEntities(raw)
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<div[^>]*id="urduTextPath"[^>]*>[\s\S]*?<\/div>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<\/?(div|span)[^>]*>', caseSensitive: false), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s*style="[^"]*"', caseSensitive: false), '')
        .trim();

    // 2. Normalize paragraph and break boundaries
    text = text.replaceAll(RegExp(r'<\/?(p|blockquote)[^>]*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n');

    // 3. Split transition from Latin punctuation directly into Arabic text
    text = text.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9\.\,\:\;\)\"]+[\:\.\!])\s*([\u0600-\u06FF])'),
      (m) => '${m.group(1)}\n\n${m.group(2)}',
    );

    final rawChunks = text.split(RegExp(r'\n{2,}'));
    final blocks = <_ContentBlock>[];

    for (final chunk in rawChunks) {
      final clean = chunk.replaceAll(RegExp(r'<[^>]+>'), '').trim();
      if (clean.isEmpty) continue;

      final arabicCount = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]').allMatches(clean).length;
      final latinCount = RegExp(r'[a-zA-Z]').allMatches(clean).length;

      final isArabic = arabicCount > latinCount;
      final lower = clean.toLowerCase();
      final isInstruction = !isArabic && (
        clean.endsWith(':') ||
        lower.contains('supplication') ||
        lower.contains('reported from') ||
        lower.contains('peace be upon') ||
        lower.contains('beseech') ||
        lower.contains('merits') ||
        lower.contains('repeat') ||
        lower.contains('times') ||
        lower.contains('then say')
      );

      blocks.add(_ContentBlock(
        text: clean,
        isArabic: isArabic,
        isInstruction: isInstruction,
      ));
    }

    return blocks;
  }

  static String _cleanHtmlEntities(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) =>
            String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
        .replaceAllMapped(RegExp(r'&#(\d+);'), (m) =>
            String.fromCharCode(int.parse(m.group(1)!)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            AppSettings.instance,
            DuaLanguageService.instance,
            UserDataService.instance,
          ]),
          builder: (context, _) {
            final s = AppSettings.instance;
            final colors = AppColors.of(context);
            final isNight = s.readerSurface == 'dark' ||
                (s.readerSurface != 'light' && Theme.of(context).brightness == Brightness.dark);
            final readerTextColor = isNight ? const Color(0xFFF2F5F3) : AppTheme.textPrimary;
            final cardBg = isNight ? const Color(0xFF1B221D) : const Color(0xFFFFFDF7);
            final fontSize = _isRtl ? s.rtlFontSize : s.ltrFontSize;

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSanctuaryHeroCard(colors, isNight),
                  _buildReciterNoteRibbon(colors, isNight),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.green),
                      ),
                    )
                  else if (_html == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64),
                      child: Center(
                        child: Text(
                          'Content not available',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    )
                  else if (_multilangDua != null)
                    ..._buildMultilangDuaView(
                      _multilangDua!,
                      s,
                      readerTextColor,
                      cardBg,
                      colors,
                      isNight,
                    )
                  else if (_isRtl)
                    ..._buildParsedBlocks(s, readerTextColor, colors)
                  else
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + s.paraSpacing),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Html(
                          data: LyricDetailScreen.sanitizeLtrHtml(_html!),
                          style: {
                            '.ar': Style(
                              fontFamily: AppTheme.arabicFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize((s.arabicFontSize * 0.85).clamp(20.0, 42.0)),
                              lineHeight: const LineHeight(2.0),
                              direction: TextDirection.rtl,
                            ),
                            'body': Style(
                              padding: HtmlPaddings.zero,
                              margin: Margins.zero,
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize),
                              lineHeight: LineHeight(s.lineHeight),
                              textAlign: TextAlign.left,
                            ),
                            'div': Style(
                              width: Width.auto(),
                              height: Height.auto(),
                              padding: HtmlPaddings.zero,
                              margin: Margins.zero,
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                            ),
                            '#urduTextPath': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.arabicFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize + 4),
                              textAlign: TextAlign.right,
                              direction: TextDirection.rtl,
                              margin: Margins.only(bottom: s.paraSpacing + 6),
                            ),
                            'table': Style(
                              width: Width.auto(),
                            ),
                            'span': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                            ),
                            'li': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize),
                              lineHeight: LineHeight(s.lineHeight),
                            ),
                            'p': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize),
                              lineHeight: LineHeight(s.lineHeight),
                              margin: Margins.only(bottom: s.paraSpacing),
                              textAlign: TextAlign.left,
                            ),
                            'h1': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize + 4),
                              lineHeight: LineHeight(s.lineHeight),
                              margin: Margins.only(bottom: s.paraSpacing + 4),
                              textAlign: TextAlign.left,
                            ),
                            'h2': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize + 3),
                              lineHeight: LineHeight(s.lineHeight),
                              margin: Margins.only(bottom: s.paraSpacing + 4),
                              textAlign: TextAlign.left,
                            ),
                            'h3': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize + 2),
                              lineHeight: LineHeight(s.lineHeight),
                              margin: Margins.only(bottom: s.paraSpacing + 4),
                              textAlign: TextAlign.left,
                            ),
                            'h4': Style(
                              color: readerTextColor,
                              fontFamily: AppTheme.uiFontFamily,
                              letterSpacing: 0,
                              fontSize: FontSize(fontSize + 1),
                              lineHeight: LineHeight(s.lineHeight),
                              margin: Margins.only(bottom: s.paraSpacing + 2),
                              textAlign: TextAlign.left,
                            ),
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (_showBackToTop)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              backgroundColor: AppTheme.green,
              foregroundColor: Colors.white,
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward_rounded, size: 18),
            ),
          ),
      ],
    );
  }

  Widget _buildSanctuaryHeroCard(AppColors colors, bool isNight) {
    final isTitleArabic = AppTheme.containsArabic(widget.item.title);
    final categoryLabel = _categoryBadgeLabel(widget.item.categoryKey);
    final hasMultiple = widget.totalInPlaylist > 1;
    final sub = _multilangDua != null && _multilangDua!.subtitle.isNotEmpty
        ? _multilangDua!.subtitle
        : widget.item.subtitle;
    final lang = DuaLanguageService.instance;

    final heroGradient = isNight
        ? const [Color(0xFF0E2915), Color(0xFF174523)]
        : const [Color(0xFF0D3B18), Color(0xFF1A5C28)];

    Widget heroLangChip(String label, bool active, VoidCallback onTap, Key key) {
      return Expanded(
        child: Material(
          color: active
              ? const Color(0xFFE7C462)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 13,
                    color: active ? const Color(0xFF122616) : Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: active ? const Color(0xFF122616) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: heroGradient,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.gold.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D3B18).withValues(alpha: isNight ? 0.32 : 0.16),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    categoryLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF6DF96),
                    ),
                  ),
                ),
                if (hasMultiple)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.indexInPlaylist + 1} of ${widget.totalInPlaylist}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.title,
              textAlign: TextAlign.center,
              textDirection: isTitleArabic ? TextDirection.rtl : TextDirection.ltr,
              style: isTitleArabic
                  ? AppTheme.arabicTextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      color: Colors.white,
                    )
                  : const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: Colors.white,
                    ),
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE7EFEA).withValues(alpha: 0.88),
                ),
              ),
            ],
            if (_multilangDua != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  heroLangChip(
                    'Arabic',
                    lang.showArabic,
                    lang.toggleArabic,
                    const Key('dua_lang_arabic'),
                  ),
                  const SizedBox(width: 8),
                  heroLangChip(
                    'Roman',
                    lang.showRoman,
                    lang.toggleRoman,
                    const Key('dua_lang_roman'),
                  ),
                  const SizedBox(width: 8),
                  heroLangChip(
                    'English',
                    lang.showEnglish,
                    lang.toggleEnglish,
                    const Key('dua_lang_english'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReciterNoteRibbon(AppColors colors, bool isNight) {
    final note = UserDataService.instance.getNote(widget.item.id);
    final hasNote = note != null && note.trim().isNotEmpty;
    final ribbonBg = isNight
        ? const Color(0xFF231F16)
        : const Color(0xFFFAF4E4);
    final ribbonBorder = isNight
        ? AppTheme.gold.withValues(alpha: 0.42)
        : const Color(0xFF9A7B2C).withValues(alpha: 0.38);
    final labelColor = isNight ? const Color(0xFFF3D57C) : const Color(0xFF6B500D);
    final bodyColor = isNight ? const Color(0xFFEDE8D8) : const Color(0xFF2A261B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Material(
        color: ribbonBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: widget.isActive ? const Key('lyric_note_btn') : null,
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTapReciterNote,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ribbonBorder, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: isNight ? 0.22 : 0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
                    size: 16,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: hasNote
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reciter Note',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: labelColor,
                              ),
                            ),
                            Text(
                              note.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: bodyColor,
                                height: 1.3,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Reciter Note',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: labelColor,
                              ),
                            ),
                            Text(
                              'Tap to add pitch & majlis cues',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: bodyColor.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isNight
                        ? AppTheme.gold.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ribbonBorder, width: 0.8),
                  ),
                  child: Text(
                    hasNote ? 'Edit' : 'Add',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildParsedBlocks(AppSettings s, Color textColor, AppColors colors) {
    if (_blocks.isEmpty) {
      if (_html == null) return [];
      final clean = _cleanHtmlEntities(_html!.replaceAll(RegExp(r'<[^>]+>'), '')).trim();
      final isAr = _isRtl || AppTheme.containsArabic(clean);
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Text(
              clean,
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              style: isAr
                  ? AppTheme.arabicTextStyle(
                      fontSize: s.arabicFontSize,
                      height: s.lineHeight + 0.3,
                      color: textColor,
                    )
                  : TextStyle(fontSize: s.ltrFontSize, color: textColor),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (int i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];

      if (block.isInstruction) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentSoft.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      block.text,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: s.ltrFontSize.clamp(13.0, 16.0),
                        height: 1.5,
                        color: textColor.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (!block.isArabic) {
        // English or Roman Urdu text (e.g. Munajaat poetry or title)
        final isTitle = i == 0 && block.text.length < 50;
        widgets.add(
          Padding(
            padding: EdgeInsets.fromLTRB(16, isTitle ? 8 : 4, 16, s.paraSpacing + (isTitle ? 12 : 6)),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                block.text,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: isTitle ? s.ltrFontSize + 3 : s.ltrFontSize,
                  fontWeight: isTitle ? FontWeight.bold : FontWeight.w500,
                  height: s.lineHeight,
                  color: isTitle ? colors.accent : textColor,
                ),
              ),
            ),
          ),
        );
      } else {
        // Arabic / Urdu script text (unified with Quran Mushaf ScheherazadeNew typography)
        widgets.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              widgets.isEmpty ? 8 : 4,
              16,
              s.paraSpacing + 16,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                block.text,
                textAlign: TextAlign.right,
                style: AppTheme.arabicTextStyle(
                  fontSize: s.arabicFontSize.clamp(24.0, 52.0),
                  height: 2.05,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildMultilangDuaView(
    MultilangDua dua,
    AppSettings s,
    Color textColor,
    Color cardBg,
    AppColors colors,
    bool isNight,
  ) {
    final lang = DuaLanguageService.instance;
    final goldBorder = colors.gold.withValues(alpha: isNight ? 0.38 : 0.32);
    final arabicSize = s.arabicFontSize.clamp(24.0, 52.0);
    final latinSize = s.ltrFontSize.clamp(13.0, 24.0);
    final romanInk = isNight ? const Color(0xFFE7C76E) : const Color(0xFF705310);
    final romanBg = isNight
        ? AppTheme.gold.withValues(alpha: 0.10)
        : const Color(0xFFFAF5E8);
    final verseBadgeBg = isNight ? const Color(0xFF213627) : const Color(0xFFE7EFEA);
    final verseBadgeInk = isNight ? const Color(0xFFB5DBC0) : const Color(0xFF1A5C28);

    return [
      for (int i = 0; i < dua.verses.length; i++)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: goldBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.18 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: verseBadgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: verseBadgeInk,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy verse',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: colors.textTertiary,
                    ),
                    onPressed: () {
                      final parts = <String>[
                        if (dua.verses[i].arabic.isNotEmpty) dua.verses[i].arabic,
                        if (dua.verses[i].roman.isNotEmpty) dua.verses[i].roman,
                        if (dua.verses[i].english.isNotEmpty) dua.verses[i].english,
                      ];
                      Clipboard.setData(ClipboardData(text: parts.join('\n')));
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (lang.showArabic && dua.verses[i].arabic.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    dua.verses[i].arabic,
                    textAlign: TextAlign.right,
                    style: AppTheme.arabicTextStyle(
                      fontSize: arabicSize,
                      height: 2.05,
                      color: textColor,
                    ),
                  ),
                ),
              if (lang.showRoman && dua.verses[i].roman.isNotEmpty) ...[
                if (lang.showArabic) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: romanBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dua.verses[i].roman,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: latinSize,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: romanInk,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (lang.showEnglish && dua.verses[i].english.isNotEmpty) ...[
                if (lang.showArabic || lang.showRoman) const SizedBox(height: 10),
                Text(
                  dua.verses[i].english,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: latinSize,
                    height: 1.55,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
    ];
  }
}

