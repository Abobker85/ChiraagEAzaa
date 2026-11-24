import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/screens/dua_hub_screen.dart';
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

  testWidgets('User can submit a custom Dua via AddCustomDuaScreen and see it saved in DuaHub index & FTS search', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const DuaHubScreen(initialCategoryKey: 'duas'),
      ),
    );
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    // Tap "+ Add Dua" in AppBar
    await tester.tap(find.byKey(const Key('dua_hub_add_custom_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Add Custom Dua'), findsOneWidget);

    const uniqueTitle = 'Custom Dua For Shifa Test';
    await tester.enterText(find.byKey(const Key('custom_dua_title_field')), uniqueTitle);
    await tester.enterText(find.byKey(const Key('custom_dua_subtitle_field')), 'Personal Supplication');
    await tester.enterText(
      find.byKey(const Key('custom_dua_arabic_field')),
      'اَللّٰهُمَّ اشْفِ كُلَّ مَرِيْضٍ',
    );
    await tester.enterText(
      find.byKey(const Key('custom_dua_roman_field')),
      'Allahummashfi kulla marid',
    );
    await tester.enterText(
      find.byKey(const Key('custom_dua_english_field')),
      'O Allah, heal every sick person.',
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('custom_dua_submit_btn')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('custom_dua_submit_btn')));
    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify it appears in the DuaHub index and in FTS search
    final searchResults = await tester.runAsync(
      () => DatabaseService.instance.search('Shifa'),
    );
    expect(searchResults!.any((r) => r.title == uniqueTitle), isTrue);

    // Verify 3-language registration
    final multi = DuaLanguageService.instance.getByTitle(uniqueTitle);
    expect(multi, isNotNull);
    expect(multi!.verses.first.arabic, contains('اشْفِ'));
    expect(multi.verses.first.roman, contains('Allahummashfi'));
    expect(multi.verses.first.english, contains('heal every sick'));

    // Clean up custom test entry
    final created = searchResults.firstWhere((r) => r.title == uniqueTitle);
    await tester.runAsync(() => DatabaseService.instance.deleteCustomDua(created.id));
    DuaLanguageService.instance.unregisterCustomDua(uniqueTitle);
  });
}
