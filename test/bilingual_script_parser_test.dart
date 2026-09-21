import 'package:flutter_test/flutter_test.dart';

class ContentBlock {
  final String text;
  final bool isArabic;
  final bool isInstruction;

  const ContentBlock({
    required this.text,
    required this.isArabic,
    this.isInstruction = false,
  });
}

List<ContentBlock> parseBlocks(String raw) {
  // 1. Decode HTML entities first
  var text = cleanHtmlEntities(raw)
      .replaceAll(RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<div[^>]*id="urduTextPath"[^>]*>[\s\S]*?<\/div>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<\/?(div|span)[^>]*>', caseSensitive: false), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s*style="[^"]*"', caseSensitive: false), '')
      .trim();

  // 2. Normalize paragraph and break boundaries
  text = text.replaceAll(RegExp(r'<\/?(p|blockquote)[^>]*>', caseSensitive: false), '\n\n');
  text = text.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n');

  // 3. Split transition from Latin punctuation (e.g. colon) directly into Arabic text
  text = text.replaceAllMapped(
    RegExp(r'([a-zA-Z0-9\.\,\:\;\)\"]+[\:\.\!])\s*([\u0600-\u06FF])'),
    (m) => '${m.group(1)}\n\n${m.group(2)}',
  );

  final rawChunks = text.split(RegExp(r'\n{2,}'));
  final blocks = <ContentBlock>[];

  for (final chunk in rawChunks) {
    final clean = chunk.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    if (clean.isEmpty) continue;

    final arabicCount = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]').allMatches(clean).length;
    final latinCount = RegExp(r'[a-zA-Z]').allMatches(clean).length;

    final isArabic = arabicCount > latinCount;
    final lower = clean.toLowerCase();
    final isInstruction = !isArabic && (
      clean.endsWith(':') ||
      lower.contains('supplication') ||
      lower.contains('reported from') ||
      lower.contains('peace be upon') ||
      lower.contains('beseech') ||
      lower.contains('merits') ||
      lower.contains('repeat') ||
      lower.contains('times') ||
      lower.contains('then say')
    );

    blocks.add(ContentBlock(
      text: clean,
      isArabic: isArabic,
      isInstruction: isInstruction,
    ));
  }

  return blocks;
}

String cleanHtmlEntities(String s) {
  return s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&rsquo;', "'")
      .replaceAll('&lsquo;', "'")
      .replaceAll('&rdquo;', '"')
      .replaceAll('&ldquo;', '"')
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) =>
          String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) =>
          String.fromCharCode(int.parse(m.group(1)!)));
}

void main() {
  group('Bilingual Script-Aware Recitation Parser', () {
    test('Correctly splits Dua e Mujeer English preface and Arabic prayer', () {
      const rawMujeer = '''
<p>The Supplication of the Lenient Supporter.</p>
<p>This magnificent supplication is reported from the Holy Prophet, peace be upon him and his Household. It was revealed to him while he was offering a prayer in Maqam Ibrahim: &#1576;&#1616;&#1587;&#1618;&#1605;&#1616; &#1575;&#1604;&#1604;&#1607;&#1616; &#1575;&#1604;&#1585;&#1617;&#1614;&#1581;&#1618;&#1605;&#1648;&#1606;&#1616; &#1575;&#1604;&#1585;&#1617;&#1614; &#1581;&#1616;&#1740;&#1618;&#1605;&#1616; &#1587;&#1615;&#1576;&#1618;&#1581;&#1614;&#1575;&#1606;&#1614;&#1603;&#1614; &#1610;&#1614;&#1575; &#1575;&#1614;&#1604;&#1604;&#1607;&#1615;</p>
''';

      final blocks = parseBlocks(rawMujeer);

      expect(blocks.length, 3);
      // Block 0: English title
      expect(blocks[0].isArabic, isFalse);
      expect(blocks[0].text, 'The Supplication of the Lenient Supporter.');

      // Block 1: English instruction/historical context card
      expect(blocks[1].isArabic, isFalse);
      expect(blocks[1].isInstruction, isTrue);
      expect(blocks[1].text, contains('peace be upon him'));

      // Block 2: Arabic supplication
      expect(blocks[2].isArabic, isTrue);
      expect(blocks[2].isInstruction, isFalse);
      expect(blocks[2].text, contains('سُبْحَانَكَ يَا اَللهُ'));
    });

    test('Leaves pure Arabic recitations intact as RTL', () {
      const pureArabic = '''
<p>&#1575;&#1614;&#1604;&#1604;&#1617;&#1648;&#1607;&#1615; &#1604;&#1614;&#1575;&#1647; &#1575;&#1616;&#1604;&#1648;&#1607;&#1614; &#1575;&#1616;&#1604;&#1617;&#1614;&#1575; &#1607;&#1615;&#1608;&#1614; &#1575;&#1604;&#1618;&#1581;&#1614;&#1609;&#1617;&#1615; &#1575;&#1604;&#1618;&#1602;&#1614;&#1610;&#1617;&#1615;&#1608;&#1618;&#1605;&#1615;</p>
''';
      final blocks = parseBlocks(pureArabic);
      expect(blocks.length, 1);
      expect(blocks[0].isArabic, isTrue);
      expect(blocks[0].isInstruction, isFalse);
    });

    test('Correctly identifies Roman Urdu poetry as Latin (LTR)', () {
      const romanUrdu = '''
<p>Aye Sakina suno toote dil ki fugaa<br>Ya Hydere Karrar madad karne ko aao</p>
''';
      final blocks = parseBlocks(romanUrdu);
      expect(blocks.length, 1);
      expect(blocks[0].isArabic, isFalse);
      expect(blocks[0].isInstruction, isFalse);
    });
  });
}
