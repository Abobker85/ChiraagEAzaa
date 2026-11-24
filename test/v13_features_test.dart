import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/screens/home_screen.dart';
import 'package:chiraag_e_azaa/screens/quran_hub_screen.dart';
import 'package:chiraag_e_azaa/screens/quran_reader_screen.dart';
import 'package:chiraag_e_azaa/screens/saved_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';
import 'package:chiraag_e_azaa/services/islamic_calendar_service.dart';
import 'package:chiraag_e_azaa/services/majlis_playlist_service.dart';
import 'package:chiraag_e_azaa/services/quran_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final naskh = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Bold.ttf'));
    await naskh.load();
    final ui = FontLoader('NotoSansArabic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf'));
    await ui.load();
    await DatabaseService.instance.db;
    await DatabaseService.instance.ensureBookmarksTable();
    await QuranService.instance.ensureLoaded();
    await MajlisPlaylistService.instance.ensureLoaded();
  });

  test('IslamicCalendarService computes Hijri date, upcoming Shia occasion, and daily Dua', () {
    final h = IslamicCalendarService.toHijri(DateTime(2026, 7, 16));
    expect(h.year, greaterThanOrEqualTo(1447));
    expect(h.month, inInclusiveRange(1, 12));
    expect(h.day, inInclusiveRange(1, 30));

    final upcoming = IslamicCalendarService.nextOccasion(DateTime(2026, 7, 16));
    expect(upcoming.occasion.title, isNotEmpty);
    expect(upcoming.daysUntil, greaterThanOrEqualTo(0));

    final thu = IslamicCalendarService.dailyDua(DateTime(2026, 11, 26)); // Thursday
    expect(thu.duaTitle, equals('Dua e Kumail'));
    final fri = IslamicCalendarService.dailyDua(DateTime(2026, 11, 27)); // Friday
    expect(fri.duaTitle, equals('Dua e Nudba'));
  });

  testWidgets('HomeScreen displays Hijri date, Shia occasion & Daily Recommended Dua card', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const HomeScreen()));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_islamic_calendar_card')), findsOneWidget);
    expect(find.byKey(const Key('home_daily_dua_btn')), findsOneWidget);
  });

  testWidgets('QuranHubScreen shows Before/After Dua shortcuts and interactive Khatm tracker', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const QuranHubScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub_dua_before_quran')), findsOneWidget);
    expect(find.byKey(const Key('hub_dua_after_quran')), findsOneWidget);

    await tester.tap(find.text('Khatm'));
    await tester.pumpAndSettle();
    expect(find.text('Khatm-e-Quran Tracker'), findsOneWidget);

    await tester.runAsync(() => QuranService.instance.resetKhatm());
    await tester.pumpAndSettle();
    expect(find.text('0 of 30 Paras Completed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('khatm_para_1')));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('1 of 30 Paras Completed'), findsOneWidget);
  });

  testWidgets('QuranReaderScreen toggles Auto-Scroll Teleprompter bar', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const QuranReaderScreen(initialSurahNumber: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auto_scroll_bar')), findsNothing);
    await tester.tap(find.byKey(const Key('quran_auto_scroll_toggle')));
    await tester.pump();
    expect(find.byKey(const Key('auto_scroll_bar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('auto_scroll_close')));
    await tester.pump();
    expect(find.byKey(const Key('auto_scroll_bar')), findsNothing);
  });

  testWidgets('SavedScreen creates and displays Custom Majlis Playlists', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const SavedScreen()));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('Majlis Lists'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_majlis_playlist_btn')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('majlis_playlist_name_input')), 'Ashura Majlis');
    await tester.tap(find.byKey(const Key('majlis_playlist_create_confirm')));
    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    expect(find.text('Ashura Majlis'), findsWidgets);
  });
}
