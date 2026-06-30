import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category>? _cats;

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.getCategories().then((cats) {
      if (mounted) setState(() => _cats = cats);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chiraag e Azaa'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      body: _cats == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : ListView.builder(
              itemCount: _cats!.length,
              itemBuilder: (ctx, i) {
                final cat = _cats![i];
                return _CategoryTile(
                  cat: cat,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => CategoryScreen(category: cat),
                  )),
                );
              },
            ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category cat;
  final VoidCallback onTap;
  const _CategoryTile({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.greenPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  if (cat.count > 0)
                    Text('${cat.count} items',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
