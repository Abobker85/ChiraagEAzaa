import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/islamic_calendar_service.dart';
import 'category_screen.dart';
import 'dua_hub_screen.dart';
import 'lyric_detail_screen.dart';

/// Full-year offline Shia Islamic Calendar (Wiladat & Shahadat occasions)
/// with 1-tap links to recommended Duas, Ziyaraat, Nouhay, and Manqabat.
class ShiaCalendarScreen extends StatelessWidget {
  const ShiaCalendarScreen({super.key});

  Future<void> _openOccasionLink(BuildContext context, ShiaOccasion occ) async {
    if (occ.recommendedDuaTitle != null) {
      final duas = await DatabaseService.instance.getLyricsByCategory('duas');
      if (!context.mounted) return;
      final idx = duas.indexWhere(
        (d) => d.title.toLowerCase() == occ.recommendedDuaTitle!.toLowerCase(),
      );
      if (idx >= 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LyricDetailScreen(
              item: duas[idx],
              playlist: duas,
              initialIndex: idx,
            ),
          ),
        );
        return;
      }
    }

    final catKey = occ.recommendedCategoryKey;
    if (catKey == null) return;
    if (catKey == 'duas' || catKey == 'ziyaraat' || catKey == 'munaejaat') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DuaHubScreen(initialCategoryKey: catKey),
        ),
      );
      return;
    }

    final cats = await DatabaseService.instance.getCategories();
    if (!context.mounted) return;
    final match = cats.where((c) => c.key == catKey);
    if (match.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryScreen(category: match.first)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final now = DateTime.now();
    final today = IslamicCalendarService.toHijri(now);
    final next = IslamicCalendarService.nextOccasion(now);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shia Islamic Calendar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF165225), Color(0xFF0D3316)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY\'S HIJRI DATE',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  today.formattedEn,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  today.formattedAr,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.arabicTextStyle(
                    fontSize: 19,
                    color: AppTheme.gold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    next.isToday
                        ? 'Today: ${next.occasion.title}'
                        : 'Next (${next.daysUntil}d): ${next.occasion.title}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wiladat & Shahadat Occasions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...IslamicCalendarService.occasions.map((occ) {
            final monthName = HijriDate.monthNamesEn[(occ.month - 1).clamp(0, 11)];
            final isNext = occ.month == next.occasion.month && occ.day == next.occasion.day;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: colors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isNext ? colors.gold : colors.separator,
                    width: isNext ? 1.3 : 0.8,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () => _openOccasionLink(context, occ),
                  leading: Container(
                    width: 48,
                    height: 44,
                    decoration: BoxDecoration(
                      color: occ.isMourning ? colors.inputFill : colors.goldSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${occ.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: occ.isMourning ? colors.textPrimary : colors.gold,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          monthName.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    occ.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    occ.arabicTitle,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.arabicTextStyle(
                      fontSize: 15,
                      color: occ.isMourning ? colors.textSecondary : colors.accent,
                      height: 1.4,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
