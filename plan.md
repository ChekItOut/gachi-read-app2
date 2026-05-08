# 가치읽자 (Gachi Read) - 미구현 항목 및 향후 구현 계획

이 문서는 현재 데모(Mock) 상태로 구현된 기능들을 실제 비즈니스 로직으로 전환하기 위한 구체적인 계획을 담고 있습니다.

## 1. Google 로그인 및 Firebase 인증 연동

현재 `DemoProvider`를 통해 `_isLoggedIn = true`로 하드코딩되어 있으며, Firebase Auth가 연결되어 있지 않습니다.

### 구현 계획
- **Firebase Console 설정**:
  - Authentication > Sign-in method에서 Google 로그인 활성화
  - Android SHA-1 인증서 지문 등록
  - Web 승인된 도메인에 배포 URL 추가
- **코드 수정**:
  - `main.dart`의 진입점을 `DemoApp`에서 `AuthGate`로 원복
  - `AuthGate`에서 `FirebaseService.instance.authStateChanges` 스트림을 구독하여 로그인 상태에 따라 라우팅
  - `login_screen.dart`의 Google 로그인 버튼에 `FirebaseService.instance.signInWithGoogle()` 연결
  - `AppProvider`의 `initializeUser`를 호출하여 Firestore에서 사용자 정보 동기화

## 2. 커플 매칭 시스템 (초대 코드 기반)

현재 `demo_provider.dart`의 `connectCouple` 함수에서 `Future.delayed`를 사용해 가짜로 연결 상태를 만들고 있습니다.

### 구현 계획
- **초대 코드 생성**:
  - `couple_connect_screen.dart`에서 사용자가 '초대 코드 생성'을 누르면 `FirebaseService.instance.createCouple(userId)` 호출
  - 6자리 영숫자 난수(초대 코드)를 생성하여 `couples` 컬렉션에 문서 생성
- **초대 코드 입력 및 연결**:
  - 파트너가 초대 코드를 입력하면 `FirebaseService.instance.joinCouple(userId, inviteCode)` 호출
  - `couples` 컬렉션에서 코드를 검증하고, 양쪽 사용자의 `users` 문서에 `coupleId` 업데이트
- **실시간 상태 반영**:
  - `AppProvider`에서 `users` 컬렉션의 내 문서를 실시간 구독(Snapshot)하여 `coupleId`가 생기면 자동으로 메인 화면으로 전환

## 3. 성경 읽기 플랜 및 진도 관리

현재 `demo_provider.dart`에서 로컬 메모리(`_todayVerses`, `_currentChapter` 등)에만 읽기 상태를 저장하고 있습니다.

### 구현 계획
- **플랜 생성**:
  - `reading_plan_screen.dart`에서 플랜 설정 시 `FirebaseService.instance.createReadingPlan()` 호출
  - `readingPlans` 컬렉션에 `coupleId`, 시작일, 목표, 분량 등을 저장
- **일일 읽기 완료 처리**:
  - `demo_reading_screen.dart`의 완료 버튼을 누르면 `FirebaseService.instance.saveDailyReading()` 호출
  - `dailyReadings` 컬렉션에 오늘 날짜, `userId`, `coupleId`, 읽은 범위 저장
- **파트너 상태 동기화**:
  - `AppProvider`에서 오늘 날짜의 `dailyReadings` 문서를 실시간 구독하여 파트너의 읽기 완료 여부를 UI에 즉시 반영

## 4. 소감 나누기 및 AI 질문 생성

현재 소감은 로컬 변수에 저장되며, 파트너 소감은 2초 후 하드코딩된 텍스트로 나타납니다. AI 질문도 하드코딩된 배열을 반환합니다.

### 구현 계획
- **소감 저장 및 공유**:
  - `reflection_screen.dart`에서 소감 작성 시 `FirebaseService.instance.saveReflection()` 호출
  - `reflections` 컬렉션에 저장하고, 파트너의 소감 문서도 실시간 구독하여 둘 다 작성 완료 시 화면에 표시
- **Gemini AI 연동**:
  - `ai_service.dart`에 실제 Gemini API 키 적용 (현재 환경변수 `GEMINI_API_KEY`로 설정되도록 준비됨)
  - 두 사람의 소감이 모두 작성된 시점에 Cloud Functions 또는 클라이언트에서 `AiService.instance.generateDiscussionQuestions()` 호출
  - 생성된 질문을 `aiDiscussions` 컬렉션에 저장하여 양쪽 화면에 동일한 질문 표시

## 5. 스트릭(연속 읽기) 및 성령의 불 레벨 시스템

현재 `_currentStreak` 변수를 수동으로 올리며, 레벨업 이벤트도 로컬에서만 발생합니다.

### 구현 계획
- **스트릭 계산 로직**:
  - 일일 읽기 완료 시 `FirebaseService.instance.updateStreak()` 호출
  - `streaks` 컬렉션에서 마지막 읽은 날짜(`lastReadDate`)를 확인하여 어제 읽었으면 `currentStreak + 1`, 아니면 `1`로 초기화
- **레벨업 이벤트 처리**:
  - 스트릭이 5, 10 등 특정 구간에 도달하면 `fireLevel`을 업데이트
  - 레벨업 발생 시 Firestore에 이벤트 플래그를 남겨, 앱 접속 시 `fire_level_up_screen.dart` 팝업을 띄우고 플래그 해제

## 6. 캘린더 및 통계 데이터 연동

현재 `_completedDates` Set에 가짜 날짜를 넣어 캘린더에 표시하고 있습니다.

### 구현 계획
- **월별 데이터 조회**:
  - `calendar_screen.dart`에서 달이 바뀔 때마다 `FirebaseService.instance.getCalendarData()` 호출
  - 해당 월의 `dailyReadings`와 `reflections` 데이터를 가져와 달력에 스탬프(읽기 완료, 소감 완료 등) 표시
- **통계 업데이트**:
  - 프로필 화면 진입 시 `getUserStats()`를 호출하여 총 읽은 날 수, 작성한 소감 수 등을 집계하여 표시

## 7. 푸시 알림 (선택/추가 구현)

현재 알림 기능은 완전히 누락되어 있습니다.

### 구현 계획
- **FCM (Firebase Cloud Messaging) 연동**:
  - `firebase_messaging` 패키지 추가
  - 파트너가 성경 읽기를 완료하거나 소감을 남겼을 때 Cloud Functions를 통해 푸시 알림 전송
  - 앱 내 알림 설정(On/Off) 기능 추가
