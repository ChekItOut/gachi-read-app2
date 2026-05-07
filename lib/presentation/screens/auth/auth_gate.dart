import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../data/services/firebase_service.dart';
import '../../providers/app_provider.dart';
import '../main_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          // 로그인 상태 - 앱 데이터 초기화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AppProvider>().initializeUser(snapshot.data!);
          });
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(36),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Image.asset(
                  'assets/images/holy_fire_sample.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '가치읽자',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2E22),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xFF3D8B5E),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
