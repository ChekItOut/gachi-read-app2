import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';
import 'demo_reading_screen.dart';
import 'demo_reflection_screen.dart';
import 'demo_discussion_screen.dart';

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen>
    with TickerProviderStateMixin {
  // 둥실둥실 애니메이션 컨트롤러
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // 살짝 회전 애니메이션 컨트롤러
  late AnimationController _wobbleController;
  late Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();

    // 둥실둥실 (위아래 움직임) - 2.4초 주기
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 살짝 흔들림 (좌우 기울기) - 3.2초 주기, 딜레이
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _wobbleAnimation = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemoProvider>().loadTodayVerses();
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
    final provider = context.watch<DemoProvider>();
    final now = DateTime.now();
    final dateStr = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 상단 앱바 (날짜 + 인사말)
          SliverAppBar(
            expandedHeight: 80,
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
                    Text(dateStr,
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      '안녕하세요, ${provider.myName}님 👋',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ─── 성령의 불 중앙 히어로 섹션 ───
                _buildFireHeroSection(provider),
                const SizedBox(height: 20),

                // 커플 미연결
                if (!provider.hasCoupleConnected) ...[
                  _buildCoupleConnectCard(provider),
                ] else ...[
                  // 플랜 없음
                  if (!provider.hasReadingPlan) ...[
                    _buildSetPlanCard(provider),
                  ] else ...[
                    // 오늘의 말씀 카드
                    _buildTodayCard(provider),
                    const SizedBox(height: 16),
                    // 커플 상태
                    _buildCoupleStatusCard(provider),
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 성령의 불 히어로 섹션 ───────────────────────────────────────────────
  Widget _buildFireHeroSection(DemoProvider provider) {
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
            // 애니메이션 성령의 불 이미지
            AnimatedBuilder(
              animation: Listenable.merge([_floatController, _wobbleController]),
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
                  // 그림자 (바닥 그림자 - 둥실 효과 강조)
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, _) {
                      // 위로 올라갈수록 그림자가 작아짐
                      final shadowScale = 1.0 -
                          (_floatAnimation.value.abs() / 14) * 0.4;
                      return Transform.translate(
                        offset: Offset(0, 140 + _floatAnimation.value.abs() * 0.8),
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
                  // 성령의 불 이미지
                  Image.asset(
                    'assets/images/holy_fire_sample.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  // 레벨 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
                      'Lv.${provider.fireLevel}',
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

            // 레벨 텍스트
            Text(
              '성령의 불 Level ${provider.fireLevel}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),

            // 스트릭 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥',
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        '${provider.currentStreak}일 연속 말씀 읽기',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 다음 레벨까지 안내
            Text(
              provider.currentStreak < 5
                  ? '${5 - provider.currentStreak}일 더 읽으면 Level 2로 진화해요!'
                  : provider.currentStreak < 10
                      ? '${10 - provider.currentStreak}일 더 읽으면 Level 3으로 진화해요!'
                      : '최고 레벨 달성! 정말 대단해요! 🎉',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),

            const SizedBox(height: 4),

            // 탭 안내
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 12, color: AppColors.secondaryText.withAlpha(120)),
                const SizedBox(width: 4),
                Text(
                  '탭하여 자세히 보기',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText.withAlpha(120),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakSheet(DemoProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Image.asset('assets/images/holy_fire_sample.png',
                width: 80, height: 80),
            const SizedBox(height: 16),
            Text('성령의 불 Level ${provider.fireLevel}',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('현재 ${provider.currentStreak}일 연속 읽기 중',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: _statItem('현재 연속', '${provider.currentStreak}일')),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                  child: _statItem('최장 연속', '${provider.longestStreak}일')),
            ]),
            const SizedBox(height: 16),
            Text(
              provider.currentStreak < 5
                  ? '${5 - provider.currentStreak}일 더 읽으면 Level 2로 진화해요!'
                  : provider.currentStreak < 10
                      ? '${10 - provider.currentStreak}일 더 읽으면 Level 3으로 진화해요!'
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

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText)),
      Text(label,
          style: const TextStyle(
              fontSize: 13, color: AppColors.secondaryText)),
    ]);
  }

  Widget _buildCoupleConnectCard(DemoProvider provider) {
    final partnerController = TextEditingController();
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
          TextField(
            controller: partnerController,
            decoration: InputDecoration(
              hintText: '파트너 이름 입력 (예: 소망이)',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: '커플 연결하기',
            isLoading: provider.isLoading,
            onPressed: () async {
              await context
                  .read<DemoProvider>()
                  .connectCouple(partnerController.text.trim());
            },
            icon: Icons.link,
          ),
        ],
      ),
    );
  }

  Widget _buildSetPlanCard(DemoProvider provider) {
    return AppCard(
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
            isLoading: provider.isLoading,
            onPressed: () => _showPlanSetupSheet(provider),
            icon: Icons.settings_outlined,
          ),
        ],
      ),
    );
  }

  void _showPlanSetupSheet(DemoProvider provider) {
    final books = BibleConstants.bookOrder;
    String selectedBook = '창';
    int selectedChapter = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('읽기 플랜 설정',
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 20),
              Text('성경 책 선택',
                  style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBook,
                    isExpanded: true,
                    items: books
                        .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(BibleConstants.getBookName(b)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          selectedBook = v;
                          selectedChapter = 1;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('시작 장', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(children: [
                IconButton(
                  onPressed: selectedChapter > 1
                      ? () => setModalState(() => selectedChapter--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                ),
                Text('$selectedChapter장',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () =>
                      setModalState(() => selectedChapter++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                ),
              ]),
              const SizedBox(height: 24),
              PrimaryButton(
                text: '플랜 시작하기',
                isLoading: provider.isLoading,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<DemoProvider>().setReadingPlan(
                        book: selectedBook,
                        chapter: selectedChapter,
                        startVerse: 1,
                        dailyChapters: 1,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(DemoProvider provider) {
    final bookName = BibleConstants.getBookName(provider.currentBook);
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
                      '$bookName ${provider.currentChapter}장 ${provider.startVerse}-${provider.endVerse}절',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              if (provider.isTodayReadingComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('완료 ✓',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
            ],
          ),
          if (provider.todayVerses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${provider.todayVerses.first['content']}"',
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
          if (!provider.isTodayReadingComplete)
            PrimaryButton(
              text: '말씀 읽기',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DemoReadingScreen()),
              ),
              icon: Icons.menu_book_outlined,
            )
          else
            _buildPostReadingActions(provider),
        ],
      ),
    );
  }

  Widget _buildPostReadingActions(DemoProvider provider) {
    if (!provider.isMyReflectionDone) {
      return PrimaryButton(
        text: '말씀 나누기',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DemoReflectionScreen()),
        ),
        icon: Icons.chat_bubble_outline,
      );
    }
    if (!provider.isPartnerReflectionDone) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.hourglass_empty,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${provider.partnerName}의 나눔을 기다리는 중...',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.primaryText),
            ),
          ),
        ]),
      );
    }
    return PrimaryButton(
      text: 'AI 대화 질문 보기',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const DemoDiscussionScreen()),
      ),
      icon: Icons.auto_awesome,
    );
  }

  Widget _buildCoupleStatusCard(DemoProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '우리의 오늘'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _personStatus(
                name: provider.myName,
                isReadingDone: provider.isTodayReadingComplete,
                isReflectionDone: provider.isMyReflectionDone,
                isMe: true,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.favorite, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: _personStatus(
                name: provider.partnerName,
                isReadingDone: provider.isTodayReadingComplete,
                isReflectionDone: provider.isPartnerReflectionDone,
                isMe: false,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _personStatus({
    required String name,
    required bool isReadingDone,
    required bool isReflectionDone,
    required bool isMe,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? AppColors.softMint : AppColors.softBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Text(name,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        _statusRow(Icons.menu_book_outlined, '읽기', isReadingDone),
        const SizedBox(height: 6),
        _statusRow(Icons.chat_bubble_outline, '나눔', isReflectionDone),
      ]),
    );
  }

  Widget _statusRow(IconData icon, String label, bool isDone) {
    return Row(children: [
      Icon(
        isDone ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 16,
        color: isDone ? AppColors.primary : AppColors.secondaryText,
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 13,
              color: isDone
                  ? AppColors.primaryText
                  : AppColors.secondaryText,
              fontWeight:
                  isDone ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}
