import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/screens/home_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final naskhLoader = FontLoader('ScheherazadeNew')
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/ScheherazadeNew-Bold.ttf'));
    await naskhLoader.load();
    final uiLoader = FontLoader('NotoSansArabic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf'));
    await uiLoader.load();
    await DatabaseService.instance.db;
  });

  test('AppTheme.arabicTextStyle uses bundled ScheherazadeNew with zero letterSpacing', () {
    final style = AppTheme.arabicTextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    expect(style.fontFamily, equals(AppTheme.arabicFontFamily));
    expect(style.fontFamily, equals('ScheherazadeNew'));
    expect(style.letterSpacing, equals(0));
    expect(style.fontSize, equals(24));
    expect(style.fontWeight, equals(FontWeight.bold));
  });

  testWidgets('Home header and Arabic/Urdu subtitles use bundled TTF font with letterSpacing 0', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pumpAndSettle();

    final headerFinder = find.text('السلام عليك يا أبا عبد الله');
    expect(headerFinder, findsOneWidget);
    final headerText = tester.widget<Text>(headerFinder);
    expect(headerText.textDirection, equals(TextDirection.rtl));
    expect(headerText.style?.fontFamily, equals('ScheherazadeNew'));
    expect(headerText.style?.letterSpacing, equals(0));

    for (final urduSubtitle in ['نوحہ خوانی', 'مرثیہ و سوز و سلام', 'زیارات مقدسہ', 'دعائیں و اعمال']) {
      final subFinder = find.text(urduSubtitle);
      expect(subFinder, findsOneWidget);
      final subText = tester.widget<Text>(subFinder);
      expect(subText.textDirection, equals(TextDirection.rtl));
      expect(subText.style?.fontFamily, equals('ScheherazadeNew'));
      expect(subText.style?.letterSpacing, equals(0));
    }
  });
}
