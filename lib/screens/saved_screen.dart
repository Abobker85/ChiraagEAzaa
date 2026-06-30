import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../widgets/lyric_row.dart';
import 'lyric_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<LyricItem>? _items;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await DatabaseService.instance.getBookmarks();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _remove(LyricItem item) async {
    await DatabaseService.instance.removeBookmark(item.id);
    setState(() => _items!.removeWhere((x) => x.id == item.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: _items == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : _items!.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🔖', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No bookmarks yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Tap the bookmark icon on any lyric to save it',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center),
                ]))
              : ListView.separated(
                  itemCount: _items!.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, thickness: 0.5, indent: 16, color: AppTheme.separator),
                  itemBuilder: (ctx, i) {
                    final item = _items![i];
                    return LyricRow(
                      title: item.title,
                      subtitle: item.subtitle.isNotEmpty ? item.subtitle : null,
                      isRtl: item.isRtl,
                      onTap: () async {
                        await Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => LyricDetailScreen(item: item),
                        ));
                        _load(); // refresh if user removed bookmark inside
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark, color: AppTheme.green, size: 20),
                        onPressed: () => _remove(item),
                      ),
                    );
                  },
                ),
    );
  }
}
