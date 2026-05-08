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
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _wobbleController;
  late Animation<double> _wobbleAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -14).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 성령의 불 히어로
                _buildFireHeroSection(provider),
                const SizedBox(height: 20),

                if (!provider.hasCoupleConnected) ...[
                  _buildCoupleConnectCard(provider),
                ] else ...[
                  if (!provider.hasReadingPlan) ...[
                    _buildSetPlanCard(provider),
                  ] else ...[
                    // 오늘의 진행 상태 카드 (트렌디)
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
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, _) {
                      final shadowScale =
                          1.0 - (_floatAnimation.value.abs() / 14) * 0.4;
                      return Transform.translate(
                        offset: Offset(
                            0, 140 + _floatAnimation.value.abs() * 0.8),
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
                  Image.asset(
                    _getFireImagePath(provider.fireLevel),
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
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
            Text(
              '성령의 불 Level ${provider.fireLevel}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    '${provider.currentStreak}일 연속',
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

  // ─── 오늘의 진행 상태 카드 (트렌디) ──────────────────────────────────────
  Widget _buildProgressStatusCard(DemoProvider provider) {
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
                name: provider.myName,
                isReadingDone: provider.isTodayReadingComplete,
                isReflectionDone: provider.isMyReflectionDone,
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
                name: provider.partnerName,
                isReadingDone: provider.isTodayReadingComplete,
                isReflectionDone: provider.isPartnerReflectionDone,
                isMe: false,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTodayStatusColor(DemoProvider provider) {
    if (provider.isMyReflectionDone && provider.isPartnerReflectionDone) {
      return const Color(0xFF22C55E);
    } else if (provider.isTodayReadingComplete) {
      return AppColors.primary;
    } else {
      return AppColors.secondaryText;
    }
  }

  String _getTodayStatusLabel(DemoProvider provider) {
    if (provider.isMyReflectionDone && provider.isPartnerReflectionDone) {
      return '나눔 완료 ✓';
    } else if (provider.isMyReflectionDone) {
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
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

  // ─── 오늘의 말씀 카드 ────────────────────────────────────────────────────
  Widget _buildTodayCard(DemoProvider provider) {
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
                      provider.todayRangeText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
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
          _buildActionButton(provider),
        ],
      ),
    );
  }

  Widget _buildActionButton(DemoProvider provider) {
    // 아직 읽지 않음
    if (!provider.isTodayReadingComplete) {
      return PrimaryButton(
        text: '말씀 읽기',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DemoReadingScreen()),
        ),
        icon: Icons.menu_book_outlined,
      );
    }

    // 읽었지만 내 소감 미작성
    if (!provider.isMyReflectionDone) {
      return PrimaryButton(
        text: '말씀 나누기',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DemoReflectionScreen()),
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
                  '${provider.partnerName}의 나눔을 기다리는 중...',
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
        MaterialPageRoute(builder: (_) => const DemoDiscussionScreen()),
      ),
      icon: Icons.auto_awesome,
    );
  }

  // ─── 커플 연결 카드 ──────────────────────────────────────────────────────
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

  // ─── 플랜 설정 카드 ──────────────────────────────────────────────────────
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
                  Text('어디서부터 얼마나 읽을지 설정해요',
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

  // ─── 플랜 설정 바텀시트 ──────────────────────────────────────────────────
  void _showPlanSetupSheet(DemoProvider provider) {
    final books = BibleConstants.bookOrder;
    String selectedBook = '창';
    int selectedChapter = 1;
    ReadingUnit selectedUnit = ReadingUnit.chapter;
    int dailyAmount = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드래그 핸들
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
                const SizedBox(height: 4),
                Text('커플이 함께 읽을 성경 플랜을 설정해요',
                    style: Theme.of(ctx)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.secondaryText)),
                const SizedBox(height: 24),

                // ── 1. 성경 책 선택 ──────────────────────────────────────
                _sheetLabel(ctx, '📖 시작할 성경 책'),
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
                const SizedBox(height: 20),

                // ── 2. 시작 장 선택 ──────────────────────────────────────
                _sheetLabel(ctx, '📌 시작 장'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    IconButton(
                      onPressed: selectedChapter > 1
                          ? () =>
                              setModalState(() => selectedChapter--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: Center(
                        child: Text('$selectedChapter장',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setModalState(() => selectedChapter++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── 3. 읽기 단위 선택 (장/절) ────────────────────────────
                _sheetLabel(ctx, '📏 읽기 단위'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _unitToggleButton(
                      ctx: ctx,
                      label: '장 단위',
                      sublabel: '한 번에 N장씩',
                      icon: Icons.import_contacts_rounded,
                      isSelected: selectedUnit == ReadingUnit.chapter,
                      onTap: () => setModalState(
                          () => selectedUnit = ReadingUnit.chapter),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _unitToggleButton(
                      ctx: ctx,
                      label: '절 단위',
                      sublabel: '한 번에 N절씩',
                      icon: Icons.format_list_numbered_rounded,
                      isSelected: selectedUnit == ReadingUnit.verse,
                      onTap: () => setModalState(
                          () => selectedUnit = ReadingUnit.verse),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── 4. 하루 분량 설정 ────────────────────────────────────
                _sheetLabel(
                  ctx,
                  selectedUnit == ReadingUnit.chapter
                      ? '📅 하루에 몇 장씩 읽을까요?'
                      : '📅 하루에 몇 절씩 읽을까요?',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    IconButton(
                      onPressed: dailyAmount > 1
                          ? () => setModalState(() => dailyAmount--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              '$dailyAmount',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary),
                            ),
                            Text(
                              selectedUnit == ReadingUnit.chapter
                                  ? '장 / 일'
                                  : '절 / 일',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setModalState(() => dailyAmount++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                // 요약 미리보기
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '📋 ${BibleConstants.getBookName(selectedBook)} $selectedChapter장부터 '
                    '매일 $dailyAmount${selectedUnit == ReadingUnit.chapter ? '장' : '절'}씩 읽기',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  text: '플랜 시작하기',
                  isLoading: provider.isLoading,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await context.read<DemoProvider>().setReadingPlan(
                          book: selectedBook,
                          chapter: selectedChapter,
                          unit: selectedUnit,
                          dailyAmount: dailyAmount,
                          startVerse: 1,
                        );
                  },
                  icon: Icons.rocket_launch_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(BuildContext ctx, String text) {
    return Text(text,
        style: Theme.of(ctx)
            .textTheme
            .labelLarge
            ?.copyWith(fontSize: 14));
  }

  Widget _unitToggleButton({
    required BuildContext ctx,
    required String label,
    required String sublabel,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 22,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.secondaryText),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primaryText)),
            Text(sublabel,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  // ─── 스트릭 시트 ─────────────────────────────────────────────────────────
  void _showStreakSheet(DemoProvider provider) {
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
            Image.asset(_getFireImagePath(provider.fireLevel),
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
                  child: _statItem(
                      '현재 연속', '${provider.currentStreak}일')),
              Container(
                  width: 1, height: 40, color: AppColors.divider),
              Expanded(
                  child: _statItem(
                      '최장 연속', '${provider.longestStreak}일')),
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

  // ─── 레벨별 이미지 경로 헬퍼 ────────────────────────────────────────────
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
          style: const TextStyle(
              fontSize: 13, color: AppColors.secondaryText)),
    ]);
  }
}
