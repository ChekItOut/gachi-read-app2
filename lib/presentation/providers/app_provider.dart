import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../data/models/app_models.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/bible_service.dart';
import '../../data/services/ai_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final BibleService _bibleService;

  AppProvider({
    FirebaseService? firebaseService,
    BibleService? bibleService,
  })  : _firebaseService = firebaseService ?? FirebaseService.instance,
        _bibleService = bibleService ?? BibleService.instance;

  // 인증 상태
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _error;

  // 커플 정보
  Couple? _couple;
  AppUser? _partner;

  // 읽기 플랜
  ReadingPlan? _readingPlan;
  Map<String, dynamic>? _todayReading;

  // 오늘의 읽기 상태
  DailyReading? _myTodayReading;
  DailyReading? _partnerTodayReading;
  Reflection? _myReflection;
  Reflection? _partnerReflection;
  AiDiscussion? _aiDiscussion;

  // 스트릭
  ReadingStreak? _myStreak;

  // 캘린더 데이터
  Map<String, Map<String, dynamic>> _calendarData = {};

  // 통계
  int _totalReadingDays = 0;
  int _totalReflections = 0;

  // Getters
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Couple? get couple => _couple;
  AppUser? get partner => _partner;
  ReadingPlan? get readingPlan => _readingPlan;
  Map<String, dynamic>? get todayReading => _todayReading;
  DailyReading? get myTodayReading => _myTodayReading;
  DailyReading? get partnerTodayReading => _partnerTodayReading;
  Reflection? get myReflection => _myReflection;
  Reflection? get partnerReflection => _partnerReflection;
  AiDiscussion? get aiDiscussion => _aiDiscussion;
  ReadingStreak? get myStreak => _myStreak;
  Map<String, Map<String, dynamic>> get calendarData => _calendarData;
  int get totalReadingDays => _totalReadingDays;
  int get totalReflections => _totalReflections;

  bool get isAuthenticated => _firebaseUser != null;
  bool get hasCoupleConnected => _appUser?.coupleId != null;
  bool get hasReadingPlan => _readingPlan != null;
  bool get isTodayReadingComplete => _myTodayReading?.isCompleted == true;
  bool get isPartnerReadingComplete => _partnerTodayReading?.isCompleted == true;
  bool get isTodayReflectionDone => _myReflection != null;
  bool get isPartnerReflectionDone => _partnerReflection != null;

  String get todayDateString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 사용자 초기화 (AuthGate에서 호출)
  Future<void> initializeUser(User firebaseUser) async {
    if (_firebaseUser?.uid == firebaseUser.uid) return;
    _firebaseUser = firebaseUser;
    await _loadUserData(firebaseUser.uid);
  }

  void _clearData() {
    _appUser = null;
    _couple = null;
    _partner = null;
    _readingPlan = null;
    _todayReading = null;
    _myTodayReading = null;
    _partnerTodayReading = null;
    _myReflection = null;
    _partnerReflection = null;
    _aiDiscussion = null;
    _myStreak = null;
    _calendarData = {};
    _totalReadingDays = 0;
    _totalReflections = 0;
  }

  Future<void> _loadUserData(String uid) async {
    _setLoading(true);
    try {
      // 사용자 데이터 생성 또는 가져오기
      _appUser = await _firebaseService.getOrCreateUser(uid, _firebaseUser!);

      if (_appUser?.coupleId != null) {
        await _loadCoupleData(_appUser!.coupleId!);
      }
      _myStreak = await _firebaseService.getStreak(uid);
      await _loadStats(uid);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadCoupleData(String coupleId) async {
    _couple = await _firebaseService.getCouple(coupleId);
    if (_couple == null) return;

    final partnerId = _couple!.getPartnerId(_firebaseUser!.uid);
    _partner = await _firebaseService.getUser(partnerId);

    _readingPlan = await _firebaseService.getActiveReadingPlan(coupleId);
    if (_readingPlan != null) {
      _calculateTodayReading();
    }

    await _loadTodayData();
  }

  void _calculateTodayReading() {
    if (_readingPlan == null) return;
    _todayReading = _bibleService.calculateTodayReading(
      startBook: _readingPlan!.startBook,
      startChapter: _readingPlan!.startChapter,
      startVerse: _readingPlan!.startVerse,
      dailyChapters: _readingPlan!.dailyChapters,
      dailyVerses: _readingPlan!.dailyVerses,
      planStartDate: _readingPlan!.startDate,
    );
  }

  Future<void> _loadTodayData() async {
    if (_couple == null || _firebaseUser == null) return;
    final date = todayDateString;
    final coupleId = _couple!.id;
    final myUid = _firebaseUser!.uid;
    final partnerId = _couple!.getPartnerId(myUid);

    _myTodayReading = await _firebaseService.getDailyReading(coupleId, myUid, date);
    _partnerTodayReading = await _firebaseService.getDailyReading(coupleId, partnerId, date);
    _myReflection = await _firebaseService.getReflection(coupleId, myUid, date);
    _partnerReflection = await _firebaseService.getReflection(coupleId, partnerId, date);
    _aiDiscussion = await _firebaseService.getAiDiscussion(coupleId, date);
    notifyListeners();
  }

  Future<void> _loadStats(String uid) async {
    try {
      final stats = await _firebaseService.getUserStats(uid);
      _totalReadingDays = stats['totalReadingDays'] ?? 0;
      _totalReflections = stats['totalReflections'] ?? 0;
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> refreshTodayData() async {
    await _loadTodayData();
  }

  Future<void> refreshAll() async {
    if (_firebaseUser != null) {
      await _loadUserData(_firebaseUser!.uid);
    }
  }

  // 읽기 완료 처리
  Future<void> markTodayReadingComplete() async {
    if (_couple == null || _firebaseUser == null || _todayReading == null) return;
    _setLoading(true);
    try {
      await _firebaseService.markReadingComplete(
        _couple!.id,
        _firebaseUser!.uid,
        todayDateString,
        _todayReading!['bookCode'],
        _todayReading!['chapter'],
        _todayReading!['startVerse'],
        _todayReading!['endVerse'],
      );
      // 스트릭 업데이트
      await _firebaseService.updateStreak(_firebaseUser!.uid);
      _myStreak = await _firebaseService.getStreak(_firebaseUser!.uid);
      await _loadTodayData();
      await _loadStats(_firebaseUser!.uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 소감 저장
  Future<void> saveReflection(String content) async {
    if (_couple == null || _firebaseUser == null || _todayReading == null) return;
    _setLoading(true);
    try {
      final reflection = Reflection(
        id: '',
        coupleId: _couple!.id,
        userId: _firebaseUser!.uid,
        date: todayDateString,
        content: content,
        bookCode: _todayReading!['bookCode'],
        chapter: _todayReading!['chapter'],
        createdAt: DateTime.now(),
      );
      await _firebaseService.saveReflection(reflection);
      await _loadTodayData();
      await _loadStats(_firebaseUser!.uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // AI 질문 생성
  Future<void> generateAiDiscussion(List<String> verses) async {
    if (_couple == null || _myReflection == null || _partnerReflection == null) return;

    _setLoading(true);
    try {
      final aiService = AiService();
      final bookCode = _todayReading?['bookCode'] ?? '창';
      final chapter = _todayReading?['chapter'] ?? 1;

      final questions = await aiService.generateDiscussionQuestions(
        bookCode: bookCode,
        chapter: chapter,
        bookName: bookCode,
        verses: verses,
        myReflection: _myReflection!.content,
        partnerReflection: _partnerReflection!.content,
      );

      final discussion = AiDiscussion(
        id: '',
        coupleId: _couple!.id,
        date: todayDateString,
        questions: questions,
        createdAt: DateTime.now(),
      );
      await _firebaseService.saveAiDiscussion(discussion);
      _aiDiscussion = discussion;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('AI generation error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 커플 연결
  Future<String> createInviteCode() async {
    return await _firebaseService.createInviteCode(_firebaseUser!.uid);
  }

  Future<String?> joinWithInviteCode(String code) async {
    final error = await _firebaseService.joinWithInviteCode(code, _firebaseUser!.uid);
    if (error == null) {
      await _loadUserData(_firebaseUser!.uid);
    }
    return error;
  }

  // 커플 연결 해제
  Future<void> disconnectCouple() async {
    if (_couple == null || _firebaseUser == null) return;
    _setLoading(true);
    try {
      await _firebaseService.disconnectCouple(_couple!.id, _firebaseUser!.uid);
      _clearData();
      _appUser = await _firebaseService.getUser(_firebaseUser!.uid);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 읽기 플랜 생성
  Future<void> createReadingPlan({
    required String startBook,
    required int startChapter,
    required int startVerse,
    required int dailyChapters,
    required int dailyVerses,
  }) async {
    if (_couple == null) return;
    _setLoading(true);
    try {
      final plan = ReadingPlan(
        id: '',
        coupleId: _couple!.id,
        startBook: startBook,
        startChapter: startChapter,
        startVerse: startVerse,
        dailyChapters: dailyChapters,
        dailyVerses: dailyVerses,
        startDate: DateTime.now(),
        isActive: true,
      );
      await _firebaseService.createReadingPlan(plan);
      _readingPlan = plan;
      _calculateTodayReading();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 캘린더 데이터 로드
  Future<void> loadCalendarData(DateTime month) async {
    if (_couple == null || _firebaseUser == null) return;
    try {
      final myUid = _firebaseUser!.uid;
      final partnerId = _couple!.getPartnerId(myUid);
      final coupleId = _couple!.id;

      final data = await _firebaseService.getCalendarData(
        coupleId: coupleId,
        myUid: myUid,
        partnerId: partnerId,
        month: month,
      );
      _calendarData = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Calendar data error: $e');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _firebaseService.signOut();
    _firebaseUser = null;
    _clearData();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
