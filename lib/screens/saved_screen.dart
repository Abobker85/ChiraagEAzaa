import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../services/majlis_playlist_service.dart';
import '../widgets/lyric_row.dart';
import 'lyric_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});
  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LyricItem>? _items;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await MajlisPlaylistService.instance.ensureLoaded();
    final items = await DatabaseService.instance.getBookmarks();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _remove(LyricItem item) async {
    await DatabaseService.instance.removeBookmark(item.id);
    setState(() => _items!.removeWhere((x) => x.id == item.id));
  }

  Future<void> _showCreatePlaylistDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Majlis Playlist'),
        content: TextField(
          key: const Key('majlis_playlist_name_input'),
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Ashura Majlis, Thursday Night',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('majlis_playlist_create_confirm'),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await MajlisPlaylistService.instance.createPlaylist(name);
    }
  }

  Future<void> _openAddToPlaylistSheet(LyricItem item) async {
    await MajlisPlaylistService.instance.ensureLoaded();
    if (!mounted) return;
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: MajlisPlaylistService.instance,
          builder: (_, __) {
            final lists = MajlisPlaylistService.instance.playlists;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add to Majlis Playlist',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (lists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'No Majlis playlists yet. Create one below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                      )
                    else
                      ...lists.map((p) {
                        final selected = p.lyricIds.contains(item.id);
                        return CheckboxListTile(
                          value: selected,
                          activeColor: colors.accent,
                          title: Text(p.name),
                          subtitle: Text('${p.lyricIds.length} items'),
                          onChanged: (_) => MajlisPlaylistService.instance
                              .toggleItemInPlaylist(p.id, item.id),
                        );
                      }),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreatePlaylistDialog();
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create New Playlist'),
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

  Future<void> _openPlaylist(MajlisPlaylist playlist) async {
    if (playlist.lyricIds.isEmpty) return;
    final resolved = <LyricItem>[];
    for (final id in playlist.lyricIds) {
      final detail = await DatabaseService.instance.getLyricDetail(id);
      if (detail != null) resolved.add(detail.item);
    }
    if (!mounted || resolved.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LyricDetailScreen(
          item: resolved.first,
          playlist: resolved,
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        title: const Text('Saved'),
        actions: [
          IconButton(
            key: const Key('create_majlis_playlist_btn'),
            tooltip: 'New Majlis Playlist',
            icon: const Icon(Icons.playlist_add_rounded, size: 22),
            onPressed: _showCreatePlaylistDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            height: 40,
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.separator),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: colors.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Bookmarks'),
                Tab(text: 'Majlis Lists'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookmarksTab(colors),
          _buildPlaylistsTab(colors),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(AppColors colors) {
    if (_items == null) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }
    if (_items!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No bookmarks yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the bookmark icon on any lyric to save it',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: _items!.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 16,
        color: colors.separator,
      ),
      itemBuilder: (ctx, i) {
        final item = _items![i];
        return LyricRow(
          title: item.title,
          subtitle: item.subtitle.isNotEmpty ? item.subtitle : null,
          isRtl: item.isRtl,
          onTap: () async {
            await Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LyricDetailScreen(
                  item: item,
                  playlist: _items,
                  initialIndex: i,
                ),
              ),
            );
            _load();
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Add to Majlis Playlist',
                icon: Icon(Icons.playlist_add_rounded, color: colors.textSecondary, size: 20),
                onPressed: () => _openAddToPlaylistSheet(item),
              ),
              IconButton(
                icon: Icon(Icons.bookmark_rounded, color: colors.accent, size: 20),
                onPressed: () => _remove(item),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(AppColors colors) {
    return AnimatedBuilder(
      animation: MajlisPlaylistService.instance,
      builder: (context, _) {
        final playlists = MajlisPlaylistService.instance.playlists;
        if (playlists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music_rounded, size: 48, color: colors.gold),
                  const SizedBox(height: 12),
                  Text(
                    'No Majlis Playlists Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Group Marsias, Nouhay, Salaam, and Duas into custom folders for sequential recitation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _showCreatePlaylistDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create Majlis Playlist'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          itemCount: playlists.length,
          itemBuilder: (context, idx) {
            final p = playlists[idx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: colors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.separator),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.folder_special_rounded, color: colors.accent, size: 20),
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${p.lyricIds.length} recitations',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete Playlist',
                    icon: Icon(Icons.delete_outline_rounded, color: colors.textSecondary, size: 20),
                    onPressed: () => MajlisPlaylistService.instance.deletePlaylist(p.id),
                  ),
                  onTap: () => _openPlaylist(p),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
