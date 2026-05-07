# 가치읽자 - 커플 성경읽기 앱

> 모든 크리스천 커플이 성경말씀 안에서 함께 성장하는 것을 목표로 한 커플 성경읽기 앱

## 앱 소개

**가치읽자**는 크리스천 커플이 매일 함께 성경을 읽고 나눌 수 있도록 돕는 Flutter 기반 모바일 앱입니다.

## 주요 기능

1. **커플 연결 & 읽기 플랜** - Google 로그인, 초대 코드로 커플 연결, 성경 읽기 플랜 설정
2. **말씀 나누기** - 오늘의 성경 읽기 완료 후 소감 작성 및 파트너 소감 확인
3. **AI 대화 질문** - Gemini AI를 활용한 맞춤형 대화 주제 생성
4. **읽기 기록 캘린더** - 월별 읽기 완료 날짜 시각화 및 날짜별 기록 확인
5. **자유 성경 읽기** - 성경 책/장 선택하여 자유롭게 읽기, 구절 저장
6. **성령의 불 게이미피케이션** - 연속 읽기 일수에 따른 레벨 시스템 (Level 1-3)

## 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.x / Dart |
| 백엔드 | Firebase (Firestore, Authentication) |
| 인증 | Google Sign-In |
| AI | Google Gemini API |
| 상태관리 | Provider |
| 폰트 | Google Fonts (Noto Sans KR) |
| 성경 데이터 | bible.json (내장) |

## 프로젝트 구조

```
lib/
├── core/
│   ├── constants/bible_constants.dart    # 성경 책 목록 상수
│   └── theme/app_theme.dart              # 앱 테마 및 디자인 시스템
├── data/
│   ├── models/app_models.dart            # 데이터 모델
│   └── services/
│       ├── ai_service.dart               # Gemini AI 서비스
│       ├── bible_service.dart            # 성경 데이터 서비스
│       └── firebase_service.dart         # Firebase CRUD 서비스
├── presentation/
│   ├── providers/app_provider.dart       # 앱 상태 관리
│   ├── screens/
│   │   ├── auth/                         # 인증 화면
│   │   ├── bible/                        # 성경 읽기 화면
│   │   ├── calendar/                     # 캘린더 화면
│   │   ├── home/                         # 홈, 커플 연결, 플랜 설정
│   │   ├── profile/                      # 프로필/설정
│   │   └── sharing/                      # 말씀 나누기, AI 질문
│   └── widgets/common_widgets.dart       # 공통 위젯
├── firebase_options.dart                 # Firebase 설정
└── main.dart                             # 앱 진입점

assets/
├── data/bible.json                       # 성경 데이터 (한국어)
└── images/holy_fire_sample.png           # 성령의 불 이미지 (Level 1)
```

## 시작하기

### 1. Firebase 설정

1. [Firebase Console](https://console.firebase.google.com)에서 새 프로젝트 생성
2. Android/iOS 앱 등록
3. Authentication에서 Google 로그인 활성화
4. Firestore Database 생성
5. FlutterFire CLI로 설정 파일 생성:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 2. Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. 앱 실행

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key
```

## Firestore 데이터 구조

| 컬렉션 | 주요 필드 |
|--------|----------|
| `users` | uid, email, displayName, coupleId |
| `couples` | user1Id, user2Id, inviteCode |
| `invites` | creatorId, used |
| `readingPlans` | coupleId, startBook, dailyChapters, isActive |
| `dailyReadings` | coupleId, userId, date, isCompleted |
| `reflections` | coupleId, userId, date, content |
| `aiDiscussions` | coupleId, date, questions[] |
| `savedVerses` | userId, bookCode, chapter, verse, content |
| `streaks` | currentStreak, longestStreak, fireLevel |

## 디자인 시스템

| 색상 | 값 | 용도 |
|------|-----|------|
| Primary | `#58BE82` | 주요 액션, 강조 |
| Background | `#F2F5FA` | 배경 |
| Surface | `#FFFFFF` | 카드 배경 |
| Soft Mint | `#E6F4F0` | 내 상태 표시 |
| Soft Blue | `#EAF2FA` | 파트너 상태 표시 |
| Warning | `#F05A4A` | 경고, 삭제 |

## 추후 개발 예정

- Level 2, Level 3 성령의 불 이미지 추가
- 푸시 알림 (매일 읽기 알림)
- 성경 검색 기능
- 다양한 성경 번역본 지원
- 읽기 플랜 템플릿 제공
