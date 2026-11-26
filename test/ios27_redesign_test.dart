import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/main.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/screens/tasbih_screen.dart';
import 'package:chiraag_e_azaa/screens/settings_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';
import 'package:chiraag_e_azaa/services/settings_service.dart';

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
    await AppSettings.instance.load();
    AppSettings.instance.rtlFontSize = AppSettings.instance.rtlFontSize.clamp(28.0, 56.0);
    AppSettings.instance.arabicFontSize = AppSettings.instance.arabicFontSize.clamp(32.0, 72.0);
  });

  testWidgets('MainShell adapts between floating glass bar on iPhone and NavigationRail on iPad', (tester) async {
    // iPhone compact width
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const MainShell(),
      ),
    );
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Duas'), findsOneWidget);
    expect(find.text('Tasbih'), findsAtLeastNWidgets(1));

    // iPad wide width
    tester.view.physicalSize = const Size(1024 * 2, 1366 * 2);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const MainShell(key: ValueKey('ipad')),
      ),
    );
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(NavigationRail), findsOneWidget);
    // Drain sqflite_common's 10s lock-warning fake timer before test teardown
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('TasbihScreen shows Tasbih Bibi Fatima Zahra (S.A.) and counts taps', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const TasbihScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tasbih Bibi Fatima Zahra (S.A.)'), findsOneWidget);
    expect(find.text('اللَّهُ أَكْبَرُ'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Tap to recite'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('SettingsScreen Appearance switcher updates ThemeMode live', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APPEARANCE'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(AppSettings.instance.themeMode, equals(ThemeMode.dark));

    // Reset back to system inside runAsync so SQLite I/O completes cleanly
    await tester.runAsync(() async {
      AppSettings.instance.themeMode = ThemeMode.system;
      await AppSettings.instance.save();
    });
  });
}
