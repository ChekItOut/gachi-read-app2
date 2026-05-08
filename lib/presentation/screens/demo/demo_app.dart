import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/demo_provider.dart';
import 'demo_login_screen.dart';
import 'demo_main_screen.dart';

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();

    if (!provider.isLoggedIn) {
      return const DemoLoginScreen();
    }
    return const DemoMainScreen();
  }
}
