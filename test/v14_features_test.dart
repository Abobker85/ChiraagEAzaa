import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/main.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/models/lyric_item.dart';
import 'package:chiraag_e_azaa/screens/add_custom_dua_screen.dart';
import 'package:chiraag_e_azaa/screens/home_screen.dart';
import 'package:chiraag_e_azaa/screens/shia_calendar_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';
import 'package:chiraag_e_azaa/services/quran_service.dart';
import 'package:chiraag_e_azaa/services/user_data_service.dart';

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
    await UserDataService.instance.ensureLoaded();
  });

  test('UserDataService records recent history, saves/clears notes, and exports/imports backup JSON', () async {
    const sample = LyricItem(
      id: 1,
      categoryKey: 'duas',
      title: 'Ayat Al Kursi',
      isRtl: true,
    );
    await UserDataService.instance.recordRecent(sample);
    expect(UserDataService.instance.recent.any((r) => r.id == 1), isTrue);

    await UserDataService.instance.saveNote(1, 'Recite slowly after Fajr');
    expect(UserDataService.instance.hasNote(1), isTrue);
    expect(UserDataService.instance.getNote(1), equals('Recite slowly after Fajr'));

    final exported = await UserDataService.instance.exportBackupJson();
    final parsed = jsonDecode(exported) as Map<String, dynamic>;
    expect(parsed['app'], equals('ChiraagEAzaa'));
    expect((parsed['notes'] as Map)['1'], equals('Recite slowly after Fajr'));

    // Clear and restore via JSON import
    await UserDataService.instance.saveNote(1, '');
    expect(UserDataService.instance.hasNote(1), isFalse);

    final summary = await UserDataService.instance.importBackupJson(exported);
    expect(summary, contains('Restored'));
    expect(UserDataService.instance.getNote(1), equals('Recite slowly after Fajr'));

    // Clean up test note
    await UserDataService.instance.saveNote(1, '');
  });

  testWidgets('HomeScreen Hijri card opens full-year ShiaCalendarScreen', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const HomeScreen()));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_open_calendar_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(ShiaCalendarScreen), findsOneWidget);
    expect(find.text('Shia Islamic Calendar'), findsOneWidget);
    expect(find.text('Wiladat & Shahadat Occasions'), findsOneWidget);
  });

  testWidgets('AddCustomDuaScreen supports Duas, Ziyaraat, Munajaat, Nouhay, Marsias & Urdu Poem', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const AddCustomDuaScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Duas'), findsOneWidget);
    expect(find.text('Nouhay'), findsOneWidget);
    expect(find.text('Marsias'), findsOneWidget);
    expect(find.text('Urdu Poem'), findsOneWidget);
  });

  testWidgets('Tapping Ziyaraat on Home inside MainShell switches directly to Ziyaraat (2nd) tab', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const MainShell()));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Drag Home ListView down so Ziyaraat card is well inside the visible viewport above the glass bar
    for (int i = 0; i < 4; i++) {
      final matches = find.text('Ziyaraat');
      if (matches.evaluate().isNotEmpty && tester.getCenter(matches.first).dy < 700) {
        break;
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('Ziyaraat').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final tabBar = tester.widget<TabBar>(find.byType(TabBar).first);
    expect(tabBar.controller!.index, equals(1));
    expect(find.text('زیارات مقدسہ'), findsOneWidget);
  });
}
