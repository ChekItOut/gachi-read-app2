import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'data/services/bible_service.dart';
import 'presentation/providers/demo_provider.dart';
import 'presentation/screens/demo/demo_app.dart';

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

  // 성경 데이터 사전 로드
  await BibleService.instance.loadBible();

  runApp(const GachiReadDemoApp());
}

class GachiReadDemoApp extends StatelessWidget {
  const GachiReadDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoProvider()),
      ],
      child: MaterialApp(
        title: '가치읽자',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DemoApp(),
      ),
    );
  }
}
