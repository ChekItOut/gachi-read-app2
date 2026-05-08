import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/demo_provider.dart';
import 'demo_home_screen.dart';
import 'demo_bible_screen.dart';
import 'demo_calendar_screen.dart';
import 'demo_profile_screen.dart';
import 'fire_level_up_screen.dart';

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
  void initState() {
    super.initState();
    // Provider 이벤트 리스닝 (빌드 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToFireEvents();
    });
  }

  void _listenToFireEvents() {
    final provider = context.read<DemoProvider>();
    provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    try {
      context.read<DemoProvider>().removeListener(_onProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<DemoProvider>();

    if (provider.fireLevelEvent == FireLevelEvent.levelUp) {
      provider.consumeFireLevelEvent();
      _showLevelUpScreen(provider.prevFireLevel, provider.fireLevel);
    } else if (provider.fireLevelEvent == FireLevelEvent.streakBroken) {
      provider.consumeFireLevelEvent();
      _showStreakBrokenDialog(provider.prevFireLevel);
    }
  }

  /// 레벨업 마일스톤 전체 화면 표시
  void _showLevelUpScreen(int fromLevel, int toLevel) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            FireLevelUpScreen(
          fromLevel: fromLevel,
          toLevel: toLevel,
          onContinue: () => Navigator.of(context).pop(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// 연속성 깨짐 작은 팝업
  void _showStreakBrokenDialog(int prevLevel) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(60),
      builder: (context) => _StreakBrokenDialog(prevLevel: prevLevel),
    );
  }

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
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 연속성 깨짐 작은 팝업 ────────────────────────────────────────────────────
class _StreakBrokenDialog extends StatefulWidget {
  final int prevLevel;
  const _StreakBrokenDialog({required this.prevLevel});

  @override
  State<_StreakBrokenDialog> createState() => _StreakBrokenDialogState();
}

class _StreakBrokenDialogState extends State<_StreakBrokenDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.7, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 70),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
    ]).animate(_controller);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _prevLevelEmoji {
    if (widget.prevLevel == 3) return '🔥🔥🔥';
    if (widget.prevLevel == 2) return '🔥🔥';
    return '🔥';
  }

  String get _message {
    if (widget.prevLevel >= 2) {
      return 'Level ${widget.prevLevel}까지 올라갔던\n성령의 불이 꺼졌어요...';
    }
    return '연속 읽기가 끊겼어요.\n다시 불을 피워볼까요?';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        ),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이모지 + 작은 불 이미지
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('💨', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  // 작은 불 이미지 (흑백 처리 효과)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 0.6, 0,
                      ]),
                      child: Image.asset(
                        'assets/images/holy_fire_sample.png',
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 이전 레벨 뱃지
              if (widget.prevLevel > 1) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F0),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFFCCBB),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$_prevLevelEmoji Level ${widget.prevLevel} 달성 중이었는데...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE64A19),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 메시지
              Text(
                _message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '괜찮아요, 오늘부터 다시 시작해요!\n함께라면 다시 불꽃을 피울 수 있어요 💪',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 버튼
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '다시 시작하기 🔥',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
