import 'package:cloud_firestore/cloud_firestore.dart';

// 사용자 모델
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? coupleId;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.coupleId,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      coupleId: data['coupleId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'coupleId': coupleId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? coupleId,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      coupleId: coupleId ?? this.coupleId,
      createdAt: createdAt,
    );
  }
}

// 커플 모델
class Couple {
  final String id;
  final String user1Id;
  final String user2Id;
  final String inviteCode;
  final DateTime createdAt;

  Couple({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.inviteCode,
    required this.createdAt,
  });

  factory Couple.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Couple(
      id: doc.id,
      user1Id: data['user1Id'] ?? '',
      user2Id: data['user2Id'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String getPartnerId(String myUid) {
    return user1Id == myUid ? user2Id : user1Id;
  }
}

// 읽기 플랜 모델
class ReadingPlan {
  final String id;
  final String coupleId;
  final String startBook;   // 시작 책 코드 (예: '창')
  final int startChapter;   // 시작 장
  final int startVerse;     // 시작 절
  final int dailyChapters;  // 하루 장 수 (0이면 절 단위)
  final int dailyVerses;    // 하루 절 수 (dailyChapters가 0일 때 사용)
  final DateTime startDate;
  final bool isActive;

  ReadingPlan({
    required this.id,
    required this.coupleId,
    required this.startBook,
    required this.startChapter,
    required this.startVerse,
    required this.dailyChapters,
    required this.dailyVerses,
    required this.startDate,
    required this.isActive,
  });

  factory ReadingPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReadingPlan(
      id: doc.id,
      coupleId: data['coupleId'] ?? '',
      startBook: data['startBook'] ?? '창',
      startChapter: data['startChapter'] ?? 1,
      startVerse: data['startVerse'] ?? 1,
      dailyChapters: data['dailyChapters'] ?? 1,
      dailyVerses: data['dailyVerses'] ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coupleId': coupleId,
      'startBook': startBook,
      'startChapter': startChapter,
      'startVerse': startVerse,
      'dailyChapters': dailyChapters,
      'dailyVerses': dailyVerses,
      'startDate': Timestamp.fromDate(startDate),
      'isActive': isActive,
    };
  }
}

// 일일 읽기 기록 모델
class DailyReading {
  final String id;
  final String coupleId;
  final String userId;
  final String date;         // 'yyyy-MM-dd' 형식
  final String bookCode;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final bool isCompleted;
  final DateTime? completedAt;

  DailyReading({
    required this.id,
    required this.coupleId,
    required this.userId,
    required this.date,
    required this.bookCode,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.isCompleted,
    this.completedAt,
  });

  factory DailyReading.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyReading(
      id: doc.id,
      coupleId: data['coupleId'] ?? '',
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      bookCode: data['bookCode'] ?? '',
      chapter: data['chapter'] ?? 1,
      startVerse: data['startVerse'] ?? 1,
      endVerse: data['endVerse'] ?? 1,
      isCompleted: data['isCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coupleId': coupleId,
      'userId': userId,
      'date': date,
      'bookCode': bookCode,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  String get verseRange => '$bookCode $chapter:$startVerse-$endVerse';
}

// 소감(나눔) 모델
class Reflection {
  final String id;
  final String coupleId;
  final String userId;
  final String date;         // 'yyyy-MM-dd' 형식
  final String content;
  final String bookCode;
  final int chapter;
  final DateTime createdAt;

  Reflection({
    required this.id,
    required this.coupleId,
    required this.userId,
    required this.date,
    required this.content,
    required this.bookCode,
    required this.chapter,
    required this.createdAt,
  });

  factory Reflection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reflection(
      id: doc.id,
      coupleId: data['coupleId'] ?? '',
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      content: data['content'] ?? '',
      bookCode: data['bookCode'] ?? '',
      chapter: data['chapter'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coupleId': coupleId,
      'userId': userId,
      'date': date,
      'content': content,
      'bookCode': bookCode,
      'chapter': chapter,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// AI 대화 질문 모델
class AiDiscussion {
  final String id;
  final String coupleId;
  final String date;
  final List<String> questions;
  final DateTime createdAt;

  AiDiscussion({
    required this.id,
    required this.coupleId,
    required this.date,
    required this.questions,
    required this.createdAt,
  });

  factory AiDiscussion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AiDiscussion(
      id: doc.id,
      coupleId: data['coupleId'] ?? '',
      date: data['date'] ?? '',
      questions: List<String>.from(data['questions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coupleId': coupleId,
      'date': date,
      'questions': questions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// 저장된 구절 모델
class SavedVerse {
  final String id;
  final String userId;
  final String bookCode;
  final int chapter;
  final int verse;
  final String content;
  final DateTime savedAt;

  SavedVerse({
    required this.id,
    required this.userId,
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.content,
    required this.savedAt,
  });

  factory SavedVerse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedVerse(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookCode: data['bookCode'] ?? '',
      chapter: data['chapter'] ?? 1,
      verse: data['verse'] ?? 1,
      content: data['content'] ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookCode': bookCode,
      'chapter': chapter,
      'verse': verse,
      'content': content,
      'savedAt': Timestamp.fromDate(savedAt),
    };
  }

  String get reference => '$bookCode $chapter:$verse';
}

// 연속 읽기 스트릭 모델
class ReadingStreak {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadDate;
  final int fireLevel; // 1, 2, 3

  ReadingStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastReadDate,
    required this.fireLevel,
  });

  factory ReadingStreak.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReadingStreak(
      userId: doc.id,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastReadDate: (data['lastReadDate'] as Timestamp?)?.toDate(),
      fireLevel: data['fireLevel'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadDate': lastReadDate != null ? Timestamp.fromDate(lastReadDate!) : null,
      'fireLevel': fireLevel,
    };
  }

  static int calculateFireLevel(int streak) {
    if (streak >= 10) return 3;
    if (streak >= 5) return 2;
    return 1;
  }
}
