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
    }

    _pageController = PageController(initialPage: _currentIndex);
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

    return Container(
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
    );
  }
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
    final html = detail != null ? _processHtml(detail.contentHtml, _isRtl) : null;
    setState(() {
      _html = html;
      _loading = false;
    });
    widget.onContentLoaded(html);
  }

  String _processHtml(String raw, bool rtl) {
    var h = raw
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<div[^>]*id="urduTextPath"[^>]*>[\s\S]*?<\/div>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<\/div>', caseSensitive: false), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    h = h.replaceAll(RegExp(r'\s*style="[^"]*"', caseSensitive: false), '');
    h = h.replaceAll(RegExp(r'<\/?span[^>]*>', caseSensitive: false), '');

    if (rtl) {
      h = h.replaceAll(RegExp(r'<\/?p[^>]*>', caseSensitive: false), '');
      h = h.replaceAll(RegExp(r'(<br\s*\/?>\s*){2,}', caseSensitive: false), '\n\n');
      h = h.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n');
      final lines = h.split(RegExp(r'\n+')).map((l) => l.trim()).where((l) => l.isNotEmpty);
      final isArabicCategory = _isArabicCategory(widget.item.categoryKey);
      h = lines.map((l) {
        if (isArabicCategory) {
          return '<blockquote dir="rtl">$l</blockquote>';
        } else {
          return '<p dir="rtl">$l</p>';
        }
      }).join('');
    } else {
      final blocks = h
          .replaceAll(RegExp(r'<br\s*\/?>\s*\n?', caseSensitive: false), '\n')
          .split(RegExp(r'\n{2,}'));
      h = blocks
          .map((b) {
            final t = b.trim();
            return t.isEmpty ? '' : '<p>${t.replaceAll('\n', '<br>')}</p>';
          })
          .where((b) => b.isNotEmpty)
          .join('');
    }
    return h;
  }

  static bool _isArabicCategory(String categoryKey) {
    final key = categoryKey.split('/').first;
    return key == 'duas' || key == 'ziyaraat' || key == 'munaejaat';
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
                    ..._buildRtlParagraphs(s)
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

  List<Widget> _buildRtlParagraphs(AppSettings s) {
    if (_html == null) return [];
    final allTags = RegExp(r'<(blockquote|p)[^>]*>(.*?)</\1>', dotAll: true);
    final matches = allTags.allMatches(_html!);

    final widgets = <Widget>[];
    for (final m in matches) {
      final tag = m.group(1)!;
      final content = m.group(2)!;
      final plainText = content
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&#39;', "'")
          .replaceAll('&quot;', '"')
          .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) =>
              String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
          .replaceAllMapped(RegExp(r'&#(\d+);'), (m) =>
              String.fromCharCode(int.parse(m.group(1)!)))
          .trim();
      if (plainText.isEmpty) continue;

      final isArabic = tag == 'blockquote';
      final textStyle = TextStyle(
        fontSize: isArabic ? s.arabicFontSize : s.rtlFontSize,
        height: isArabic ? s.lineHeight + 0.3 : s.lineHeight,
        fontFamily: 'NotoNaskhArabic',
        color: AppTheme.textPrimary,
      );

      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            widgets.isEmpty ? 8 : 0,
            16,
            isArabic ? s.paraSpacing + 20 : s.paraSpacing + 14,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              plainText,
              textAlign: TextAlign.right,
              style: textStyle,
            ),
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      final plainText = _html!
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) =>
              String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
          .replaceAllMapped(RegExp(r'&#(\d+);'), (m) =>
              String.fromCharCode(int.parse(m.group(1)!)))
          .trim();
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              plainText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: s.arabicFontSize,
                height: s.lineHeight + 0.3,
                fontFamily: 'NotoNaskhArabic',
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}
