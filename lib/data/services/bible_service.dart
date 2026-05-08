import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/constants/bible_constants.dart';

class BibleVerse {
  final String bookCode;
  final int chapter;
  final int verse;
  final String content;

  BibleVerse({
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.content,
  });

  String get reference => '${BibleConstants.getBookName(bookCode)} $chapter:$verse';
  String get key => '$bookCode$chapter:$verse';
}

class BibleService {
  static BibleService? _instance;
  static BibleService get instance => _instance ??= BibleService._();
  BibleService._();

  Map<String, String>? _bibleData;
  bool _isLoaded = false;

  Future<void> loadBible() async {
    if (_isLoaded) return;
    final String jsonString = await rootBundle.loadString('assets/data/bible.json');
    _bibleData = Map<String, String>.from(json.decode(jsonString));
    _isLoaded = true;
  }

  Map<String, String> get bibleData {
    if (_bibleData == null) throw Exception('Bible not loaded');
    return _bibleData!;
  }

  // 특정 구절 가져오기
  String? getVerse(String bookCode, int chapter, int verse) {
    return _bibleData?['$bookCode$chapter:$verse'];
  }

  // 특정 장의 모든 절 가져오기
  List<BibleVerse> getChapter(String bookCode, int chapter) {
    if (_bibleData == null) return [];
    final List<BibleVerse> verses = [];
    int verse = 1;
    while (true) {
      final key = '$bookCode$chapter:$verse';
      final content = _bibleData![key];
      if (content == null) break;
      verses.add(BibleVerse(
        bookCode: bookCode,
        chapter: chapter,
        verse: verse,
        content: content.trim(),
      ));
      verse++;
    }
    return verses;
  }

  // 특정 범위의 절 가져오기
  List<BibleVerse> getVerseRange(
      String bookCode, int chapter, int startVerse, int endVerse) {
    if (_bibleData == null) return [];
    final List<BibleVerse> verses = [];
    for (int v = startVerse; v <= endVerse; v++) {
      final key = '$bookCode$chapter:$v';
      final content = _bibleData![key];
      if (content != null) {
        verses.add(BibleVerse(
          bookCode: bookCode,
          chapter: chapter,
          verse: v,
          content: content.trim(),
        ));
      }
    }
    return verses;
  }

  // 특정 책의 총 장 수 가져오기
  int getChapterCount(String bookCode) {
    if (_bibleData == null) return 0;
    int chapter = 1;
    while (_bibleData!.containsKey('$bookCode$chapter:1')) {
      chapter++;
    }
    return chapter - 1;
  }

  // 특정 장의 총 절 수 가져오기
  int getVerseCount(String bookCode, int chapter) {
    if (_bibleData == null) return 0;
    int verse = 1;
    while (_bibleData!.containsKey('$bookCode$chapter:$verse')) {
      verse++;
    }
    return verse - 1;
  }

  // 다음 장 정보 가져오기 (책 경계 처리)
  Map<String, dynamic>? getNextChapter(String bookCode, int chapter) {
    final totalChapters = getChapterCount(bookCode);
    if (chapter < totalChapters) {
      return {'bookCode': bookCode, 'chapter': chapter + 1};
    }
    // 다음 책으로
    final allBooks = BibleConstants.allBookCodes;
    final currentIndex = allBooks.indexOf(bookCode);
    if (currentIndex < allBooks.length - 1) {
      final nextBook = allBooks[currentIndex + 1];
      return {'bookCode': nextBook, 'chapter': 1};
    }
    return null;
  }

  // 이전 장 정보 가져오기
  Map<String, dynamic>? getPrevChapter(String bookCode, int chapter) {
    if (chapter > 1) {
      return {'bookCode': bookCode, 'chapter': chapter - 1};
    }
    // 이전 책으로
    final allBooks = BibleConstants.allBookCodes;
    final currentIndex = allBooks.indexOf(bookCode);
    if (currentIndex > 0) {
      final prevBook = allBooks[currentIndex - 1];
      final prevChapterCount = getChapterCount(prevBook);
      return {'bookCode': prevBook, 'chapter': prevChapterCount};
    }
    return null;
  }

  // 오늘의 읽기 범위 계산 (플랜 기반)
  Map<String, dynamic> calculateTodayReading({
    required String startBook,
    required int startChapter,
    required int startVerse,
    required int dailyChapters,
    required int dailyVerses,
    required DateTime planStartDate,
  }) {
    final today = DateTime.now();
    final daysSinceStart = today.difference(planStartDate).inDays;

    String currentBook = startBook;
    int currentChapter = startChapter;
    int currentStartVerse = startVerse;

    if (dailyChapters > 0) {
      // 장 단위 읽기
      int totalChaptersToSkip = daysSinceStart * dailyChapters;
      int chaptersSkipped = 0;

      while (chaptersSkipped < totalChaptersToSkip) {
        final totalChapters = getChapterCount(currentBook);
        if (currentChapter < totalChapters) {
          currentChapter++;
        } else {
          final allBooks = BibleConstants.allBookCodes;
          final idx = allBooks.indexOf(currentBook);
          if (idx < allBooks.length - 1) {
            currentBook = allBooks[idx + 1];
            currentChapter = 1;
          } else {
            break;
          }
        }
        chaptersSkipped++;
      }

      final endVerse = getVerseCount(currentBook, currentChapter);
      return {
        'bookCode': currentBook,
        'chapter': currentChapter,
        'startVerse': 1,
        'endVerse': endVerse,
      };
    } else {
      // 절 단위 읽기
      int totalVersesToSkip = daysSinceStart * dailyVerses;
      int versesSkipped = 0;
      int currentVerse = currentStartVerse;

      while (versesSkipped < totalVersesToSkip) {
        final totalVerses = getVerseCount(currentBook, currentChapter);
        if (currentVerse < totalVerses) {
          currentVerse++;
        } else {
          final next = getNextChapter(currentBook, currentChapter);
          if (next != null) {
            currentBook = next['bookCode'];
            currentChapter = next['chapter'];
            currentVerse = 1;
          } else {
            break;
          }
        }
        versesSkipped++;
      }

      final endVerse = (currentVerse + dailyVerses - 1)
          .clamp(currentVerse, getVerseCount(currentBook, currentChapter));
      return {
        'bookCode': currentBook,
        'chapter': currentChapter,
        'startVerse': currentVerse,
        'endVerse': endVerse,
      };
    }
  }

  // 장의 구절 목록을 Map 형태로 반환 (demo용)
  List<Map<String, dynamic>> getVerses(String bookCode, int chapter) {
    final verses = getChapter(bookCode, chapter);
    return verses.map((v) => {
      'verse': v.verse,
      'content': v.content,
    }).toList();
  }

  // 전체 책 코드 목록 반환
  List<String> getBookList() {
    return BibleConstants.allBookCodes;
  }
}

// 추가 헬퍼 메서드 (demo용)
