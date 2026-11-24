import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/screens/lyric_detail_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';
import 'package:chiraag_e_azaa/services/dua_language_service.dart';

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
    await DuaLanguageService.instance.ensureLoaded();
  });

  test('Before & After Quran Duas and Urdu Noha exist in DB and 3-language asset', () async {
    final db = DatabaseService.instance;
    final duas = await db.getLyricsByCategory('duas');
    final titles = duas.map((d) => d.title).toList();
    expect(titles, contains('Dua Before Reciting Holy Quran'));
    expect(titles, contains('Dua After Reciting Holy Quran'));

    final before = DuaLanguageService.instance.getByTitle('Dua Before Reciting Holy Quran');
    final after = DuaLanguageService.instance.getByTitle('Dua After Reciting Holy Quran');
    expect(before, isNotNull);
    expect(after, isNotNull);
    expect(before!.verses.first.arabic, contains('اَللّٰهُمَّ اِنِّيْ اَشْهَدُ'));
    expect(before.verses.first.roman, isNotEmpty);
    expect(before.verses.first.english, isNotEmpty);
    expect(after!.verses.first.arabic, contains('اَللّٰهُمَّ اِنِّيْ قَدْ قَرَأْتُ'));
    expect(after.verses.first.roman, isNotEmpty);
    expect(after.verses.first.english, isNotEmpty);

    final qasimUrdu = await db.getLyricsByArtist('urduMarsiye', 'شہزادے قاسم (ع)');
    expect(
      qasimUrdu.any((it) => it.title.contains('لاشِ قاسم کی لا رہے ہیں')),
      isTrue,
    );
  });

  testWidgets('LyricDetailScreen renders 3-language Dua with Arabic, Roman, English toggles', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final duas = await tester.runAsync(
      () => DatabaseService.instance.getLyricsByCategory('duas'),
    );
    final beforeItem = duas!.firstWhere((d) => d.title == 'Dua Before Reciting Holy Quran');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LyricDetailScreen(
          item: beforeItem,
          playlist: [beforeItem],
          initialIndex: 0,
        ),
      ),
    );
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dua_lang_arabic')), findsOneWidget);
    expect(find.byKey(const Key('dua_lang_roman')), findsOneWidget);
    expect(find.byKey(const Key('dua_lang_english')), findsOneWidget);
    expect(find.text('Taught by Imam Sadiq (a.s.)'), findsOneWidget);

    // Toggle off English and verify
    await tester.tap(find.byKey(const Key('dua_lang_english')));
    await tester.pumpAndSettle();
    expect(DuaLanguageService.instance.showEnglish, isFalse);

    // Restore English for clean state
    await tester.tap(find.byKey(const Key('dua_lang_english')));
    await tester.pumpAndSettle();
    expect(DuaLanguageService.instance.showEnglish, isTrue);
  });
}
