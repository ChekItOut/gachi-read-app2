import 'package:flutter/material.dart';
import '../../data/services/bible_service.dart';
import '../../core/constants/bible_constants.dart';

/// 읽기 단위 타입
enum ReadingUnit { chapter, verse }

class DemoProvider extends ChangeNotifier {
  // 앱 상태
  bool _isLoggedIn = false;
  bool _hasCoupleConnected = false;
  bool _hasReadingPlan = false;
  bool _isTodayReadingComplete = false;
  bool _isMyReflectionDone = false;
  bool _isPartnerReflectionDone = false;
  bool _isLoading = false;

  // 사용자 정보
  String _myName = '나';
  String _partnerName = '파트너';

  // 읽기 플랜 설정
  ReadingUnit _readingUnit = ReadingUnit.chapter; // 장 단위 or 절 단위
  int _dailyAmount = 1;   // 하루에 몇 장 or 몇 절

  // 성경 읽기 상태
  String _currentBook = '창';
  int _currentChapter = 1;
  int _startVerse = 1;
  int _endVerse = 10;
  List<Map<String, dynamic>> _todayVerses = [];

  // 소감
  String _myReflection = '';
  String _partnerReflection = '';

  // AI 질문
  List<String> _aiQuestions = [];

  // 스트릭
  int _currentStreak = 3;
  int _longestStreak = 7;
  int _fireLevel = 1;

  // 캘린더 데이터 (완료한 날짜들)
  final Set<String> _completedDates = {};

  // 자유 읽기 - 저장된 구절
  final List<Map<String, dynamic>> _savedVerses = [];

  // 자유 읽기 현재 위치
  String _freeBibleBook = '창';
  int _freeBibleChapter = 1;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get hasCoupleConnected => _hasCoupleConnected;
  bool get hasReadingPlan => _hasReadingPlan;
  bool get isTodayReadingComplete => _isTodayReadingComplete;
  bool get isMyReflectionDone => _isMyReflectionDone;
  bool get isPartnerReflectionDone => _isPartnerReflectionDone;
  bool get isLoading => _isLoading;
  String get myName => _myName;
  String get partnerName => _partnerName;
  ReadingUnit get readingUnit => _readingUnit;
  int get dailyAmount => _dailyAmount;
  String get currentBook => _currentBook;
  int get currentChapter => _currentChapter;
  int get startVerse => _startVerse;
  int get endVerse => _endVerse;
  List<Map<String, dynamic>> get todayVerses => _todayVerses;
  String get myReflection => _myReflection;
  String get partnerReflection => _partnerReflection;
  List<String> get aiQuestions => _aiQuestions;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get fireLevel => _fireLevel;
  Set<String> get completedDates => _completedDates;
  List<Map<String, dynamic>> get savedVerses => _savedVerses;
  String get freeBibleBook => _freeBibleBook;
  int get freeBibleChapter => _freeBibleChapter;

  /// 오늘 읽기 범위 요약 텍스트 (예: "창세기 1장 1-10절" or "창세기 1-2장")
  String get todayRangeText {
    final bookName = BibleConstants.getBookName(_currentBook);
    if (_readingUnit == ReadingUnit.verse) {
      return '$bookName ${_currentChapter}장 ${_startVerse}-${_endVerse}절';
    } else {
      if (_dailyAmount == 1) {
        return '$bookName ${_currentChapter}장';
      } else {
        return '$bookName ${_currentChapter}-${_currentChapter + _dailyAmount - 1}장';
      }
    }
  }

