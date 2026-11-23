import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/screens/quran_hub_screen.dart';
import 'package:chiraag_e_azaa/screens/quran_reader_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';
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
    await QuranService.instance.ensureLoaded();
  });

  test('Offline Quran bundle contains all 114 Surahs, 6236 Ayahs, and 30 Juz', () {
    final q = QuranService.instance;
    expect(q.surahs.length, equals(114));
    final totalAyahs = q.surahs.fold<int>(0, (sum, s) => sum + s.ayahCount);
    expect(totalAyahs, equals(6236));
    expect(q.juzList.length, equals(30));

    final fatiha = q.getSurah(1)!;
    expect(fatiha.englishName, equals('Al-Faatiha'));
    expect(fatiha.ayahCount, equals(7));
    expect(fatiha.ayahs.first.arabic, isNotEmpty);
    expect(fatiha.ayahs.first.roman, isNotEmpty);
    expect(fatiha.ayahs.first.english, isNotEmpty);
  });

  testWidgets('QuranHubScreen renders Surah Wise, Para Wise, and Search', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const QuranHubScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('Surah Wise'), findsOneWidget);
    expect(find.text('Para Wise'), findsOneWidget);
    expect(find.text('Al-Faatiha'), findsOneWidget);

    await tester.tap(find.text('Para Wise'));
    await tester.pumpAndSettle();
    expect(find.text('Para 1 (Juz 1)'), findsOneWidget);
  });

  testWidgets('QuranReaderScreen defaults to Mushaf page and toggles to Roman/English view', (tester) async {
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

    expect(find.text('Al-Faatiha'), findsOneWidget);
    expect(find.byKey(const Key('quran_record_button')), findsOneWidget);
    // Default Mushaf page mode shows continuous flowing ayahs + tap hint
    expect(find.text('Tap any Ayah for Roman, English & Audio'), findsOneWidget);

    // Switch to Translation (Roman & English) view
    await tester.tap(find.byKey(const Key('quran_view_mode_toggle')));
    await tester.pumpAndSettle();

    final fatihaFirst = QuranService.instance.getSurah(1)!.ayahs.first;
    expect(find.text(fatihaFirst.roman), findsOneWidget);
    expect(find.text(fatihaFirst.english), findsOneWidget);
  });
}
