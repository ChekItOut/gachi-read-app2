import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../data/models/app_models.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/bible_service.dart';
import '../../data/services/ai_service.dart';

/// 레벨 변경 이벤트 타입
enum FireLevelEvent {
  none,
  levelUp, // 레벨 상승
  streakBroken, // 연속성 깨짐
}

/// 커플 연결 이벤트 타입
enum CoupleConnectionEvent {
  none,
  connected, // 커플 연결됨
  disconnected, // 커플 해제됨
}

/// 읽기 플랜 이벤트 타입
enum ReadingPlanEvent {
  none,
  created, // 플랜 생성됨
  updated, // 플랜 수정됨
}

/// 파트너 소감 이벤트 타입
enum PartnerReflectionEvent {
  none,
  submitted, // 파트너 소감 작성 완료
}

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

  // 레벨 이벤트 (UI에서 소비 후 none으로 리셋)
  FireLevelEvent _fireLevelEvent = FireLevelEvent.none;
  int _prevFireLevel = 1; // 레벨업 전 레벨 (fromLevel 용)

  // 커플 연결 실시간 감시
  StreamSubscription<AppUser?>? _userWatchSubscription;
  CoupleConnectionEvent _coupleConnectionEvent = CoupleConnectionEvent.none;
  String? _newPartnerName;

  // 커플 데이터 실시간 감시
  StreamSubscription? _readingPlanWatchSubscription;
  StreamSubscription? _partnerReflectionWatchSubscription;
  ReadingPlanEvent _readingPlanEvent = ReadingPlanEvent.none;
  PartnerReflectionEvent _partnerReflectionEvent = PartnerReflectionEvent.none;

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
  FireLevelEvent get fireLevelEvent => _fireLevelEvent;
  int get prevFireLevel => _prevFireLevel;
  CoupleConnectionEvent get coupleConnectionEvent => _coupleConnectionEvent;
  String? get newPartnerName => _newPartnerName;
  ReadingPlanEvent get readingPlanEvent => _readingPlanEvent;
  PartnerReflectionEvent get partnerReflectionEvent => _partnerReflectionEvent;
  Map<String, Map<String, dynamic>> get calendarData => _calendarData;
  int get totalReadingDays => _totalReadingDays;
  int get totalReflections => _totalReflections;

  bool get isAuthenticated => _firebaseUser != null;
  bool get hasCoupleConnected => _appUser?.coupleId != null;
  bool get hasReadingPlan => _readingPlan != null;
  bool get isTodayReadingComplete => _myTodayReading?.isCompleted == true;
  bool get isPartnerReadingComplete =>
      _partnerTodayReading?.isCompleted == true;
  bool get isTodayReflectionDone => _myReflection != null;
  bool get isPartnerReflectionDone => _partnerReflection != null;

  String get todayDateString => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// 레벨 이벤트 소비 (화면에서 처리 후 반드시 호출)
  void consumeFireLevelEvent() {
    _fireLevelEvent = FireLevelEvent.none;
    notifyListeners();
  }

  /// 커플 연결 이벤트 소비 (화면에서 처리 후 반드시 호출)
  void consumeCoupleConnectionEvent() {
    _coupleConnectionEvent = CoupleConnectionEvent.none;
    _newPartnerName = null;
    notifyListeners();
  }

  /// 읽기 플랜 이벤트 소비
  void consumeReadingPlanEvent() {
    _readingPlanEvent = ReadingPlanEvent.none;
    notifyListeners();
  }

  /// 파트너 소감 이벤트 소비
  void consumePartnerReflectionEvent() {
    _partnerReflectionEvent = PartnerReflectionEvent.none;
    notifyListeners();
  }

  // 사용자 초기화 (AuthGate에서 호출)
  Future<void> initializeUser(User firebaseUser) async {
    if (_firebaseUser?.uid == firebaseUser.uid) return;
    _firebaseUser = firebaseUser;
    await _loadUserData(firebaseUser.uid);
    _startWatchingUser(firebaseUser.uid);
    // 이미 커플 연결 상태면 커플 데이터 감시 시작
    if (_appUser?.coupleId != null) {
      _startWatchingCoupleData(_appUser!.coupleId!);
    }
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
    _fireLevelEvent = FireLevelEvent.none;
    _prevFireLevel = 1;
    _coupleConnectionEvent = CoupleConnectionEvent.none;
    _newPartnerName = null;
    _readingPlanEvent = ReadingPlanEvent.none;
    _partnerReflectionEvent = PartnerReflectionEvent.none;
    _calendarData = {};
    _totalReadingDays = 0;
    _totalReflections = 0;
  }

  /// Firestore 실시간 감시 시작 (coupleId 변경 감지)
  void _startWatchingUser(String uid) {
    _stopWatchingUser();
    _userWatchSubscription =
        _firebaseService.watchUser(uid).listen((updatedUser) {
      if (updatedUser == null) return;

      final oldCoupleId = _appUser?.coupleId;
      final newCoupleId = updatedUser.coupleId;

      // coupleId가 null → 값으로 변경된 경우 = 커플 연결됨
      if (oldCoupleId == null && newCoupleId != null) {
        _appUser = updatedUser;
        _onCoupleConnected(newCoupleId);
      }
      // coupleId가 값 → null로 변경된 경우 = 커플 해제됨
      else if (oldCoupleId != null && newCoupleId == null) {
        _onCoupleDisconnected(uid);
      }
    });
  }

  /// Firestore 실시간 감시 중지
  void _stopWatchingUser() {
    _userWatchSubscription?.cancel();
    _userWatchSubscription = null;
  }

  /// 커플 연결 감지 시 처리
  Future<void> _onCoupleConnected(String coupleId) async {
    try {
      await _loadCoupleData(coupleId);
      _newPartnerName = _partner?.displayName;
      _coupleConnectionEvent = CoupleConnectionEvent.connected;
      _startWatchingCoupleData(coupleId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error on couple connected: $e');
    }
  }

  /// 커플 해제 감지 시 처리
  Future<void> _onCoupleDisconnected(String uid) async {
    try {
      _stopWatchingCoupleData();
      _clearData();
      _appUser = await _firebaseService.getUser(uid);
      _coupleConnectionEvent = CoupleConnectionEvent.disconnected;
      notifyListeners();
    } catch (e) {
      debugPrint('Error on couple disconnected: $e');
    }
  }

  /// 커플 데이터(플랜, 파트너 소감) 실시간 감시 시작
  void _startWatchingCoupleData(String coupleId) {
    _stopWatchingCoupleData();
    if (_couple == null || _firebaseUser == null) return;

    final partnerId = _couple!.getPartnerId(_firebaseUser!.uid);
    final today = todayDateString;

    // 활성 읽기 플랜 감시
    _readingPlanWatchSubscription =
        _firebaseService.watchActiveReadingPlan(coupleId).listen((newPlan) async {
      // 플랜이 없던 상태에서 새 플랜이 생긴 경우
      if (_readingPlan == null && newPlan != null) {
        _readingPlan = newPlan;
        await _calculateTodayReading();
        _readingPlanEvent = ReadingPlanEvent.created;
        notifyListeners();
      } else if (_readingPlan != null &&
          newPlan != null &&
          _readingPlan!.id != newPlan.id) {
        // 기존 플랜과 다른 플랜으로 교체된 경우 = 플랜 수정
        _readingPlan = newPlan;
        await _calculateTodayReading();
        _loadTodayData();
        _readingPlanEvent = ReadingPlanEvent.updated;
        notifyListeners();
      } else if (newPlan != null) {
        // 플랜 데이터 동기화
        _readingPlan = newPlan;
        await _calculateTodayReading();
        notifyListeners();
      }
    });

    // 파트너 소감 감시
    _partnerReflectionWatchSubscription = _firebaseService
        .watchPartnerReflection(coupleId, partnerId, today)
        .listen((newReflection) {
      // 파트너 소감이 없던 상태에서 새로 작성된 경우
      if (_partnerReflection == null && newReflection != null) {
        _partnerReflection = newReflection;
        _partnerReflectionEvent = PartnerReflectionEvent.submitted;
        notifyListeners();
      } else if (newReflection != null) {
        _partnerReflection = newReflection;
        notifyListeners();
      }
    });
  }

  /// 커플 데이터 감시 중지
  void _stopWatchingCoupleData() {
    _readingPlanWatchSubscription?.cancel();
    _readingPlanWatchSubscription = null;
    _partnerReflectionWatchSubscription?.cancel();
    _partnerReflectionWatchSubscription = null;
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
      await _calculateTodayReading();
    }

    await _loadTodayData();
  }

  Future<void> _calculateTodayReading() async {
    if (_readingPlan == null || _couple == null) return;

    // 플랜 시작일 이후 완료된 고유 날짜 수 조회
    int totalCompleted = await _firebaseService.getCompletedDaysCount(
      _couple!.id,
      _readingPlan!.startDate,
    );

    // 오늘 이미 완료한 경우, 오늘 읽은 것을 계속 표시 (다음 날로 넘기지 않음)
    if (totalCompleted > 0) {
      final todayStr = todayDateString;
      final myToday = await _firebaseService.getDailyReading(
        _couple!.id, _firebaseUser!.uid, todayStr);
      final partnerId = _couple!.getPartnerId(_firebaseUser!.uid);
      final partnerToday = await _firebaseService.getDailyReading(
        _couple!.id, partnerId, todayStr);
      final todayCompleted =
          (myToday?.isCompleted ?? false) || (partnerToday?.isCompleted ?? false);
      if (todayCompleted) {
        totalCompleted -= 1;
      }
    }

    _todayReading = _bibleService.calculateTodayReading(
      startBook: _readingPlan!.startBook,
      startChapter: _readingPlan!.startChapter,
      startVerse: _readingPlan!.startVerse,
      dailyChapters: _readingPlan!.dailyChapters,
      dailyVerses: _readingPlan!.dailyVerses,
      completedDays: totalCompleted,
    );
  }

  Future<void> _loadTodayData() async {
    if (_couple == null || _firebaseUser == null) return;
    final date = todayDateString;
    final coupleId = _couple!.id;
    final myUid = _firebaseUser!.uid;
    final partnerId = _couple!.getPartnerId(myUid);

    _myTodayReading =
        await _firebaseService.getDailyReading(coupleId, myUid, date);
    _partnerTodayReading =
        await _firebaseService.getDailyReading(coupleId, partnerId, date);
    _myReflection = await _firebaseService.getReflection(coupleId, myUid, date);
    _partnerReflection =
        await _firebaseService.getReflection(coupleId, partnerId, date);
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
      // 이전 streak 상태 기록 (연속성 깨짐 감지용)
      final oldStreak = _myStreak;
      final oldFireLevel = oldStreak?.fireLevel ?? 1;

      await _loadUserData(_firebaseUser!.uid);

      // 연속성 깨짐 감지: 이전에 레벨이 있었는데 현재 레벨이 낮아진 경우
      final newFireLevel = _myStreak?.fireLevel ?? 1;
      if (oldStreak != null && newFireLevel < oldFireLevel) {
        _prevFireLevel = oldFireLevel;
        _fireLevelEvent = FireLevelEvent.streakBroken;
        notifyListeners();
      }
    }
  }

  // 읽기 완료 처리
  Future<void> markTodayReadingComplete() async {
    if (_couple == null || _firebaseUser == null || _todayReading == null) {
      return;
    }
    _setLoading(true);
    try {
      // 스트릭 업데이트 전 레벨 기록
      final oldFireLevel = _myStreak?.fireLevel ?? 1;

      await _firebaseService.markReadingComplete(
        _couple!.id,
        _firebaseUser!.uid,
        todayDateString,
        _todayReading!['bookCode'],
        _todayReading!['chapter'],
        _todayReading!['startVerse'],
        _todayReading!['endVerse'],
        endBookCode: _todayReading!['endBookCode'],
        endChapter: _todayReading!['endChapter'],
        passages: (_todayReading!['passages'] as List?)
            ?.whereType<Map>()
            .map((passage) => Map<String, dynamic>.from(passage))
            .toList(),
        rangeText: _todayReading!['rangeText'],
      );
      // 스트릭 업데이트
      await _firebaseService.updateStreak(_firebaseUser!.uid);
      _myStreak = await _firebaseService.getStreak(_firebaseUser!.uid);

      // 레벨업 감지
      final newFireLevel = _myStreak?.fireLevel ?? 1;
      if (newFireLevel > oldFireLevel) {
        _prevFireLevel = oldFireLevel;
        _fireLevelEvent = FireLevelEvent.levelUp;
      }

      await _loadTodayData();
      await _loadStats(_firebaseUser!.uid);
      await loadCalendarData(DateTime.now());
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 소감 저장
  Future<void> saveReflection(String content) async {
    if (_couple == null || _firebaseUser == null || _todayReading == null) {
      return;
    }
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
      await loadCalendarData(DateTime.now());
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // AI 질문 생성
  Future<void> generateAiDiscussion(List<String> verses) async {
    if (_couple == null ||
        _myReflection == null ||
        _partnerReflection == null) {
      return;
    }

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
      if (aiService.isDefaultQuestions(questions)) {
        debugPrint('AI discussion generated with default fallback questions.');
      } else {
        debugPrint('AI discussion generated with Gemini questions.');
      }

      final discussion = AiDiscussion(
        id: '',
        coupleId: _couple!.id,
        date: todayDateString,
        questions: questions,
        createdAt: DateTime.now(),
      );
      await _firebaseService.saveAiDiscussion(discussion);
      _aiDiscussion = discussion;
      await loadCalendarData(DateTime.now());
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
    final error =
        await _firebaseService.joinWithInviteCode(code, _firebaseUser!.uid);
    if (error == null) {
      // 중복 감지 방지: 감시 중지 후 데이터 로드, 다시 감시 시작
      _stopWatchingUser();
      await _loadUserData(_firebaseUser!.uid);
      _startWatchingUser(_firebaseUser!.uid);
      if (_appUser?.coupleId != null) {
        _startWatchingCoupleData(_appUser!.coupleId!);
      }
    }
    return error;
  }

  // 커플 연결 해제
  Future<void> disconnectCouple() async {
    if (_couple == null || _firebaseUser == null) return;
    _setLoading(true);
    try {
      _stopWatchingCoupleData();
      _stopWatchingUser();
      await _firebaseService.disconnectCouple(_couple!.id, _firebaseUser!.uid);
      _clearData();
      _appUser = await _firebaseService.getUser(_firebaseUser!.uid);
      _startWatchingUser(_firebaseUser!.uid);
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
      // 중복 감지 방지: 플랜 감시 일시 중지
      _readingPlanWatchSubscription?.cancel();
      _readingPlanWatchSubscription = null;

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
      await _calculateTodayReading();
      notifyListeners();

      // 플랜 감시 재시작
      if (_couple != null) {
        _startWatchingCoupleData(_couple!.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 읽기 플랜 수정
  Future<void> updateReadingPlan({
    required String startBook,
    required int startChapter,
    required int startVerse,
    required int dailyChapters,
    required int dailyVerses,
  }) async {
    if (_couple == null) return;
    _setLoading(true);
    try {
      // 중복 감지 방지: 플랜 감시 일시 중지
      _readingPlanWatchSubscription?.cancel();
      _readingPlanWatchSubscription = null;

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
      await _calculateTodayReading();
      await _loadTodayData();

      // 플랜 감시 재시작
      if (_couple != null) {
        _startWatchingCoupleData(_couple!.id);
      }
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
    _stopWatchingCoupleData();
    _stopWatchingUser();
    await _firebaseService.signOut();
    _firebaseUser = null;
    _clearData();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopWatchingCoupleData();
    _stopWatchingUser();
    super.dispose();
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