  String get todayDateString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ─── 로그인 (데모) ───────────────────────────────────────────────────────
  Future<void> demoLogin(String name) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoggedIn = true;
    _myName = name.isNotEmpty ? name : '데모 사용자';
    _setLoading(false);
  }

  // ─── 커플 연결 (데모) ────────────────────────────────────────────────────
  Future<void> connectCouple(String partnerName) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 600));
    _hasCoupleConnected = true;
    _partnerName = partnerName.isNotEmpty ? partnerName : '파트너';
    // 샘플 완료 날짜 추가
    final now = DateTime.now();
    for (int i = 1; i <= 3; i++) {
      final d = now.subtract(Duration(days: i));
      _completedDates.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
    _setLoading(false);
  }

  // ─── 읽기 플랜 설정 ──────────────────────────────────────────────────────
  Future<void> setReadingPlan({
    required String book,
    required int chapter,
    required ReadingUnit unit,
    required int dailyAmount,
    int startVerse = 1,
  }) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));
    _hasReadingPlan = true;
    _currentBook = book;
    _currentChapter = chapter;
    _readingUnit = unit;
    _dailyAmount = dailyAmount;

    if (unit == ReadingUnit.verse) {
      _startVerse = startVerse;
      _endVerse = startVerse + dailyAmount - 1;
    } else {
      // 장 단위: 해당 장 전체
      _startVerse = 1;
      final totalVerses =
          BibleService.instance.getVerses(book, chapter).length;
      _endVerse = totalVerses;
    }

    await _loadTodayVerses();
    _setLoading(false);
  }

  // ─── 오늘의 성경 구절 로드 ───────────────────────────────────────────────
  Future<void> _loadTodayVerses() async {
    if (_readingUnit == ReadingUnit.chapter) {
      // 장 단위: dailyAmount만큼 여러 장 합산
      List<Map<String, dynamic>> allVerses = [];
      for (int i = 0; i < _dailyAmount; i++) {
        final chap = _currentChapter + i;
        final totalChapters =
            BibleService.instance.getChapterCount(_currentBook);
        if (chap > totalChapters) break;
        final verses = BibleService.instance.getVerses(_currentBook, chap);
        // 장 번호 정보 추가
        for (final v in verses) {
          allVerses.add({...v, 'chapterNum': chap});
        }
      }
      _todayVerses = allVerses;
      // endVerse를 마지막 절로 업데이트
      if (allVerses.isNotEmpty) {
        _endVerse = allVerses.last['verse'] as int;
      }
    } else {
      // 절 단위
      final verses =
          BibleService.instance.getVerses(_currentBook, _currentChapter);
      if (verses.isNotEmpty) {
        final end = (_endVerse <= verses.length) ? _endVerse : verses.length;
        _todayVerses = verses
            .where((v) => v['verse'] >= _startVerse && v['verse'] <= end)
            .toList();
      }
    }
  }

  // 오늘의 구절 로드 (외부 호출용)
  Future<void> loadTodayVerses() async {
    if (_hasReadingPlan && _todayVerses.isEmpty) {
      await _loadTodayVerses();
      notifyListeners();
    }
  }

  // ─── 읽기 완료 처리 ──────────────────────────────────────────────────────
  Future<void> completeReading() async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));
    _isTodayReadingComplete = true;
    _completedDates.add(todayDateString);
    _currentStreak += 1;
    if (_currentStreak >= 10) {
      _fireLevel = 3;
    } else if (_currentStreak >= 5) {
      _fireLevel = 2;
    }
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
    _setLoading(false);
  }

  // ─── 소감 저장 ───────────────────────────────────────────────────────────
  Future<void> saveMyReflection(String content) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 400));
    _myReflection = content;
    _isMyReflectionDone = true;
    // 데모: 파트너도 2초 후 자동으로 소감 작성
    Future.delayed(const Duration(seconds: 2), () {
      _partnerReflection =
          '오늘 말씀을 읽으면서 하나님의 사랑이 얼마나 크고 넓은지 다시 한번 느꼈어요. 특히 ${_currentChapter}장 말씀이 마음에 깊이 와닿았고, 우리 관계에서도 이런 사랑을 실천하고 싶다는 생각이 들었어요.';
      _isPartnerReflectionDone = true;
      notifyListeners();
    });
    _setLoading(false);
  }

  // ─── AI 질문 생성 (데모) ─────────────────────────────────────────────────
  Future<void> generateAiQuestions() async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));
    _aiQuestions = [
      '오늘 읽은 말씀 중 가장 마음에 와닿은 구절은 무엇이었나요? 그 이유는?',
      '말씀에서 발견한 하나님의 성품이 우리 관계에 어떻게 적용될 수 있을까요?',
      '오늘 말씀을 통해 서로에게 더 잘해줄 수 있는 한 가지 방법이 있다면 무엇일까요?',
      '이번 주 말씀을 삶에서 실천할 수 있는 구체적인 방법을 함께 이야기해봐요.',
    ];
    _setLoading(false);
  }

  // ─── 자유 읽기 ───────────────────────────────────────────────────────────
  void setFreeBiblePosition(String book, int chapter) {
    _freeBibleBook = book;
    _freeBibleChapter = chapter;
    notifyListeners();
  }

  void goToNextChapter() {
    final totalChapters =
        BibleService.instance.getChapterCount(_freeBibleBook);
    if (_freeBibleChapter < totalChapters) {
      _freeBibleChapter++;
    } else {
      final books = BibleService.instance.getBookList();
      final idx = books.indexOf(_freeBibleBook);
      if (idx < books.length - 1) {
        _freeBibleBook = books[idx + 1];
        _freeBibleChapter = 1;
      }
    }
    notifyListeners();
  }

  void goToPrevChapter() {
    if (_freeBibleChapter > 1) {
      _freeBibleChapter--;
    } else {
      final books = BibleService.instance.getBookList();
      final idx = books.indexOf(_freeBibleBook);
      if (idx > 0) {
        _freeBibleBook = books[idx - 1];
        _freeBibleChapter =
            BibleService.instance.getChapterCount(_freeBibleBook);
      }
    }
    notifyListeners();
  }

  // ─── 구절 저장/삭제 ──────────────────────────────────────────────────────
  void saveVerse(String bookCode, int chapter, int verse, String content) {
    final ref = '$bookCode $chapter:$verse';
    final exists = _savedVerses.any((v) => v['reference'] == ref);
    if (!exists) {
      _savedVerses.insert(0, {
        'reference': ref,
        'content': content,
        'bookCode': bookCode,
        'chapter': chapter,
        'verse': verse,
      });
      notifyListeners();
    }
  }

  void deleteVerse(String reference) {
    _savedVerses.removeWhere((v) => v['reference'] == reference);
    notifyListeners();
  }

  // ─── 로그아웃 ────────────────────────────────────────────────────────────
  void logout() {
    _isLoggedIn = false;
    _hasCoupleConnected = false;
    _hasReadingPlan = false;
    _isTodayReadingComplete = false;
    _isMyReflectionDone = false;
    _isPartnerReflectionDone = false;
    _myReflection = '';
    _partnerReflection = '';
    _aiQuestions = [];
    _todayVerses = [];
    _currentStreak = 3;
    _fireLevel = 1;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
