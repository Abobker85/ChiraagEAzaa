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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search Nouhay, Marsias, Duas…',
                hintStyle: const TextStyle(color: AppTheme.textTertiary),
                filled: true, fillColor: const Color(0xFFEFEFEF),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _ctrl.clear(); setState(() => _results = []); })
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _ctrl.text.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('🔍', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Search across 5,130 items',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
            ]))
          : _searching
              ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
              : _results.isEmpty
                  ? Center(child: Text('No results for "${_ctrl.text}"',
                      style: const TextStyle(color: AppTheme.textSecondary)))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, thickness: 0.5, indent: 16, color: AppTheme.separator),
                      itemBuilder: (ctx, i) {
                        final item = _results[i];
                        return LyricRow(
                          title: item.title,
                          subtitle: item.subtitle.isNotEmpty ? item.subtitle : null,
                          isRtl: item.isRtl,
                          onTap: () => Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => LyricDetailScreen(item: item),
                          )),
                        );
                      },
                    ),
    );
  }
}
