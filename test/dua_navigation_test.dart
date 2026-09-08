import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chiraag_e_azaa/models/lyric_item.dart';
import 'package:chiraag_e_azaa/screens/lyric_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final data = await rootBundle.load('assets/chiraag_e_azaa.db');
    tempDir = await Directory.systemTemp.createTemp('chiraag_test_nav_');
    final dbFile = File('${tempDir.path}${Platform.pathSeparator}chiraag_e_azaa.db');
    await dbFile.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('LyricDetailScreen renders playlist and navigates between pages', (tester) async {
    const item1 = LyricItem(
      id: 1,
      categoryKey: 'duas',
      title: 'Ayat Al Kursi',
      isRtl: true,
    );
    const item2 = LyricItem(
      id: 2,
      categoryKey: 'duas',
      title: 'Dua e Ahad',
      isRtl: true,
    );
    const item3 = LyricItem(
      id: 3,
      categoryKey: 'duas',
      title: 'Dua e Kumail',
      isRtl: true,
    );

    final playlist = [item1, item2, item3];

    await tester.pumpWidget(
      MaterialApp(
        home: LyricDetailScreen(
          item: item1,
          playlist: playlist,
          initialIndex: 0,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify initial item
    expect(find.text('Ayat Al Kursi'), findsWidgets);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Prev'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Now index is 1 (item2: Dua e Ahad)
    expect(find.text('Dua e Ahad'), findsWidgets);
    expect(find.text('2 of 3'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    // Tap center index button to open Table of Recitations sheet
    await tester.tap(find.text('2 / 3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Table of Recitations (الفهرس)'), findsOneWidget);
    expect(find.text('Dua e Kumail'), findsWidgets);

    // Tap Dua e Kumail in the sheet to jump to page 2 (index 2)
    await tester.tap(find.text('Dua e Kumail').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Sheet closed and now showing Dua e Kumail
    expect(find.text('Dua e Kumail'), findsWidgets);
    expect(find.text('3 of 3'), findsOneWidget);
  });
}
