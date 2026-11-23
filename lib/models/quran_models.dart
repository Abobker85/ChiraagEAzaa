class QuranAyah {
  final int surahNumber;
  final int numberInSurah;
  final int globalNumber;
  final int juz;
  final String arabic;
  final String roman;
  final String english;

  const QuranAyah({
    required this.surahNumber,
    required this.numberInSurah,
    required this.globalNumber,
    required this.juz,
    required this.arabic,
    required this.roman,
    required this.english,
  });

  factory QuranAyah.fromJson(int surahNumber, Map<String, dynamic> j) => QuranAyah(
        surahNumber: surahNumber,
        numberInSurah: j['n'] as int,
        globalNumber: j['g'] as int,
        juz: j['j'] as int,
        arabic: j['ar'] as String,
        roman: j['ro'] as String,
        english: j['en'] as String,
      );

  String get bookmarkKey => '$surahNumber:$numberInSurah';
}

class QuranSurah {
  final int number;
  final String arabicName;
  final String englishName;
  final String englishTranslation;
  final String revelationType;
  final List<QuranAyah> ayahs;

  const QuranSurah({
    required this.number,
    required this.arabicName,
    required this.englishName,
    required this.englishTranslation,
    required this.revelationType,
    required this.ayahs,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> j) {
    final num = j['n'] as int;
    final list = (j['ayahs'] as List<dynamic>)
        .map((e) => QuranAyah.fromJson(num, e as Map<String, dynamic>))
        .toList();
    return QuranSurah(
      number: num,
      arabicName: j['ar'] as String,
      englishName: j['en'] as String,
      englishTranslation: j['tr'] as String,
      revelationType: j['rev'] as String,
      ayahs: list,
    );
  }

  int get ayahCount => ayahs.length;
}

class QuranJuzEntry {
  final int juzNumber;
  final int startSurahNumber;
  final String startSurahEnglish;
  final String startSurahArabic;
  final int startAyahNumber;
  final String previewArabic;

  const QuranJuzEntry({
    required this.juzNumber,
    required this.startSurahNumber,
    required this.startSurahEnglish,
    required this.startSurahArabic,
    required this.startAyahNumber,
    required this.previewArabic,
  });
}

class QuranRecording {
  final String path;
  final int surahNumber;
  final DateTime createdAt;

  const QuranRecording({
    required this.path,
    required this.surahNumber,
    required this.createdAt,
  });
}

class QuranReciter {
  final String id;
  final String name;
  final String style;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.style,
  });

  String surahAudioUrl(int surahNumber) =>
      'https://cdn.islamic.network/quran/audio-surah/128/$id/$surahNumber.mp3';

  String ayahAudioUrl(int globalAyahNumber) =>
      'https://cdn.islamic.network/quran/audio/128/$id/$globalAyahNumber.mp3';
}
