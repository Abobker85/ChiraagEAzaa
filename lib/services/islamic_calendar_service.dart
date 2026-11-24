class HijriDate {
  final int day;
  final int month; // 1..12
  final int year;

  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
  });

  static const List<String> monthNamesEn = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Thani',
    'Rajab',
    'Shaban',
    'Ramadan',
    'Shawwal',
    'Dhul Qadah',
    'Dhul Hijjah',
  ];

  static const List<String> monthNamesAr = [
    'محرم',
    'صفر',
    'ربیع الاول',
    'ربیع الثانی',
    'جمادی الاولیٰ',
    'جمادی الثانیہ',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذی القعدہ',
    'ذی الحجہ',
  ];

  String get monthNameEn => monthNamesEn[(month - 1).clamp(0, 11)];
  String get monthNameAr => monthNamesAr[(month - 1).clamp(0, 11)];

  String get formattedEn => '$day $monthNameEn $year AH';
  String get formattedAr => '$day $monthNameAr $year هـ';
}

class ShiaOccasion {
  final int month;
  final int day;
  final String title;
  final String arabicTitle;
  final bool isMourning;
  final String? recommendedCategoryKey;
  final String? recommendedDuaTitle;

  const ShiaOccasion({
    required this.month,
    required this.day,
    required this.title,
    required this.arabicTitle,
    this.isMourning = false,
    this.recommendedCategoryKey,
    this.recommendedDuaTitle,
  });
}

class UpcomingOccasion {
  final ShiaOccasion occasion;
  final int daysUntil;

  const UpcomingOccasion({
    required this.occasion,
    required this.daysUntil,
  });

  bool get isToday => daysUntil == 0;
}

class DailyDuaRecommendation {
  final String dayLabel;
  final String duaTitle;
  final String subtitle;

  const DailyDuaRecommendation({
    required this.dayLabel,
    required this.duaTitle,
    required this.subtitle,
  });
}

/// Offline Hijri calendar, Shia Wiladat/Shahadat occasions, and daily Dua guide.
class IslamicCalendarService {
  IslamicCalendarService._();

  static const List<ShiaOccasion> occasions = [
    ShiaOccasion(
      month: 1,
      day: 1,
      title: 'Islamic New Year · Muharram Begins',
      arabicTitle: 'آغازِ محرم الحرام',
      isMourning: true,
      recommendedCategoryKey: 'nouhay',
    ),
    ShiaOccasion(
      month: 1,
      day: 10,
      title: 'Day of Ashura — Shahadat Imam Hussain (a.s.)',
      arabicTitle: 'یومِ عاشورہ',
      isMourning: true,
      recommendedCategoryKey: 'ziyaraat',
    ),
    ShiaOccasion(
      month: 2,
      day: 20,
      title: 'Arbaeen of Imam Hussain (a.s.)',
      arabicTitle: 'اربعینِ حسینیؑ',
      isMourning: true,
      recommendedCategoryKey: 'ziyaraat',
    ),
    ShiaOccasion(
      month: 2,
      day: 28,
      title: 'Shahadat Holy Prophet (s.a.w.w.) & Imam Hasan (a.s.)',
      arabicTitle: 'شہادت رسولِ خداؐ و امام حسنؑ',
      isMourning: true,
      recommendedCategoryKey: 'marsias',
    ),
    ShiaOccasion(
      month: 3,
      day: 9,
      title: 'Eid-e-Zahra (s.a.)',
      arabicTitle: 'عیدِ زہراؑ',
      recommendedCategoryKey: 'manqabat',
    ),
    ShiaOccasion(
      month: 3,
      day: 17,
      title: 'Wiladat Holy Prophet (s.a.w.w.) & Imam Sadiq (a.s.)',
      arabicTitle: 'ولادتِ رسولِ اکرمؐ و امام صادقؑ',
      recommendedCategoryKey: 'qasiday',
    ),
    ShiaOccasion(
      month: 6,
      day: 3,
      title: 'Shahadat Bibi Fatima Zahra (s.a.)',
      arabicTitle: 'شہادتِ بی بی فاطمہ زہراؑ',
      isMourning: true,
      recommendedCategoryKey: 'nouhay',
    ),
    ShiaOccasion(
      month: 6,
      day: 20,
      title: 'Wiladat Bibi Fatima Zahra (s.a.)',
      arabicTitle: 'ولادتِ بی بی فاطمہ زہراؑ',
      recommendedCategoryKey: 'manqabat',
    ),
    ShiaOccasion(
      month: 7,
      day: 13,
      title: 'Wiladat Imam Ali (a.s.)',
      arabicTitle: 'ولادتِ امیرالمومنین امام علیؑ',
      recommendedCategoryKey: 'manqabat',
    ),
    ShiaOccasion(
      month: 8,
      day: 3,
      title: 'Wiladat Imam Hussain (a.s.)',
      arabicTitle: 'ولادتِ امام حسینؑ',
      recommendedCategoryKey: 'qasiday',
    ),
    ShiaOccasion(
      month: 8,
      day: 4,
      title: 'Wiladat Hazrat Abbas Alamdar (a.s.)',
      arabicTitle: 'ولادتِ حضرت عباس علمدارؑ',
      recommendedCategoryKey: 'manqabat',
    ),
    ShiaOccasion(
      month: 8,
      day: 15,
      title: 'Wiladat Imam Al-Mahdi (a.t.f.s.)',
      arabicTitle: 'ولادتِ امامِ زمانہ عج',
      recommendedDuaTitle: 'Dua e Faraj',
    ),
    ShiaOccasion(
      month: 9,
      day: 19,
      title: 'Shab-e-Qadr & Zarbat Imam Ali (a.s.)',
      arabicTitle: 'شبِ قدر و ضربتِ امام علیؑ',
      isMourning: true,
      recommendedDuaTitle: 'Dua e Kumail',
    ),
    ShiaOccasion(
      month: 9,
      day: 21,
      title: 'Shahadat Imam Ali (a.s.) & Shab-e-Qadr',
      arabicTitle: 'شہادتِ امام علیؑ',
      isMourning: true,
      recommendedCategoryKey: 'nouhay',
    ),
    ShiaOccasion(
      month: 9,
      day: 23,
      title: '23rd Ramadan — Grand Night of Qadr',
      arabicTitle: 'شبِ قدر (۲۳ رمضان)',
      recommendedDuaTitle: 'Dua e Tawassul',
    ),
    ShiaOccasion(
      month: 10,
      day: 1,
      title: 'Eid al-Fitr',
      arabicTitle: 'عید الفطر',
      recommendedCategoryKey: 'qasiday',
    ),
    ShiaOccasion(
      month: 12,
      day: 9,
      title: 'Day of Arafah',
      arabicTitle: 'یومِ عرفہ',
      recommendedDuaTitle: 'Dua e Kumail',
    ),
    ShiaOccasion(
      month: 12,
      day: 10,
      title: 'Eid al-Adha',
      arabicTitle: 'عید الاضحیٰ',
      recommendedCategoryKey: 'qasiday',
    ),
    ShiaOccasion(
      month: 12,
      day: 18,
      title: 'Eid-e-Ghadeer',
      arabicTitle: 'عیدِ غدیرِ خم',
      recommendedCategoryKey: 'manqabat',
    ),
  ];

