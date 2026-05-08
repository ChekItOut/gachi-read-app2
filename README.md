# 가치읽자 - 커플 성경읽기 앱

> 모든 크리스천 커플이 성경말씀 안에서 함께 성장하는 것을 목표로 한 커플 성경읽기 앱

## 앱 소개

**가치읽자**는 크리스천 커플이 매일 함께 성경을 읽고 나눌 수 있도록 돕는 Flutter 기반 모바일 앱입니다.

## 주요 기능

1. **커플 연결 & 읽기 플랜** - Google 로그인, 초대 코드로 커플 연결, 성경 읽기 플랜 설정 (장/절 단위 선택, 하루 분량 설정)
2. **말씀 나누기** - 오늘의 성경 읽기 완료 후 소감 작성 및 파트너 소감 확인 (파트너 대기 페이지 제공)
3. **AI 대화 질문** - Gemini API를 활용하여 두 사람의 소감을 분석한 맞춤형 대화 주제 생성
4. **읽기 기록 캘린더** - 월별 읽기 완료 날짜 시각화 및 날짜별 기록 확인
5. **자유 성경 읽기** - 성경 책/장 선택하여 자유롭게 읽기, 드래그로 여러 절을 묶어 저장, 저장 목록 제목 표시 및 이동
6. **성령의 불 게이미피케이션** - 연속 읽기 일수에 따른 레벨 시스템 (Level 1-3), 레벨업 마일스톤 및 연속성 깨짐 팝업 제공

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
│   ├── providers/
│   │   ├── app_provider.dart             # Firebase 연동 앱 상태 관리
│   │   └── demo_provider.dart            # 데모용 상태 관리
│   ├── screens/
│   │   ├── auth/                         # 인증 화면 (Google 로그인)
│   │   ├── bible/                        # 성경 읽기 화면
│   │   ├── calendar/                     # 캘린더 화면
│   │   ├── demo/                         # 데모용 화면들 (Firebase 없이 동작)
│   │   ├── home/                         # 홈, 커플 연결, 플랜 설정
│   │   ├── profile/                      # 프로필/설정
│   │   └── sharing/                      # 말씀 나누기, AI 질문
│   └── widgets/common_widgets.dart       # 공통 위젯
├── firebase_options.dart                 # Firebase 설정
└── main.dart                             # 앱 진입점
```

## 1. Firebase 연동 및 구조

현재 프로젝트는 Firebase Authentication(Google 로그인)과 Firestore Database를 백엔드로 사용하도록 구성되어 있습니다.

### 시작하기 (Firebase 설정)

1. [Firebase Console](https://console.firebase.google.com)에서 새 프로젝트 생성
2. Android/iOS/Web 앱 등록
3. Authentication에서 **Google 로그인** 활성화
4. Firestore Database 생성 (위치: `asia-northeast3` 권장)
5. FlutterFire CLI로 설정 파일 생성:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /couples/{coupleId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.memberIds;
    }
    match /couples/{coupleId}/{document=**} {
      allow read, write: if request.auth != null;
    }
    match /invites/{code} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 2. 페이지네이션 흐름 정보

앱의 주요 화면 전환 흐름은 다음과 같습니다.

1. **인증 게이트 (`AuthGate`)**: 로그인 상태 확인
   - 미로그인 -> **로그인 화면 (`LoginScreen`)**
   - 로그인 완료 -> **메인 화면 (`MainScreen` - 하단 탭 네비게이션)**
2. **홈 탭 (`HomeScreen`)**:
   - 커플 미연결 -> **커플 연결 화면 (`CoupleConnectScreen`)**
   - 플랜 미설정 -> **읽기 플랜 설정 시트** (장/절 단위, 하루 분량 설정)
   - 오늘의 말씀 카드 클릭 -> **오늘의 성경 읽기 화면 (`DailyReadingScreen`)**
3. **읽기 흐름**:
   - `DailyReadingScreen`에서 읽기 완료 -> **소감 작성 화면 (`ReflectionScreen`)** 자동 이동
   - 소감 작성 완료 -> 파트너 미작성 시 **대기 페이지** 표시, 파트너 작성 시 **서로의 소감 확인**
   - 소감 확인 후 -> **AI 대화 질문 화면 (`DiscussionScreen`)**
4. **기타 탭**:
   - **성경 탭 (`FreeBibleScreen`)**: 자유 읽기, 구절 드래그 다중 선택 저장, 저장 목록 제목 표시 및 이동
   - **기록 탭 (`CalendarScreen`)**: 캘린더 및 날짜별 기록
   - **프로필 탭 (`ProfileScreen`)**: 성령의 불 레벨, 계정 관리, 데모 테스트 버튼

## 3. Gemini API 호출 기능 상태

- **구현 상태**: `AiService` 클래스를 통해 REST API 방식으로 Gemini API 호출 구현 완료.
- **기능**: 두 사용자의 소감(`myReflection`, `partnerReflection`)을 프롬프트로 전달하여, 커플이 나눌 수 있는 맞춤형 대화 질문 3~4개를 생성합니다.
- **실행 방법**: 앱 실행 시 `--dart-define`으로 API 키를 주입해야 합니다.
  ```bash
  flutter run --dart-define=GEMINI_API_KEY=your_gemini_api_key
  ```

## 4. 구글 로그인 구현 상태

- **구현 상태**: `google_sign_in` 및 `firebase_auth` 패키지를 사용하여 구현 완료.
- **Web 환경 주의사항**: Flutter Web에서 실행 시 `web/index.html`에 Google Cloud Console에서 발급받은 **OAuth 2.0 Web Client ID**를 meta 태그로 추가해야 정상 동작합니다. (현재 데모 환경에 적용됨)

## 5. 백엔드 테이블 구조 (Firestore)

| 컬렉션 | 문서 ID | 주요 필드 | 설명 |
|--------|---------|----------|------|
| `users` | `uid` | email, displayName, coupleId | 사용자 기본 정보 |
| `couples` | 자동 생성 | memberIds[], inviteCode, createdAt | 커플 그룹 정보 |
| `invites` | `inviteCode` | creatorId, used, createdAt | 커플 연결 초대 코드 |
| `readingPlans` | `coupleId` | startBook, startChapter, readingUnit, dailyAmount, isActive | 커플의 읽기 플랜 설정 |
| `dailyReadings` | `coupleId_date` | coupleId, date, completedUsers[] | 날짜별 읽기 완료 상태 |
| `reflections` | `coupleId_date` | coupleId, date, reflections{userId: content} | 날짜별 소감 내용 |
| `aiDiscussions` | `coupleId_date` | coupleId, date, questions[] | 날짜별 AI 생성 질문 |
| `savedVerses` | 자동 생성 | userId, bookCode, chapter, startVerse, endVerse, content, reference | 사용자가 저장한 구절 그룹 |
| `streaks` | `coupleId` | currentStreak, longestStreak, fireLevel | 성령의 불 연속성 및 레벨 |

## 6. 커플 매칭 기능 구현 계획

현재 `CoupleConnectScreen`과 `FirebaseService`에 기본 로직이 구현되어 있습니다.
1. **초대 코드 생성**: 사용자가 '초대 코드 생성' 버튼을 누르면 랜덤 6자리 영숫자 코드가 생성되고 `invites` 컬렉션에 저장됩니다.
2. **초대 코드 입력**: 파트너가 해당 코드를 입력하면 `invites` 컬렉션을 조회하여 유효성을 확인합니다.
3. **커플 그룹 생성**: 유효한 코드일 경우 `couples` 컬렉션에 새 문서를 생성하고 두 사용자의 `uid`를 `memberIds` 배열에 추가합니다.
4. **사용자 정보 업데이트**: 두 사용자의 `users` 문서에 생성된 `coupleId`를 업데이트하여 매칭을 완료합니다.

## 7. 현재 미구현된 계획사항들

- **푸시 알림**: 매일 정해진 시간에 성경 읽기 알림을 보내는 기능 (Firebase Cloud Messaging 연동 필요)
- **성령의 불 이미지 에셋**: 현재 Level 1 이미지만 적용되어 있으며, 추후 Level 2, Level 3 전용 이미지 에셋 추가 필요
- **성경 검색 기능**: 키워드로 성경 구절을 검색하는 기능
- **다양한 성경 번역본 지원**: 현재는 내장된 `bible.json` (개역개정 등 단일 버전)만 지원하며, 추후 여러 번역본 선택 기능 추가 필요
- **읽기 플랜 템플릿**: '1년 1독', '신약 통독' 등 미리 정의된 읽기 플랜 템플릿 제공 기능
