import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/main.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/models/lyric_item.dart';
import 'package:chiraag_e_azaa/screens/lyric_detail_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final loader = FontLoader('NotoSansArabic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf'));
    await loader.load();
    await DatabaseService.instance.db;
    await DatabaseService.instance.loadBookmarkIds();
  });

  test('AppTheme.containsArabic detects Arabic/Urdu script accurately', () {
    expect(AppTheme.containsArabic('السلام عليك'), isTrue);
    expect(AppTheme.containsArabic('نوحہ خوانی'), isTrue);
    expect(AppTheme.containsArabic('eid aayi hai rajab'), isFalse);
  });

  testWidgets('Global ParentsDuaBubble appears on every screen and opens Parents Dua dialog', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    const sampleItem = LyricItem(
      id: 18,
      categoryKey: 'manqabat',
      title: 'eid aayi hai rajab shaban ki',
      isRtl: false,
    );

    await tester.pumpWidget(
      const ChiraagApp(
        home: LyricDetailScreen(
          item: sampleItem,
          playlist: [sampleItem],
          initialIndex: 0,
        ),
      ),
    );
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    // Floating bubble is present even inside the LyricDetailScreen
    final bubble = find.byKey(const Key('parents_dua_bubble'));
    expect(bubble, findsOneWidget);

    // Tap bubble once to open Parents Dua dialog
    await tester.tap(bubble);
    await tester.pumpAndSettle();

    expect(find.text('Parents Dua'), findsOneWidget);
    expect(find.text('بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ'), findsOneWidget);
    expect(find.text('Al-Haj O Zawar Janab Mir Hussain Ali'), findsOneWidget);
    expect(find.text('Ex-Secretary, Anjuman-e-Parwanah Jaffariyah'), findsOneWidget);
    expect(find.text('Al-Haj O Zawaraa Syeda Zainab Fatima'), findsOneWidget);

    // Tap bubble a second time to hide/close the dialog
    await tester.tap(bubble);
    await tester.pumpAndSettle();
    expect(find.text('Parents Dua'), findsNothing);

    // Open again and close via the top-right Close button
    await tester.tap(bubble);
    await tester.pumpAndSettle();
    expect(find.text('Parents Dua'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Parents Dua'), findsNothing);
  });
}
