import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/page_transitions.dart';
import '../providers/app_provider.dart';
import 'home/home_screen.dart';
import 'bible/free_bible_screen.dart';
import 'calendar/calendar_screen.dart';
import 'profile/profile_screen.dart';
import 'common/fire_level_up_screen.dart';
import 'sharing/discussion_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const FreeBibleScreen();
      case 2:
        return CalendarScreen(isActive: _currentIndex == 2);
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    // Provider 이벤트 리스닝 (빌드 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToFireEvents();
    });
  }

  void _listenToFireEvents() {
    final provider = context.read<AppProvider>();
    provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    try {
      context.read<AppProvider>().removeListener(_onProviderChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();

    // 커플 연결 이벤트 처리
    if (provider.coupleConnectionEvent == CoupleConnectionEvent.connected) {
      final partnerName = provider.newPartnerName;
      provider.consumeCoupleConnectionEvent();
      _showCoupleConnectedDialog(partnerName);
    } else if (provider.coupleConnectionEvent ==
        CoupleConnectionEvent.disconnected) {
      provider.consumeCoupleConnectionEvent();
      _showCoupleDisconnectedDialog();
    }

    // 읽기 플랜 이벤트 처리
    if (provider.readingPlanEvent == ReadingPlanEvent.created) {
      provider.consumeReadingPlanEvent();
      _showReadingPlanCreatedDialog();
    } else if (provider.readingPlanEvent == ReadingPlanEvent.updated) {
      provider.consumeReadingPlanEvent();
      _showReadingPlanUpdatedDialog();
    }

    // 파트너 소감 이벤트 처리
    if (provider.partnerReflectionEvent == PartnerReflectionEvent.submitted) {
      provider.consumePartnerReflectionEvent();
      _showPartnerReflectionDialog();
    }

    if (provider.fireLevelEvent == FireLevelEvent.levelUp) {
      provider.consumeFireLevelEvent();
      _showLevelUpScreen(
          provider.prevFireLevel, provider.myStreak?.fireLevel ?? 2);
    } else if (provider.fireLevelEvent == FireLevelEvent.streakBroken) {
      provider.consumeFireLevelEvent();
      _showStreakBrokenDialog(provider.prevFireLevel);
    }
  }

  /// 커플 연결 완료 다이얼로그 표시
  void _showCoupleConnectedDialog(String? partnerName) {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => _CoupleConnectedDialog(partnerName: partnerName),
    );
  }

  /// 커플 해제 다이얼로그 표시
  void _showCoupleDisconnectedDialog() {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierDismissible: false,
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => _CoupleDisconnectedDialog(
        onConfirm: () {
          Navigator.of(context).pop();
          setState(() => _currentIndex = 0);
        },
      ),
    );
  }

  /// 읽기 플랜 생성 다이얼로그 표시
  void _showReadingPlanCreatedDialog() {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => _ReadingPlanCreatedDialog(
        onConfirm: () {
          Navigator.of(context).pop();
          setState(() => _currentIndex = 0);
        },
      ),
    );
  }

  /// 읽기 플랜 수정 다이얼로그 표시
  void _showReadingPlanUpdatedDialog() {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => _ReadingPlanUpdatedDialog(
        onConfirm: () {
          Navigator.of(context).pop();
          setState(() => _currentIndex = 0);
        },
      ),
    );
  }

  /// 파트너 소감 완료 다이얼로그 표시
  void _showPartnerReflectionDialog() {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => _PartnerReflectionDialog(
        onViewDiscussion: () {
          Navigator.of(context).pop();
          Navigator.of(this.context).push(
            SharedAxisPageRoute(builder: (_) => const DiscussionScreen()),
          );
        },
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
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
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => _StreakBrokenDialog(prevLevel: prevLevel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _buildScreen(_currentIndex),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, '홈'),
              _buildNavItem(1, Icons.menu_book_outlined, Icons.menu_book, '성경'),
              _buildNavItem(
                  2, Icons.calendar_month_outlined, Icons.calendar_month, '기록'),
              _buildNavItem(3, Icons.person_outline, Icons.person, '프로필'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.secondaryText,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primary : AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 연속성 깨짐 작은 팝업 ────────────────────────────────────────────────────
class _StreakBrokenDialog extends StatelessWidget {
  final int prevLevel;
  const _StreakBrokenDialog({required this.prevLevel});

  // 레벨별 이미지 경로
  String _getFireImagePath(int level) {
    switch (level) {
      case 2:
        return 'assets/images/holy_fire_level2.png';
      case 3:
        return 'assets/images/holy_fire_level3.png';
      default:
        return 'assets/images/holy_fire_sample.png';
    }
  }

  String get _prevLevelEmoji {
    if (prevLevel == 3) return '🔥🔥🔥';
    if (prevLevel == 2) return '🔥🔥';
    return '🔥';
  }

  String get _message {
    if (prevLevel >= 2) {
      return 'Level $prevLevel까지 올라갔던\n성령의 불이 꺼졌어요...';
    }
    return '연속 읽기가 끊겼어요.\n다시 불을 피워볼까요?';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('💨', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  // 작은 불 이미지 (흑백 처리 효과 - 꺼진 불 표현)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0.6,
                        0,
                      ]),
                      child: Image.asset(
                        _getFireImagePath(prevLevel),
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 이전 레벨 뱃지
              if (prevLevel > 1) ...[
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
                    '$_prevLevelEmoji Level ${prevLevel} 달성 중이었는데...',
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
    );
  }
}

// ─── 커플 연결 완료 다이얼로그 ──────────────────────────────────────────────────
class _CoupleConnectedDialog extends StatelessWidget {
  final String? partnerName;
  const _CoupleConnectedDialog({this.partnerName});

  @override
  Widget build(BuildContext context) {
    final displayName = partnerName ?? '파트너';
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
              // 하트 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 메시지
              Text(
                '$displayName님과\n연결되었어요!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '이제 함께 성경을 읽고\n매일의 소감을 나눠보세요',
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
                      colors: [Color(0xFF4ECDC4), Color(0xFF44B5AD)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '함께 시작하기',
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
    );
  }
}

// ─── 커플 해제 다이얼로그 ──────────────────────────────────────────────────────
class _CoupleDisconnectedDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _CoupleDisconnectedDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F0),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('💔', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '커플 연결이\n해제되었어요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '상대방이 커플 연결을 해제했어요.\n새로운 파트너와 다시 연결할 수 있어요.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '확인',
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
    );
  }
}

// ─── 읽기 플랜 생성 다이얼로그 ────────────────────────────────────────────────────
class _ReadingPlanCreatedDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _ReadingPlanCreatedDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📖', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '파트너님이 읽기 플랜을\n설정했어요!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '오늘부터 함께 성경 읽기를\n시작해볼까요?',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44B5AD)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '오늘의 말씀 보기',
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
    );
  }
}

// ─── 파트너 소감 완료 다이얼로그 ──────────────────────────────────────────────────
class _PartnerReflectionDialog extends StatelessWidget {
  final VoidCallback onViewDiscussion;
  final VoidCallback onDismiss;
  const _PartnerReflectionDialog({
    required this.onViewDiscussion,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('💌', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '파트너님이\n소감을 남겼어요!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '함께 오늘의 말씀에 대해\n이야기를 나눠보세요',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onViewDiscussion,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '말씀나눔 보기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDismiss,
              child: const Text(
                '나중에 볼게요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 읽기 플랜 수정 다이얼로그 ────────────────────────────────────────────────────
class _ReadingPlanUpdatedDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _ReadingPlanUpdatedDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✏️', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '파트너님이 읽기 플랜을\n수정했어요!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 플랜이 적용되었어요.\n오늘의 말씀을 확인해보세요!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44B5AD)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '오늘의 말씀 보기',
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
    );
  }
}
