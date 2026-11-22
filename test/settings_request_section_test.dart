import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/screens/settings_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';
import 'package:chiraag_e_azaa/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final loader = FontLoader('NotoSansArabic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf'));
    await loader.load();
    await DatabaseService.instance.db;
    await AppSettings.instance.load();
    AppSettings.instance.rtlFontSize = AppSettings.instance.rtlFontSize.clamp(28.0, 56.0);
    AppSettings.instance.arabicFontSize = AppSettings.instance.arabicFontSize.clamp(32.0, 72.0);
  });

  for (final testCase in [
    (size: const Size(320, 568), theme: AppTheme.light, label: 'small-light'),
    (
      size: const Size(390, 844),
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: AppTheme.arabicFontFamily,
      ),
      label: 'phone-dark',
    ),
    (size: const Size(1024, 1366), theme: AppTheme.light, label: 'tablet-light'),
  ]) {
    testWidgets('REQUEST memorial section renders below CREDITS (${testCase.label})', (tester) async {
      tester.view.physicalSize = testCase.size * 2;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: testCase.theme,
          home: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('CREDITS'),
        100,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('CREDITS'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Designed & Developed by'),
        100,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Designed & Developed by'), findsOneWidget);
      expect(find.text('Mir Ali'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('gisdevpr31@gmail.com'),
        60,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('gisdevpr31@gmail.com'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('REQUEST'),
        60,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text('REQUEST'), findsOneWidget);

      // REQUEST header sits below Email row
      final emailFinder = find.text('gisdevpr31@gmail.com', skipOffstage: false);
      if (emailFinder.evaluate().isNotEmpty) {
        final emailBottom = tester.getBottomLeft(emailFinder).dy;
        final requestTop = tester.getTopLeft(find.text('REQUEST')).dy;
        expect(requestTop, greaterThan(emailBottom), reason: 'REQUEST must appear below Email row');
      }

      // Scroll to the very bottom of the memorial card
      await tester.scrollUntilVisible(
        find.text('May Allah (SWT) grant them the highest place in Jannatul Firdaus and fill their graves with light. Ameen.'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      // Exact memorial card content from Photo 4
      expect(find.text('بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ'), findsOneWidget);
      expect(
        find.text('We humbly request all readers to kindly recite Surah Al-Fatiha for the Isaal-e-Sawab of our beloved parents.'),
        findsOneWidget,
      );
      expect(find.text('Al-Haj O Zawar Janab Mir Hussain Ali'), findsOneWidget);
      expect(find.text('Ex-Secretary, Anjuman-e-Parwanah Jaffariyah'), findsOneWidget);
      expect(find.text('Son of Janab Mir Jamal Ali (Marhoom)'), findsOneWidget);
      expect(find.text('Al-Haj O Zawaraa Syeda Zainab Fatima'), findsOneWidget);
      expect(find.text('Daughter of Janab Mir Ahmed Ali (Marhoom)'), findsOneWidget);
      expect(
        find.text('May Allah (SWT) grant them the highest place in Jannatul Firdaus and fill their graves with light. Ameen.'),
        findsOneWidget,
      );

      // Bundled father's photo renders offline
      final memorialImgFinder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/memorial_parents.jpg',
      );
      expect(memorialImgFinder, findsOneWidget);
    });
  }
}