  /// Standard Kuwaiti/Tabular Islamic calendar conversion from Gregorian [date].
  static HijriDate toHijri(DateTime date) {
    final d = date.day;
    final m = date.month;
    final y = date.year;

    final a = (14 - m) ~/ 12;
    final yAdj = y + 4800 - a;
    final mAdj = m + 12 * a - 3;
    final jdn = d +
        (153 * mAdj + 2) ~/ 5 +
        365 * yAdj +
        yAdj ~/ 4 -
        yAdj ~/ 100 +
        yAdj ~/ 400 -
        32045;

    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final hMonth = (24 * l) ~/ 709;
    final hDay = l - (709 * hMonth) ~/ 24;
    final hYear = 30 * n + j - 30;

    return HijriDate(
      day: hDay.clamp(1, 30),
      month: hMonth.clamp(1, 12),
      year: hYear,
    );
  }

  /// Finds today's Shia occasion, or the nearest upcoming occasion within 355 days.
  static UpcomingOccasion nextOccasion([DateTime? now]) {
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    for (int offset = 0; offset <= 355; offset++) {
      final h = toHijri(today.add(Duration(days: offset)));
      for (final occ in occasions) {
        if (occ.month == h.month && occ.day == h.day) {
          return UpcomingOccasion(occasion: occ, daysUntil: offset);
        }
      }
    }
    return UpcomingOccasion(occasion: occasions.first, daysUntil: 1);
  }

  /// Day-of-week recommended Dua mapped to titles in the local `duas` table.
  static DailyDuaRecommendation dailyDua([DateTime? now]) {
    final weekday = (now ?? DateTime.now()).weekday;
    switch (weekday) {
      case DateTime.thursday:
        return const DailyDuaRecommendation(
          dayLabel: 'Thursday Night Recommended',
          duaTitle: 'Dua e Kumail',
          subtitle: 'Taught by Imam Ali (a.s.) for Thursday evenings',
        );
      case DateTime.friday:
        return const DailyDuaRecommendation(
          dayLabel: 'Friday Recommended',
          duaTitle: 'Dua e Nudba',
          subtitle: 'Friday morning supplication for Imam Al-Mahdi (a.t.f.s.)',
        );
      case DateTime.tuesday:
        return const DailyDuaRecommendation(
          dayLabel: 'Tuesday Night Recommended',
          duaTitle: 'Dua e Tawassul',
          subtitle: 'Seeking intercession through the 14 Masumeen (a.s.)',
        );
      case DateTime.sunday:
        return const DailyDuaRecommendation(
          dayLabel: 'Daily Recommended',
          duaTitle: 'Dua e Faraj',
          subtitle: 'Supplication for Relief & Reappearance',
        );
      default:
        return const DailyDuaRecommendation(
          dayLabel: 'Daily Morning Recommended',
          duaTitle: 'Dua e Ahad',
          subtitle: 'Covenant with Imam Al-Mahdi (a.t.f.s.) after Fajr',
        );
    }
  }
}
