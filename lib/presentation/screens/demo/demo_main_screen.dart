import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'demo_home_screen.dart';
import 'demo_bible_screen.dart';
import 'demo_calendar_screen.dart';
import 'demo_profile_screen.dart';

class DemoMainScreen extends StatefulWidget {
  const DemoMainScreen({super.key});

  @override
  State<DemoMainScreen> createState() => _DemoMainScreenState();
}

class _DemoMainScreenState extends State<DemoMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DemoHomeScreen(),
    DemoBibleScreen(),
    DemoCalendarScreen(),
    DemoProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, '홈'),
                _buildNavItem(1, Icons.menu_book_rounded,
                    Icons.menu_book_outlined, '성경'),
                _buildNavItem(2, Icons.calendar_month_rounded,
                    Icons.calendar_month_outlined, '기록'),
                _buildNavItem(3, Icons.person_rounded,
                    Icons.person_outline_rounded, '프로필'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.primary : AppColors.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
