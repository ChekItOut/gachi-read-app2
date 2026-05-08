import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 성령의 불 레벨업 마일스톤 전체 화면
/// [fromLevel] → [toLevel] 레벨업 시 표시
class FireLevelUpScreen extends StatefulWidget {
  final int fromLevel;
  final int toLevel;
  final VoidCallback? onContinue;

  const FireLevelUpScreen({
    super.key,
    required this.fromLevel,
    required this.toLevel,
    this.onContinue,
  });

  @override
  State<FireLevelUpScreen> createState() => _FireLevelUpScreenState();
}

class _FireLevelUpScreenState extends State<FireLevelUpScreen>
    with TickerProviderStateMixin {
  // 메인 스케일 애니메이션
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // 둥실 애니메이션
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // 파티클 애니메이션
  late AnimationController _particleController;

  // 텍스트 페이드인
  late AnimationController _textController;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  // 버튼 페이드인
  late AnimationController _btnController;
  late Animation<double> _btnFadeAnimation;

  // 배경 그라디언트 애니메이션
  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 파티클 생성
    for (int i = 0; i < 24; i++) {
      _particles.add(_Particle(random: _random));
    }

    // 배경
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOut,
    );

    // 이미지 스케일
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.2, end: 0.95)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
    ]).animate(_scaleController);

    // 둥실
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -16).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 파티클
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 텍스트
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // 버튼
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _btnFadeAnimation = CurvedAnimation(
      parent: _btnController,
      curve: Curves.easeOut,
    );

    // 순서대로 실행
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
      _particleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      _btnController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _floatController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _btnController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  // 레벨별 색상 테마
  List<Color> get _gradientColors {
    if (widget.toLevel == 2) {
      return [
        const Color(0xFFFF6B35),
        const Color(0xFFFF8C42),
        const Color(0xFFFFB347),
      ];
    } else {
      return [
        const Color(0xFFFF3D00),
        const Color(0xFFFF6D00),
        const Color(0xFFFFAB00),
      ];
    }
  }

  String get _levelTitle {
    if (widget.toLevel == 2) return '성령의 불이\n더 밝게 타오릅니다!';
    return '성령의 불이\n활활 타오릅니다!';
  }

  String get _levelSubtitle {
    if (widget.toLevel == 2) {
      return '5일 연속 말씀 읽기 달성!\n함께 성장하는 여러분이 자랑스러워요 🔥';
    }
    return '10일 연속 말씀 읽기 달성!\n두 사람의 믿음이 하늘에 닿았어요 ✨';
  }

  String get _levelBadge => 'Level ${widget.toLevel}';

  String get _streakText {
    if (widget.toLevel == 2) return '5일 연속 달성';
    return '10일 연속 달성';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _gradientColors[0].withAlpha(
                      (255 * _bgAnimation.value).toInt()),
                  _gradientColors[1].withAlpha(
                      (200 * _bgAnimation.value).toInt()),
                  _gradientColors[2].withAlpha(
                      (120 * _bgAnimation.value).toInt()),
                  Colors.white.withAlpha(
                      (255 * _bgAnimation.value).toInt()),
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // 파티클 레이어
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                    colors: _gradientColors,
                  ),
                );
              },
            ),

            // 메인 콘텐츠
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // 레벨 뱃지
                  AnimatedBuilder(
                    animation: _textFadeAnimation,
                    builder: (context, child) => FadeTransition(
                      opacity: _textFadeAnimation,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withAlpha(100),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            _streakText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 성령의 불 이미지 (애니메이션)
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_scaleAnimation, _floatAnimation]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 글로우 효과
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withAlpha(80),
                                Colors.white.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                        // 이미지
                        Image.asset(
                          'assets/images/holy_fire_sample.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                        // 레벨 뱃지
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: _gradientColors[0].withAlpha(80),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _levelBadge,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _gradientColors[0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 텍스트 영역
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) => FadeTransition(
                        opacity: _textFadeAnimation,
                        child: SlideTransition(
                          position: _textSlideAnimation,
                          child: child,
                        ),
                      ),
                      child: Column(
                        children: [
                          // LEVEL UP 라벨
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'LEVEL UP! ${widget.fromLevel} → ${widget.toLevel}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _levelTitle,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _levelSubtitle,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.white.withAlpha(220),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 계속하기 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: AnimatedBuilder(
                      animation: _btnFadeAnimation,
                      builder: (context, child) => FadeTransition(
                        opacity: _btnFadeAnimation,
                        child: child,
                      ),
                      child: Column(
                        children: [
                          // 메인 버튼
                          GestureDetector(
                            onTap: () {
                              if (widget.onContinue != null) {
                                widget.onContinue!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withAlpha(30),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                '계속 함께 읽기 🔥',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: _gradientColors[0],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // 공유 힌트
                          Text(
                            '파트너와 함께 이 순간을 나눠보세요',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 파티클 모델 ─────────────────────────────────────────────────────────────
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double angle;
  final double opacity;

  _Particle({required Random random})
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = random.nextDouble() * 8 + 4,
        speed = random.nextDouble() * 0.6 + 0.4,
        angle = random.nextDouble() * 2 * pi,
        opacity = random.nextDouble() * 0.6 + 0.3;
}

// ─── 파티클 페인터 ───────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final List<Color> colors;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = p.x * size.width +
          cos(p.angle) * progress * size.width * 0.3 * p.speed;
      final dy = p.y * size.height -
          progress * size.height * 0.5 * p.speed;
      final opacity = p.opacity * (1 - progress * 0.7);
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = Colors.white.withAlpha((opacity * 255).toInt())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size * (1 - progress * 0.3),
          paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
