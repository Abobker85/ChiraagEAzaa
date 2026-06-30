import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/lyric_item.dart';
import '../services/database_service.dart';
import '../widgets/lyric_row.dart';
import 'lyric_list_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Artist>? _artists;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.getArtists(widget.category.key).then((artists) {
      if (!mounted) return;
      if (artists.isEmpty) {
        // No artists — go directly to flat list
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => LyricListScreen(
            title: widget.category.label,
            categoryKey: widget.category.key,
          ),
        ));
        return;
      }
      setState(() { _artists = artists; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.icon} ${widget.category.label}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // "All" row
                SectionCard(children: [
                  LyricRow(
                    title: 'All ${widget.category.label}',
                    subtitle: '${widget.category.count} items',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LyricListScreen(
                        title: 'All ${widget.category.label}',
                        categoryKey: widget.category.key,
                      ),
                    )),
                  ),
                ]),
                const SizedBox(height: 8),
                SectionCard(
                  children: _artists!.map((a) => LyricRow(
                    title: a.name,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ArtistScreen(
                        category: widget.category,
                        artist: a,
                      ),
                    )),
                  )).toList(),
                ),
              ],
            ),
    );
  }
}

/// Shows years for an artist, or directly the lyrics if only one year.
class ArtistScreen extends StatefulWidget {
  final Category category;
  final Artist artist;
  const ArtistScreen({super.key, required this.category, required this.artist});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  List<String>? _years;

  @override
  void initState() {
    super.initState();
    DatabaseService.instance
        .getYearsForArtist(widget.category.key, widget.artist.name)
        .then((years) {
      if (!mounted) return;
      if (years.length <= 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => LyricListScreen(
            title: widget.artist.name,
            categoryKey: widget.category.key,
            artistName: widget.artist.name,
            year: years.isEmpty ? null : years.first,
          ),
        ));
        return;
      }
      setState(() => _years = years);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _years == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SectionCard(children: [
                  LyricRow(
                    title: 'All by ${widget.artist.name}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LyricListScreen(
                        title: widget.artist.name,
                        categoryKey: widget.category.key,
                        artistName: widget.artist.name,
                      ),
                    )),
                  ),
                ]),
                const SizedBox(height: 8),
                SectionCard(
                  children: _years!.map((y) => LyricRow(
                    title: y,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LyricListScreen(
                        title: '${widget.artist.name} · $y',
                        categoryKey: widget.category.key,
                        artistName: widget.artist.name,
                        year: y,
                      ),
                    )),
                  )).toList(),
                ),
              ],
            ),
    );
  }
}
