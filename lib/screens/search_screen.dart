import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../widgets/lyric_row.dart';
import 'lyric_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<LyricItem> _results = [];
  bool _searching = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _onChanged(String q) async {
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final results = await DatabaseService.instance.search(q);
    if (mounted && _ctrl.text == q) {
      setState(() { _results = results; _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              onChanged: _onChanged,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search Nouhay, Marsias, Duas…',
                hintStyle: TextStyle(color: colors.textTertiary),
                filled: true,
                fillColor: colors.inputFill,
                prefixIcon: Icon(Icons.search_rounded, color: colors.accent),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18, color: colors.textSecondary),
                        onPressed: () { _ctrl.clear(); setState(() => _results = []); })
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _ctrl.text.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Search across 5,130 items',
                  style: TextStyle(color: colors.textSecondary, fontSize: 15)),
            ]))
          : _searching
              ? Center(child: CircularProgressIndicator(color: colors.accent))
              : _results.isEmpty
                  ? Center(child: Text('No results for "${_ctrl.text}"',
                      style: TextStyle(color: colors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, thickness: 0.5, indent: 16, color: colors.separator),
                      itemBuilder: (ctx, i) {
                        final item = _results[i];
                        return LyricRow(
                          title: item.title,
                          subtitle: item.subtitle.isNotEmpty ? item.subtitle : null,
                          isRtl: item.isRtl,
                          onTap: () => Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => LyricDetailScreen(
                              item: item,
                              playlist: _results,
                              initialIndex: i,
                            ),
                          )),
                        );
                      },
                    ),
    );
  }
}
