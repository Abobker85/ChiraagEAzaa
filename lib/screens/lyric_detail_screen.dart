import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/content_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../widgets/audio_player_widget.dart';

class LyricDetailScreen extends StatefulWidget {
  final LyricItem item;
  const LyricDetailScreen({super.key, required this.item});

  @override
  State<LyricDetailScreen> createState() => _LyricDetailScreenState();
}

class _LyricDetailScreenState extends State<LyricDetailScreen> {
  String? _html;
  bool _loading = true;
  bool _saved = false;
  bool _isRtl = false;

  @override
  void initState() {
    super.initState();
    _saved = SavedManager.instance.isSaved(widget.item.id);
    // Force RTL for Arabic categories (duas, ziyaraat) even if is_rtl=0 in DB
    final catKey = widget.item.categoryKey.split('/').first;
    _isRtl = widget.item.isRtl || catKey == 'duas' || catKey == 'ziyaraat';
    _load();
  }

  Future<void> _load() async {
    final detail = await DatabaseService.instance.getLyricDetail(widget.item.id);
    if (!mounted) return;
    final html = detail != null ? _processHtml(detail.contentHtml, _isRtl) : null;
    setState(() { _html = html; _loading = false; });
  }

  String _processHtml(String raw, bool rtl) {
    var h = raw
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<div[^>]*id="urduTextPath"[^>]*>[\s\S]*?<\/div>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<\/div>', caseSensitive: false), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    // Strip any inline style attributes so settings font sizes are not overridden
    h = h.replaceAll(RegExp(r'\s*style="[^"]*"', caseSensitive: false), '');
    // Strip <span> wrappers but keep their content
    h = h.replaceAll(RegExp(r'<\/?span[^>]*>', caseSensitive: false), '');

    if (rtl) {
      // Strip existing <p> tags so we can re-wrap properly
      h = h.replaceAll(RegExp(r'<\/?p[^>]*>', caseSensitive: false), '');
      h = h.replaceAll(RegExp(r'(<br\s*\/?>\s*){2,}', caseSensitive: false), '\n\n');
      h = h.replaceAll(RegExp(r'<br\s*\/?>',           caseSensitive: false), '\n');
      final lines = h.split(RegExp(r'\n+')).map((l) => l.trim()).where((l) => l.isNotEmpty);
      // Use category to determine if content is Arabic (duas, ziyaraat) vs Urdu
      final isArabicCategory = _isArabicCategory(widget.item.categoryKey);
      h = lines.map((l) {
        if (isArabicCategory) {
          return '<blockquote dir="rtl">$l</blockquote>';
        } else {
          return '<p dir="rtl">$l</p>';
        }
      }).join('');
    } else {
      final blocks = h.replaceAll(RegExp(r'<br\s*\/?>\s*\n?', caseSensitive: false), '\n')
          .split(RegExp(r'\n{2,}'));
      h = blocks.map((b) {
        final t = b.trim();
        return t.isEmpty ? '' : '<p>${t.replaceAll('\n', '<br>')}</p>';
      }).where((b) => b.isNotEmpty).join('');
    }
    return h;
  }

  /// Categories that contain Arabic content (Quran, Duas, Ziyaraat).
  static bool _isArabicCategory(String categoryKey) {
    final key = categoryKey.split('/').first;
    return key == 'duas' || key == 'ziyaraat';
  }

  Future<void> _toggleSave() async {
    if (_saved) {
      await DatabaseService.instance.removeBookmark(widget.item.id);
    } else {
      await DatabaseService.instance.addBookmark(widget.item.id);
    }
    setState(() => _saved = !_saved);
    _toast(_saved ? 'Saved! 🔖' : 'Removed');
  }

  void _copy() {
    if (_html == null) return;
    final plain = _html!.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&amp;', '&');
    Clipboard.setData(ClipboardData(text: plain));
    _toast('Copied! 📋');
  }

  OverlayEntry? _toastEntry;
  void _toast(String msg) {
    _toastEntry?.remove();
    final overlay = Overlay.of(context);
    _toastEntry = OverlayEntry(builder: (_) => Positioned(
      bottom: 80, left: 0, right: 0,
      child: Center(child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
          child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      )),
    ));
    overlay.insert(_toastEntry!);
    Future.delayed(const Duration(milliseconds: 2500), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    final fontSize = _isRtl ? s.rtlFontSize : s.ltrFontSize;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border,
                color: _saved ? AppTheme.green : null),
            onPressed: _toggleSave,
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: _html != null ? _copy : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : _html == null
              ? const Center(child: Text('Content not available'))
              : AnimatedBuilder(
                  animation: AppSettings.instance,
                  builder: (context, _) => SingleChildScrollView(
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
                                'body': Style(padding: HtmlPaddings.zero, margin: Margins.zero),
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build RTL paragraphs directly as Flutter widgets for reliable font control.
  List<Widget> _buildRtlParagraphs(AppSettings s) {
    if (_html == null) return [];
    // Extract text from each paragraph tag (blockquote = Arabic, p = Urdu)
    final blockquoteRegex = RegExp(r'<blockquote[^>]*>(.*?)</blockquote>', dotAll: true);
    final pRegex = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true);
    // Find all tags in order
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
            16, widgets.isEmpty ? 8 : 0, 16,
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
      // Fallback: show raw text
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
