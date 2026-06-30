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
    _isRtl = widget.item.isRtl;
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

    if (rtl) {
      h = h.replaceAll(RegExp(r'(<br\s*\/?>\s*){2,}', caseSensitive: false), '\n\n');
      h = h.replaceAll(RegExp(r'<br\s*\/?>',           caseSensitive: false), '\n');
      final lines = h.split(RegExp(r'\n+')).map((l) => l.trim()).where((l) => l.isNotEmpty);
      h = lines.map((l) => '<p dir="rtl">$l</p>').join('');
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
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + s.paraSpacing),
                          child: Directionality(
                            textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
                            child: Html(
                              data: _html!,
                              style: {
                                'p': Style(
                                  fontSize: FontSize(fontSize),
                                  lineHeight: LineHeight(s.lineHeight),
                                  margin: Margins.only(bottom: s.paraSpacing),
                                  fontFamily: _isRtl ? 'NotoNaskhArabic' : null,
                                  textAlign: _isRtl ? TextAlign.right : TextAlign.left,
                                ),
                                'body': Style(padding: HtmlPaddings.zero, margin: Margins.zero),
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
