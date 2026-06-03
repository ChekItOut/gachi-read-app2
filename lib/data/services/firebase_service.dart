import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '70879729412-fhr1b81lphpecpngaba7ehllb4ifjkue.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );
  final Uuid _uuid = const Uuid();

  // ===== 인증 =====

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential.user!);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
        'coupleId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
      });
    }
  }

  // ===== 사용자 =====

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  // 사용자 가져오기 또는 생성
  Future<AppUser?> getOrCreateUser(String uid, User firebaseUser) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _saveUserToFirestore(firebaseUser);
      final newDoc = await _db.collection('users').doc(uid).get();
      if (!newDoc.exists) return null;
      return AppUser.fromFirestore(newDoc);
    }
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<void> updateUserName(String uid, String displayName) async {
    await _db.collection('users').doc(uid).update({'displayName': displayName});
  }

  // ===== 커플 연결 =====

  Future<String> createInviteCode(String userId) async {
    // 기존 초대 코드 삭제
    final existing = await _db
        .collection('invites')
        .where('creatorId', isEqualTo: userId)
        .where('used', isEqualTo: false)
        .get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    final code = _uuid.v4().substring(0, 6).toUpperCase();
    await _db.collection('invites').doc(code).set({
      'creatorId': userId,
      'used': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<String?> joinWithInviteCode(String code, String userId) async {
    final inviteDoc = await _db.collection('invites').doc(code).get();
    if (!inviteDoc.exists) return '유효하지 않은 초대 코드입니다.';

    final data = inviteDoc.data()!;
    if (data['used'] == true) return '이미 사용된 초대 코드입니다.';
    if (data['creatorId'] == userId) return '본인의 초대 코드는 사용할 수 없습니다.';

    final creatorId = data['creatorId'] as String;

    // 커플 문서 생성
    final coupleRef = _db.collection('couples').doc();
    await coupleRef.set({
      'user1Id': creatorId,
      'user2Id': userId,
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 양쪽 사용자에 coupleId 업데이트
    await _db
        .collection('users')
        .doc(creatorId)
        .update({'coupleId': coupleRef.id});
    await _db
        .collection('users')
        .doc(userId)
        .update({'coupleId': coupleRef.id});

    // 초대 코드 사용 처리
    await inviteDoc.reference.update({'used': true});

    return null;
  }

  Future<Couple?> getCouple(String coupleId) async {
    final doc = await _db.collection('couples').doc(coupleId).get();
    if (!doc.exists) return null;
    return Couple.fromFirestore(doc);
  }

  Future<void> disconnectCouple(String coupleId, String userId) async {
    // 커플 문서를 먼저 조회하여 양쪽 사용자 ID 확보
    final coupleDoc = await _db.collection('couples').doc(coupleId).get();

    final batch = _db.batch();

    if (coupleDoc.exists) {
      final data = coupleDoc.data()!;
      final user1Id = data['user1Id'] as String;
      final user2Id = data['user2Id'] as String;
      batch.update(_db.collection('users').doc(user1Id), {'coupleId': null});
      batch.update(_db.collection('users').doc(user2Id), {'coupleId': null});
    } else {
      batch.update(_db.collection('users').doc(userId), {'coupleId': null});
    }

    batch.delete(_db.collection('couples').doc(coupleId));
    await batch.commit();
  }

  // ===== 읽기 플랜 =====

  Future<void> createReadingPlan(ReadingPlan plan) async {
    // 기존 활성 플랜 비활성화
    final existing = await _db
        .collection('readingPlans')
        .where('coupleId', isEqualTo: plan.coupleId)
        .where('isActive', isEqualTo: true)
        .get();
    for (final doc in existing.docs) {
      await doc.reference.update({'isActive': false});
    }

    await _db.collection('readingPlans').add(plan.toFirestore());
  }

  // 활성 읽기 플랜 실시간 감시
  Stream<ReadingPlan?> watchActiveReadingPlan(String coupleId) {
    return _db
        .collection('readingPlans')
        .where('coupleId', isEqualTo: coupleId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return ReadingPlan.fromFirestore(snap.docs.first);
    });
  }

  Future<ReadingPlan?> getActiveReadingPlan(String coupleId) async {
    final query = await _db
        .collection('readingPlans')
        .where('coupleId', isEqualTo: coupleId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return ReadingPlan.fromFirestore(query.docs.first);
  }

  // ===== 일일 읽기 기록 =====

  Future<DailyReading?> getDailyReading(
      String coupleId, String userId, String date) async {
    final query = await _db
        .collection('dailyReadings')
        .where('coupleId', isEqualTo: coupleId)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return DailyReading.fromFirestore(query.docs.first);
  }

  Future<void> markReadingComplete(
    String coupleId,
    String userId,
    String date,
    String bookCode,
    int chapter,
    int startVerse,
    int endVerse, {
    String? endBookCode,
    int? endChapter,
    List<Map<String, dynamic>>? passages,
    String? rangeText,
  }) async {
    final existing = await getDailyReading(coupleId, userId, date);
    final rangeFields = {
      if (endBookCode != null) 'endBookCode': endBookCode,
      if (endChapter != null) 'endChapter': endChapter,
      if (passages != null) 'passages': passages,
      if (rangeText != null) 'rangeText': rangeText,
    };
    if (existing != null) {
      await _db.collection('dailyReadings').doc(existing.id).update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        ...rangeFields,
      });
    } else {
      await _db.collection('dailyReadings').add({
        'coupleId': coupleId,
        'userId': userId,
        'date': date,
        'bookCode': bookCode,
        'chapter': chapter,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        ...rangeFields,
      });
    }
  }

  Future<List<DailyReading>> getMonthlyReadings(
      String coupleId, String userId, int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final query = await _db
        .collection('dailyReadings')
        .where('coupleId', isEqualTo: coupleId)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .where('isCompleted', isEqualTo: true)
        .get();

    return query.docs.map((doc) => DailyReading.fromFirestore(doc)).toList();
  }

  // 플랜 시작일 이후 커플의 완료된 읽기 고유 날짜 수 카운트
  Future<int> getCompletedDaysCount(String coupleId, DateTime planStartDate) async {
    final startDateStr = DateFormat('yyyy-MM-dd').format(planStartDate);
    final query = await _db
        .collection('dailyReadings')
        .where('coupleId', isEqualTo: coupleId)
        .where('isCompleted', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: startDateStr)
        .get();

    // 고유한 날짜 수 카운트 (커플 중 한 명이라도 완료하면 1일로 카운트)
    final uniqueDates = query.docs
        .map((doc) => (doc.data())['date'] as String)
        .toSet();
    return uniqueDates.length;
  }

  // ===== 소감 =====

  Future<void> saveReflection(Reflection reflection) async {
    final existing = await getReflection(
        reflection.coupleId, reflection.userId, reflection.date);
    if (existing != null) {
      await _db.collection('reflections').doc(existing.id).update({
        'content': reflection.content,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection('reflections').add(reflection.toFirestore());
    }
  }

  // 파트너 소감 실시간 감시
  Stream<Reflection?> watchPartnerReflection(
      String coupleId, String partnerId, String date) {
    return _db
        .collection('reflections')
        .where('coupleId', isEqualTo: coupleId)
        .where('userId', isEqualTo: partnerId)
        .where('date', isEqualTo: date)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return Reflection.fromFirestore(snap.docs.first);
    });
  }

  Future<Reflection?> getReflection(
      String coupleId, String userId, String date) async {
    final query = await _db
        .collection('reflections')
        .where('coupleId', isEqualTo: coupleId)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Reflection.fromFirestore(query.docs.first);
  }

  Future<List<Reflection>> getMonthlyReflections(
      String coupleId, String userId, int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final query = await _db
        .collection('reflections')
        .where('coupleId', isEqualTo: coupleId)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .get();

    return query.docs.map((doc) => Reflection.fromFirestore(doc)).toList();
  }

  // ===== AI 대화 질문 =====

  Future<void> saveAiDiscussion(AiDiscussion discussion) async {
    // 기존 것 있으면 업데이트
    final existing =
        await getAiDiscussion(discussion.coupleId, discussion.date);
    if (existing != null) {
      await _db.collection('aiDiscussions').doc(existing.id).update({
        'questions': discussion.questions,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection('aiDiscussions').add(discussion.toFirestore());
    }
  }

  Future<AiDiscussion?> getAiDiscussion(String coupleId, String date) async {
    final query = await _db
        .collection('aiDiscussions')
        .where('coupleId', isEqualTo: coupleId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return AiDiscussion.fromFirestore(query.docs.first);
  }

  Future<List<AiDiscussion>> getMonthlyAiDiscussions(
      String coupleId, int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final query = await _db
        .collection('aiDiscussions')
        .where('coupleId', isEqualTo: coupleId)
        .get();

    return query.docs
        .map((doc) => AiDiscussion.fromFirestore(doc))
        .where((discussion) =>
            discussion.date.compareTo(startDate) >= 0 &&
            discussion.date.compareTo(endDate) <= 0)
        .toList();
  }

  // ===== 저장된 구절 =====

  Future<void> saveVerse(SavedVerse verse) async {
    final existing = await _db
        .collection('savedVerses')
        .where('userId', isEqualTo: verse.userId)
        .where('bookCode', isEqualTo: verse.bookCode)
        .where('chapter', isEqualTo: verse.chapter)
        .where('verse', isEqualTo: verse.verse)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _db.collection('savedVerses').add(verse.toFirestore());
  }

  Future<void> deleteVerse(String verseId) async {
    await _db.collection('savedVerses').doc(verseId).delete();
  }

  // 그룹 단위 삭제 (book+chapter의 특정 구절들)
  Future<void> deleteVersesByGroup(
      String userId, String bookCode, int chapter) async {
    final query = await _db
        .collection('savedVerses')
        .where('userId', isEqualTo: userId)
        .where('bookCode', isEqualTo: bookCode)
        .where('chapter', isEqualTo: chapter)
        .get();
    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<SavedVerse>> watchSavedVerses(String userId) {
    return _db
        .collection('savedVerses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final verses =
          snap.docs.map((doc) => SavedVerse.fromFirestore(doc)).toList();
      verses.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return verses;
    });
  }

  // ===== 스트릭 =====

  Future<ReadingStreak?> getStreak(String userId) async {
    final doc = await _db.collection('streaks').doc(userId).get();
    if (!doc.exists) return null;
    return ReadingStreak.fromFirestore(doc);
  }

  Future<void> updateStreak(String userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _updateStreak(userId, today);
  }

  Future<void> _updateStreak(String userId, String date) async {
    final streakRef = _db.collection('streaks').doc(userId);
    final doc = await streakRef.get();

    final today = DateTime.parse(date);

    if (!doc.exists) {
      await streakRef.set({
        'currentStreak': 1,
        'longestStreak': 1,
        'lastReadDate': Timestamp.fromDate(today),
        'fireLevel': 1,
      });
      return;
    }

    final data = doc.data()!;
    final lastReadDate = (data['lastReadDate'] as Timestamp?)?.toDate();
    int currentStreak = data['currentStreak'] ?? 0;
    int longestStreak = data['longestStreak'] ?? 0;

    if (lastReadDate != null) {
      final lastDay =
          DateTime(lastReadDate.year, lastReadDate.month, lastReadDate.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      final diff = todayDay.difference(lastDay);

      if (diff.inDays == 1) {
        currentStreak++;
      } else if (diff.inDays == 0) {
        return; // 오늘 이미 읽음
      } else {
        currentStreak = 1; // 연속성 깨짐
      }
    } else {
      currentStreak = 1;
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;
    final fireLevel = ReadingStreak.calculateFireLevel(currentStreak);

    await streakRef.set({
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadDate': Timestamp.fromDate(today),
      'fireLevel': fireLevel,
    });
  }

  // ===== 캘린더 데이터 =====

  Future<Map<String, Map<String, dynamic>>> getCalendarData({
    required String coupleId,
    required String myUid,
    required String partnerId,
    required DateTime month,
  }) async {
    final year = month.year;
    final m = month.month;

    // 월별 읽기 기록 가져오기
    final myReadings = await getMonthlyReadings(coupleId, myUid, year, m);
    final partnerReadings =
        await getMonthlyReadings(coupleId, partnerId, year, m);
    final myReflections = await getMonthlyReflections(coupleId, myUid, year, m);
    final partnerReflections =
        await getMonthlyReflections(coupleId, partnerId, year, m);
    final aiDiscussions =
        await getMonthlyAiDiscussions(coupleId, year, m).catchError((Object e) {
      return <AiDiscussion>[];
    });

    final Map<String, Map<String, dynamic>> result = {};

    // 내 읽기 기록 처리
    for (final reading in myReadings) {
      result[reading.date] ??= {};
      result[reading.date]!['readingDone'] = true;
      result[reading.date]!['readingInfo'] = {
        'bookCode': reading.bookCode,
        'chapter': reading.chapter,
        'startVerse': reading.startVerse,
        'endVerse': reading.endVerse,
      };
    }

    // 파트너 읽기 기록 처리
    for (final reading in partnerReadings) {
      result[reading.date] ??= {};
      result[reading.date]!['partnerReadingDone'] = true;
    }

    // 내 소감 처리
    for (final reflection in myReflections) {
      result[reflection.date] ??= {};
      result[reflection.date]!['myReflection'] = reflection.content;
    }

    // 파트너 소감 처리
    for (final reflection in partnerReflections) {
      result[reflection.date] ??= {};
      result[reflection.date]!['partnerReflection'] = reflection.content;
    }

    // AI 대화 질문 처리
    for (final discussion in aiDiscussions) {
      result[discussion.date] ??= {};
      result[discussion.date]!['aiQuestions'] = discussion.questions;
      result[discussion.date]!['aiDiscussionCreatedAt'] =
          discussion.createdAt.toIso8601String();
    }

    // 둘 다 소감 완료 여부 계산
    for (final date in result.keys) {
      final hasMyReflection = result[date]!['myReflection'] != null;
      final hasPartnerReflection = result[date]!['partnerReflection'] != null;
      result[date]!['bothReflectionDone'] =
          hasMyReflection && hasPartnerReflection;
    }

    return result;
  }

  // ===== 통계 =====

  Future<Map<String, int>> getUserStats(String userId) async {
    // 총 읽은 날 수
    final readingsQuery = await _db
        .collection('dailyReadings')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .get();

    // 총 소감 수
    final reflectionsQuery = await _db
        .collection('reflections')
        .where('userId', isEqualTo: userId)
        .get();

    return {
      'totalReadingDays': readingsQuery.docs.length,
      'totalReflections': reflectionsQuery.docs.length,
    };
  }
}
