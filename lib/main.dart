import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'data/services/bible_service.dart';
import 'data/services/firebase_service.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 성경 데이터 사전 로드
  await BibleService.instance.loadBible();

  runApp(const GachiReadApp());
}

class GachiReadApp extends StatelessWidget {
  const GachiReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(
            firebaseService: FirebaseService.instance,
            bibleService: BibleService.instance,
          ),
        ),
      ],
      child: MaterialApp(
        title: '가치읽자',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}
