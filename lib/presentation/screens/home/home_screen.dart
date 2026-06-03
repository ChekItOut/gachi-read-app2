import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/services/bible_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../bible/daily_reading_screen.dart';
import '../sharing/reflection_screen.dart';
import '../sharing/discussion_screen.dart';
import 'couple_connect_screen.dart';
import 'reading_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _wobbleController;
  late Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    // 둥실 떠오르는 애니메이션
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    // 좌우 흔들림 애니메이션
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _wobbleAnimation = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshAll();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => provider.refreshAll(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(provider),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 성령의 불 히어로 섹션
                  _buildFireHeroSection(provider),
                  const SizedBox(height: 20),

                  // 커플 연결 상태에 따라 분기
                  if (!provider.hasCoupleConnected) ...[
                    _buildCoupleConnectCard(),
                    const SizedBox(height: 16),
                    _buildDailyVerseCard(),
                    const SizedBox(height: 16),
                    _buildFeaturePreviewSection(),
                    const SizedBox(height: 16),
                    _buildMyJourneyCard(provider),
                  ] else ...[
                    if (!provider.hasReadingPlan) ...[
                      _buildNoPlanCard(),
                    ] else ...[
                      // 오늘의 진행 상태 카드
                      _buildProgressStatusCard(provider),
                      const SizedBox(height: 16),
                      // 오늘의 말씀 카드
                      _buildTodayCard(provider),
                    ],
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 앱바 ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(AppProvider provider) {
    final now = DateTime.now();
    final dateStr = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(dateStr, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                provider.appUser?.displayName != null
                    ? '안녕하세요, ${provider.appUser!.displayName}님 👋'
                    : '가치읽자',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 성령의 불 히어로 섹션 ─────────────────────────────────────────────────
  Widget _buildFireHeroSection(AppProvider provider) {
    final streak = provider.myStreak;
    final fireLevel = streak?.fireLevel ?? 1;
    final currentStreak = streak?.currentStreak ?? 0;

    return GestureDetector(
      onTap: () => _showStreakSheet(provider),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withAlpha(18),
              AppColors.background,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation:
                  Listenable.merge([_floatController, _wobbleController]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: Transform.rotate(
                    angle: _wobbleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // 그림자
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, _) {
                      final shadowScale =
                          1.0 - (_floatAnimation.value.abs() / 14) * 0.4;
                      return Transform.translate(
                        offset:
                            Offset(0, 140 + _floatAnimation.value.abs() * 0.8),
                        child: Container(
                          width: 80 * shadowScale,
                          height: 10 * shadowScale,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    },
                  ),
                  // 불 이미지
                  Image.asset(
                    _getFireImagePath(fireLevel),
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  // 레벨 뱃지
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Lv.$fireLevel',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '성령의 불 Level $fireLevel',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$currentStreak일 연속',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 오늘의 진행 상태 카드 ─────────────────────────────────────────────────
  Widget _buildProgressStatusCard(AppProvider provider) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      closedElevation: 0,
      openElevation: 0,
      closedColor: AppColors.surface,
      openColor: AppColors.background,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      closedBuilder: (context, openContainer) {
        return _buildProgressStatusCardContent(provider);
      },
      openBuilder: (context, _) => const ReflectionViewScreen(),
    );
  }

  Widget _buildProgressStatusCardContent(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('우리의 오늘',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTodayStatusColor(provider).withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _getTodayStatusLabel(provider),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getTodayStatusColor(provider)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildPersonStatusCard(
                name: provider.appUser?.displayName ?? '나',
                isReadingDone: provider.isTodayReadingComplete,
                isReflectionDone: provider.isTodayReflectionDone,
                isMe: true,
              )),
              const SizedBox(width: 10),
              // 하트 구분자
              Column(
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildPersonStatusCard(
                name: provider.partner?.displayName ?? '파트너',
                isReadingDone: provider.isPartnerReadingComplete,
                isReflectionDone: provider.isPartnerReflectionDone,
                isMe: false,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTodayStatusColor(AppProvider provider) {
    if (provider.isTodayReflectionDone && provider.isPartnerReflectionDone) {
      return const Color(0xFF22C55E);
    } else if (provider.isTodayReadingComplete) {
      return AppColors.primary;
    } else {
      return AppColors.secondaryText;
    }
  }

  String _getTodayStatusLabel(AppProvider provider) {
    if (provider.isTodayReflectionDone && provider.isPartnerReflectionDone) {
      return '나눔 완료 ✓';
    } else if (provider.isTodayReflectionDone) {
      return '파트너 대기 중';
    } else if (provider.isTodayReadingComplete) {
      return '읽기 완료';
    } else {
      return '읽기 전';
    }
  }

  Widget _buildPersonStatusCard({
    required String name,
    required bool isReadingDone,
    required bool isReflectionDone,
    required bool isMe,
  }) {
    final baseColor = isMe ? AppColors.primary : const Color(0xFF4A90D9);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: baseColor.withAlpha(40),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름 + 나/파트너 뱃지
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: baseColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMe)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: baseColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('나',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: baseColor)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 읽기 상태 pill
          _buildStatusPill(
            icon: isReadingDone
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            label: '읽기',
            isDone: isReadingDone,
            color: baseColor,
          ),
          const SizedBox(height: 6),
          // 나눔 상태 pill
          _buildStatusPill(
            icon: isReflectionDone
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            label: '나눔',
            isDone: isReflectionDone,
            color: baseColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required bool isDone,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDone ? color.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDone ? color : AppColors.secondaryText,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isDone ? FontWeight.w700 : FontWeight.w400,
              color: isDone ? color : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 오늘의 말씀 카드 ──────────────────────────────────────────────────────
  Widget _buildTodayCard(AppProvider provider) {
    final todayReading = provider.todayReading;

    if (todayReading == null) {
      return OpenContainer(
        transitionDuration: const Duration(milliseconds: 400),
        closedElevation: 0,
        openElevation: 0,
        closedColor: AppColors.surface,
        openColor: AppColors.background,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        closedBuilder: (context, openContainer) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconBox(icon: Icons.menu_book_rounded, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('오늘의 말씀',
                              style: Theme.of(context).textTheme.labelLarge),
                          Text('읽기 플랜을 설정해주세요',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.secondaryText)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: '읽기 플랜 설정',
                  onPressed: openContainer,
                ),
              ],
            ),
          );
        },
        openBuilder: (context, _) => const ReadingPlanScreen(),
      );
    }

    final rangeText = BibleService.instance.formatReadingRange(todayReading);

    // 첫 구절 미리보기 로드
    final verses = BibleService.instance.getReadingVerses(todayReading);
    final firstVerse = verses.isNotEmpty ? verses.first.content : null;

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      closedElevation: 0,
      openElevation: 0,
      closedColor: AppColors.surface,
      openColor: AppColors.background,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      closedBuilder: (context, openContainer) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBox(icon: Icons.menu_book_rounded, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('오늘의 말씀',
                            style: Theme.of(context).textTheme.labelLarge),
                        Text(
                          rangeText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 구절 미리보기
              if (firstVerse != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"$firstVerse"',
                    style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.primaryText,
                        fontStyle: FontStyle.italic),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildActionButton(provider),
            ],
          ),
        );
      },
      openBuilder: (context, _) => const DailyReadingScreen(),
    );
  }

  Widget _buildActionButton(AppProvider provider) {
    // 아직 읽지 않음
    if (!provider.isTodayReadingComplete) {
      return PrimaryButton(
        text: '말씀 읽기',
        onPressed: () => Navigator.push(
          context,
          SharedAxisPageRoute(builder: (_) => const DailyReadingScreen()),
        ),
        icon: Icons.menu_book_outlined,
      );
    }

    // 읽었지만 내 소감 미작성
    if (!provider.isTodayReflectionDone) {
      return PrimaryButton(
        text: '말씀 나누기',
        onPressed: () => Navigator.push(
          context,
          SharedAxisPageRoute(builder: (_) => const ReflectionScreen()),
        ),
        icon: Icons.chat_bubble_outline,
      );
    }

    // 내 소감 작성 완료, 파트너 대기 중
    if (!provider.isPartnerReflectionDone) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4A90D9).withAlpha(20),
              AppColors.primary.withAlpha(20),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withAlpha(40),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내 소감을 보냈어요 💌',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  '${provider.partner?.displayName ?? "파트너"}의 나눔을 기다리는 중...',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ]),
      );
    }

    // 둘 다 완료 → AI 질문
    return PrimaryButton(
      text: 'AI 대화 질문 보기',
      onPressed: () => Navigator.push(
        context,
        SharedAxisPageRoute(builder: (_) => const DiscussionScreen()),
      ),
      icon: Icons.auto_awesome,
    );
  }

  // ─── 커플 연결 카드 ────────────────────────────────────────────────────────
  Widget _buildCoupleConnectCard() {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 400),
      closedElevation: 0,
      openElevation: 0,
      closedColor: AppColors.surface,
      openColor: AppColors.background,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      closedBuilder: (context, openContainer) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const IconBox(icon: Icons.favorite_outline, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('파트너와 연결하기',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('커플 연결 후 함께 성경을 읽어요',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.secondaryText)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              PrimaryButton(
                text: '커플 연결하기',
                onPressed: openContainer,
              ),
            ],
          ),
        );
      },
      openBuilder: (context, _) => const CoupleConnectScreen(),
    );
  }

  // ─── 오늘의 말씀 카드 (커플 미연결) ──────────────────────────────────────────
  static const _dailyVerses = [
    {'text': '두 사람이 한 사람보다 나음은 그들이 수고함으로 좋은 상을 얻을 것임이라', 'ref': '전도서 4:9'},
    {'text': '철이 철을 날카롭게 하는 것 같이 사람이 그의 친구의 얼굴을 빛나게 하느니라', 'ref': '잠언 27:17'},
    {'text': '너희가 내 이름으로 무엇이든지 내게 구하면 내가 시행하리라', 'ref': '요한복음 14:14'},
    {'text': '항상 기뻐하라 쉬지 말고 기도하라 범사에 감사하라', 'ref': '데살로니가전서 5:16-18'},
    {'text': '여호와는 나의 목자시니 내게 부족함이 없으리로다', 'ref': '시편 23:1'},
    {
      'text':
          '내가 진실로 진실로 너희에게 이르노니 한 알의 밀이 땅에 떨어져 죽지 아니하면 한 알 그대로 있고 죽으면 많은 열매를 맺느니라',
      'ref': '요한복음 12:24'
    },
    {'text': '너는 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라', 'ref': '잠언 3:5'},
  ];

  Widget _buildDailyVerseCard() {
    final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays %
        _dailyVerses.length;
    final verse = _dailyVerses[dayIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.softMint,
            AppColors.softMint.withAlpha(120),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      '오늘의 말씀',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"${verse['text']}"',
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '- ${verse['ref']}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 기능 미리보기 섹션 (커플 미연결) ──────────────────────────────────────
  Widget _buildFeaturePreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            '함께하면 이런 것들을 할 수 있어요',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
        ),
        _buildFeatureItem(
          icon: Icons.menu_book_rounded,
          color: AppColors.primary,
          title: '매일 함께 말씀 읽기',
          subtitle: '같은 성경 구절을 읽고 서로의 진행 상황을 확인해요',
        ),
        const SizedBox(height: 10),
        _buildFeatureItem(
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF4A90D9),
          title: '소감 나누기',
          subtitle: '읽은 말씀에 대한 느낌을 서로 공유해요',
        ),
        const SizedBox(height: 10),
        _buildFeatureItem(
          icon: Icons.auto_awesome_rounded,
          color: AppColors.purple,
          title: 'AI 대화 질문',
          subtitle: 'AI가 두 사람의 소감을 바탕으로 대화 주제를 만들어줘요',
        ),
        const SizedBox(height: 10),
        _buildFeatureItem(
          icon: Icons.local_fire_department_rounded,
          color: AppColors.warning,
          title: '성령의 불 키우기',
          subtitle: '매일 읽기를 이어가면 불꽃이 점점 커져요',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 나의 여정 카드 (커플 미연결) ──────────────────────────────────────────
  Widget _buildMyJourneyCard(AppProvider provider) {
    final streak = provider.myStreak;
    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;
    final totalDays = provider.totalReadingDays;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '나의 여정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              SizedBox(width: 6),
              Text('📖', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildJourneyStat(
                      '연속 읽기', '$currentStreak일', AppColors.primary)),
              Container(width: 1, height: 44, color: AppColors.divider),
              Expanded(
                  child: _buildJourneyStat(
                      '최장 기록', '$longestStreak일', AppColors.warning)),
              Container(width: 1, height: 44, color: AppColors.divider),
              Expanded(
                  child: _buildJourneyStat(
                      '총 읽은 날', '$totalDays일', const Color(0xFF4A90D9))),
            ],
          ),
          if (currentStreak == 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '파트너와 연결하고 함께 말씀을 읽어보세요!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJourneyStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // ─── 플랜 설정 카드 ────────────────────────────────────────────────────────
  Widget _buildNoPlanCard() {
    return AppCard(
      backgroundColor: AppColors.softBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const IconBox(
                icon: Icons.calendar_today_outlined,
                size: 48,
                color: Color(0xFF4A90D9),
                backgroundColor: Color(0xFFD0E8FA)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('읽기 플랜 설정',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text('어디서부터 읽을지 설정해요',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.secondaryText)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          PrimaryButton(
            text: '플랜 설정하기',
            onPressed: () => Navigator.push(
              context,
              SharedAxisPageRoute(builder: (_) => const ReadingPlanScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 스트릭 상세 바텀시트 ──────────────────────────────────────────────────
  void _showStreakSheet(AppProvider provider) {
    final streak = provider.myStreak;
    final fireLevel = streak?.fireLevel ?? 1;
    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Image.asset(_getFireImagePath(fireLevel), width: 80, height: 80),
            const SizedBox(height: 16),
            Text('성령의 불 Level $fireLevel',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('현재 $currentStreak일 연속 읽기 중',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _statItem('현재 연속', '$currentStreak일')),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(child: _statItem('최장 연속', '$longestStreak일')),
            ]),
            const SizedBox(height: 16),
            Text(
              currentStreak < 5
                  ? '${5 - currentStreak}일 더 읽으면 Level 2로 진화해요!'
                  : currentStreak < 10
                      ? '${10 - currentStreak}일 더 읽으면 Level 3으로 진화해요!'
                      : '최고 레벨 달성! 정말 대단해요! 🎉',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── 레벨별 이미지 경로 ────────────────────────────────────────────────────
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

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText)),
      Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText)),
    ]);
  }
}
