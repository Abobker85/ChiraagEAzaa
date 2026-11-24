import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/theme.dart';
import 'package:chiraag_e_azaa/models/lyric_item.dart';
import 'package:chiraag_e_azaa/screens/lyric_detail_screen.dart';
import 'package:chiraag_e_azaa/services/database_service.dart';
import 'package:chiraag_e_azaa/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.instance.db;
    await DatabaseService.instance.loadBookmarkIds();
  });

  group('LyricDetailScreen.sanitizeLtrHtml', () {
    test('strips unquoted, double-quoted, and single-quoted style/width/height attributes', () {
      const raw = '<div style=width:100%><h3><u>eid aayi hai</u></h3>'
          '<div style="width: 100%!important; height: 200px">'
          '<table width="600" style=\'width:100%\'><p>salle ala</p></table></div></div>';
      final cleaned = LyricDetailScreen.sanitizeLtrHtml(raw);
      expect(cleaned, isNot(contains('width:100%')));
      expect(cleaned, isNot(contains('height: 200px')));
      expect(cleaned, isNot(contains('width="600"')));
      expect(cleaned, contains('salle ala'));
      expect(cleaned, contains('<h3><u>eid aayi hai</u></h3>'));
    });

    test('strips script, style, and iframe tags while preserving lyric body', () {
      const raw = '<style>p{color:red}</style><script>alert(1)</script>'
          '<iframe src="x"></iframe><p>Ya Hussain</p>';
      final cleaned = LyricDetailScreen.sanitizeLtrHtml(raw);
      expect(cleaned, equals('<p>Ya Hussain</p>'));
    });
  });

  group('LyricDetailScreen full-width layout across categories and sizes', () {
    testWidgets('Manqabat ID 18 (eid aayi hai rajab shaban ki) wraps at full width on smallest device and min/max font sizes', (tester) async {
      // Smallest supported device: 320 x 568 (iPhone SE 1st gen)
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      const item = LyricItem(
        id: 18,
        categoryKey: 'manqabat',
        artistName: 'Farhan Ali',
        year: '2008',
        title: 'eid aayi hai rajab shaban ki',
        isRtl: false,
      );

      for (final fontSize in [14.0, 26.0]) {
        AppSettings.instance.ltrFontSize = fontSize;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const LyricDetailScreen(
              item: item,
              playlist: [item],
              initialIndex: 0,
            ),
          ),
        );
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
        await tester.pumpAndSettle();

        // Find the rendered RichText containing the lyric body
        final richTexts = tester.widgetList<RichText>(find.byType(RichText)).toList();
        final lyricRichText = find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('salle ala ka shor utha'),
        );
        expect(richTexts, isNotEmpty);
        expect(lyricRichText, findsOneWidget);

        final box = tester.getSize(lyricRichText);
        // Available width on 320px device minus 32px horizontal padding = 288px.
        // Previously collapsed to ~12px (one character per line).
        expect(box.width, greaterThan(220), reason: 'Lyric text must wrap at full width at ${fontSize}px');
      }
    });

    testWidgets('Arabic-script lyrics align RTL and Roman-script lyrics align LTR', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      // 1. Arabic/Urdu lyric (Ayat Al Kursi, duas)
      const duaItem = LyricItem(
        id: 1,
        categoryKey: 'duas',
        title: 'Ayat Al Kursi',
        isRtl: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const LyricDetailScreen(
            key: ValueKey(1),
            item: duaItem,
            playlist: [duaItem],
            initialIndex: 0,
          ),
        ),
      );
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();

      final arabicTextFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            ((w.data ?? '').contains('اللّٰهُ') || (w.data ?? '').contains('اللَّهُ')) &&
            w.textAlign == TextAlign.right,
      );
      expect(arabicTextFinder, findsWidgets);

      // 2. Urdu Marsiye (isRtl = true)
      const urduItem = LyricItem(
        id: 5005,
        categoryKey: 'urduMarsiye',
        title: 'أم البنين مادرِ عباس ذی وقار',
        isRtl: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const LyricDetailScreen(
            key: ValueKey(5005),
            item: urduItem,
            playlist: [urduItem],
            initialIndex: 0,
          ),
        ),
      );
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();

      final urduTextFinder = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').contains('عباس') && w.textAlign == TextAlign.right,
      );
      expect(urduTextFinder, findsWidgets);

      // 3. Roman-script Nouha with table/width (ID 3996)
      const nouhaItem = LyricItem(
        id: 3996,
        categoryKey: 'nouhay',
        title: 'Haan Tha Mera Baba',
        isRtl: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const LyricDetailScreen(
            key: ValueKey(3996),
            item: nouhaItem,
            playlist: [nouhaItem],
            initialIndex: 0,
          ),
        ),
      );
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 250)));
      await tester.pumpAndSettle();

      final ltrDirFinder = find.byWidgetPredicate(
        (w) => w is Directionality && w.textDirection == TextDirection.ltr,
      );
      expect(ltrDirFinder, findsWidgets);
    });
  });
}
