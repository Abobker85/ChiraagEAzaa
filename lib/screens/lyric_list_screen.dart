import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../widgets/lyric_row.dart';
import 'lyric_detail_screen.dart';

class LyricListScreen extends StatefulWidget {
  final String title;
  final String categoryKey;
  final String? artistName;
  final String? year;

  const LyricListScreen({
    super.key,
    required this.title,
    required this.categoryKey,
    this.artistName,
    this.year,
  });

  @override
  State<LyricListScreen> createState() => _LyricListScreenState();
}

class _LyricListScreenState extends State<LyricListScreen> {
  List<LyricItem>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final items = widget.artistName != null
        ? await db.getLyricsByArtist(
            widget.categoryKey, widget.artistName!, year: widget.year)
        : await db.getLyricsByCategory(widget.categoryKey);
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _items == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : _items!.isEmpty
              ? const Center(child: Text('No items found',
                  style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.separated(
                  itemCount: _items!.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 0.5, indent: 16,
                      color: AppTheme.separator),
                  itemBuilder: (context, i) {
                    final item = _items![i];
                    return LyricRow(
                      title: item.title,
                      subtitle: item.subtitle.isNotEmpty ? item.subtitle : null,
                      isRtl: item.isRtl,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => LyricDetailScreen(item: item),
                      )),
                    );
                  },
                ),
    );
  }
}
