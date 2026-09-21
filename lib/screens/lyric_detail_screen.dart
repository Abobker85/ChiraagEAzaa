import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../widgets/audio_player_widget.dart';

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

  @override
  State<LyricDetailScreen> createState() => _LyricDetailScreenState();
}

class _LyricDetailScreenState extends State<LyricDetailScreen> {
  late List<LyricItem> _playlist;
  late int _currentIndex;
  late PageController _pageController;

  // Cached content HTML per lyric ID to prevent re-fetching on swipes
  final Map<int, String?> _contentCache = {};

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
    _toast(isSaved ? 'Removed from saved' : 'Saved to bookmarks 🔖');
  }

  void _copy(String? html) {
    if (html == null) return;
    final plain = html.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&amp;', '&');
    Clipboard.setData(ClipboardData(text: plain));
    _toast('Copied to clipboard 📋');
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

  void _showFontSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: AppSettings.instance,
          builder: (context, _) {
            final s = AppSettings.instance;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Reading & Typography Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    // Arabic Font Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Arabic Calligraphy Size',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        Text(
                          '${s.arabicFontSize.toInt()} pt',
                          style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: s.arabicFontSize.clamp(28.0, 70.0),
                      min: 28,
                      max: 70,
                      divisions: 21,
                      activeColor: AppTheme.green,
                      onChanged: (v) {
                        s.arabicFontSize = v;
                        s.save();
                      },
                    ),
                    const SizedBox(height: 8),
                    // Line Spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Line Height (التباعد)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        Text(
                          s.lineHeight.toStringAsFixed(1),
                          style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: s.lineHeight.clamp(1.4, 2.8),
                      min: 1.4,
                      max: 2.8,
                      divisions: 14,
                      activeColor: AppTheme.green,
                      onChanged: (v) {
                        s.lineHeight = v;
                        s.save();
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenPale,
                        foregroundColor: AppTheme.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                                style: TextStyle(
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

    return Scaffold(
      backgroundColor: _isCurrentRtl ? const Color(0xFFFAF8F3) : AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              _currentItem.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (hasMultiple)
              Text(
                '${_currentIndex + 1} of ${_playlist.length}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size_rounded, size: 21),
            tooltip: 'Text Size',
            onPressed: _showFontSettingsSheet,
          ),
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSaved ? AppTheme.green : null,
              size: 22,
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: _playlist.length,
        onPageChanged: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        itemBuilder: (context, index) {
          final item = _playlist[index];
          return _LyricPageView(
            item: item,
            onContentLoaded: (html) {
              _contentCache[item.id] = html;
            },
          );
        },
      ),
      bottomNavigationBar: hasMultiple ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildBottomNavigationBar() {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex >= _playlist.length - 1;

    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border(
            top: BorderSide(
              color: Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isFirst
                  ? null
                  : () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: isFirst ? AppTheme.textTertiary : AppTheme.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Prev',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFirst ? AppTheme.textTertiary : AppTheme.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Center Index button (tappable to open table of recitations)
            Material(
              color: AppTheme.greenPale,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showPlaylistIndexSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 15,
                        color: AppTheme.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentIndex + 1} / ${_playlist.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 16,
                        color: AppTheme.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Next button
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isLast
                  ? null
                  : () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLast ? AppTheme.textTertiary : AppTheme.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isLast ? AppTheme.textTertiary : AppTheme.green,
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
  final ValueChanged<String?> onContentLoaded;

  const _LyricPageView({
    required this.item,
    required this.onContentLoaded,
  });

  @override
  State<_LyricPageView> createState() => _LyricPageViewState();
}

class _LyricPageViewState extends State<_LyricPageView> {
  String? _html;
  List<_ContentBlock> _blocks = [];
  bool _loading = true;
  late bool _isRtl;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

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

    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await DatabaseService.instance.getLyricDetail(widget.item.id);
    if (!mounted) return;
    final raw = detail?.contentHtml;
    final blocks = raw != null && _isRtl ? _parseBlocks(raw) : <_ContentBlock>[];
    setState(() {
      _html = raw;
      _blocks = blocks;
      _loading = false;
    });
    widget.onContentLoaded(raw);
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.green),
      );
    }
    if (_html == null) {
      return const Center(child: Text('Content not available'));
    }

    return Stack(
      children: [
        AnimatedBuilder(
          animation: AppSettings.instance,
          builder: (context, _) {
            final s = AppSettings.instance;
            final fontSize = _isRtl ? s.rtlFontSize : s.ltrFontSize;

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AudioPlayerWidget(lyricId: widget.item.id),
                  if (_isRtl)
                    ..._buildParsedBlocks(s)
                  else
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + s.paraSpacing),
                      child: Html(
                        data: _html!,
                        style: {
                          'p': Style(
                            fontSize: FontSize(fontSize),
                            lineHeight: LineHeight(s.lineHeight),
                            margin: Margins.only(bottom: s.paraSpacing),
                            textAlign: TextAlign.left,
                          ),
                          'body': Style(
                            padding: HtmlPaddings.zero,
                            margin: Margins.zero,
                          ),
                        },
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

  List<Widget> _buildParsedBlocks(AppSettings s) {
    if (_blocks.isEmpty) {
      if (_html == null) return [];
      final clean = _cleanHtmlEntities(_html!.replaceAll(RegExp(r'<[^>]+>'), '')).trim();
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(clean, style: TextStyle(fontSize: s.ltrFontSize)),
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
              color: AppTheme.greenPale.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.green,
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
                        color: AppTheme.textPrimary.withValues(alpha: 0.88),
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
                  color: isTitle ? AppTheme.green : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        );
      } else {
        // Arabic / Urdu script text
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
                style: TextStyle(
                  fontSize: s.arabicFontSize,
                  height: s.lineHeight + 0.3,
                  fontFamily: 'NotoSansArabic',
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

