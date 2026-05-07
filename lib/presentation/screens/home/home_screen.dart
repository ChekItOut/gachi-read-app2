import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../data/models/app_models.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshAll();
    });
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  // 커플 미연결 상태
                  if (!provider.hasCoupleConnected) ...[
                    _buildCoupleConnectCard(),
                    const SizedBox(height: 20),
                  ],
                  // 커플 연결됨
                  if (provider.hasCoupleConnected) ...[
                    // 스트릭 카드
                    _buildStreakCard(provider),
                    const SizedBox(height: 20),
                    // 오늘의 말씀 카드
                    _buildTodayReadingCard(provider),
                    const SizedBox(height: 20),
                    // 커플 상태 카드
                    _buildCoupleStatusCard(provider),
                    const SizedBox(height: 20),
                    // 플랜 없을 때
                    if (!provider.hasReadingPlan) _buildNoPlanCard(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.appUser?.displayName != null
                          ? '안녕하세요, ${provider.appUser!.displayName}님 👋'
                          : '가치읽자',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              // 성령의 불 아이콘
              if (provider.myStreak != null)
                _buildFireIcon(provider.myStreak!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFireIcon(ReadingStreak streak) {
    return GestureDetector(
      onTap: () => _showStreakDetail(streak),
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.softMint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/holy_fire_sample.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${streak.currentStreak}일',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStreakDetail(ReadingStreak streak) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/holy_fire_sample.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 16),
            Text(
              '성령의 불 Level ${streak.fireLevel}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '현재 ${streak.currentStreak}일 연속 읽기 중',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStreakStat('현재 연속', '${streak.currentStreak}일'),
                ),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(
                  child: _buildStreakStat('최장 연속', '${streak.longestStreak}일'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (streak.currentStreak < 5)
              Text(
                '${5 - streak.currentStreak}일 더 읽으면 Level 2로 진화해요!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                textAlign: TextAlign.center,
              )
            else if (streak.currentStreak < 10)
              Text(
                '${10 - streak.currentStreak}일 더 읽으면 Level 3으로 진화해요!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                textAlign: TextAlign.center,
              )
            else
              const Text(
                '최고 레벨 달성! 정말 대단해요!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildCoupleConnectCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBox(icon: Icons.favorite_outline, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '파트너와 연결하기',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '커플 연결 후 함께 성경을 읽어요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: '커플 연결하기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoupleConnectScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(AppProvider provider) {
    final streak = provider.myStreak;
    final currentStreak = streak?.currentStreak ?? 0;
    final fireLevel = streak?.fireLevel ?? 1;

    return SoftCard(
      backgroundColor: AppColors.softMint,
      child: Row(
        children: [
          // 불 이미지
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/holy_fire_sample.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '성령의 불 Level $fireLevel',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentStreak일 연속 읽기 중',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                if (currentStreak < 5)
                  Text(
                    '${5 - currentStreak}일 후 Level 2 달성!',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  )
                else if (currentStreak < 10)
                  Text(
                    '${10 - currentStreak}일 후 Level 3 달성!',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  )
                else
                  const Text(
                    '최고 레벨 달성!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          // 진행 표시
          Column(
            children: [
              Text(
                '$currentStreak',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const Text(
                '일',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayReadingCard(AppProvider provider) {
    final todayReading = provider.todayReading;
    final isComplete = provider.isTodayReadingComplete;

    if (todayReading == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBox(icon: Icons.menu_book_outlined, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('오늘의 말씀', style: Theme.of(context).textTheme.titleLarge),
                      Text('읽기 플랜을 설정해주세요',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondaryText,
                              )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: '읽기 플랜 설정',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
              ),
            ),
          ],
        ),
      );
    }

    final bookName = BibleConstants.getBookName(todayReading['bookCode']);
    final chapter = todayReading['chapter'];
    final startVerse = todayReading['startVerse'];
    final endVerse = todayReading['endVerse'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBox(icon: Icons.menu_book_outlined, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('오늘의 말씀', style: Theme.of(context).textTheme.labelLarge),
                        const Spacer(),
                        StatusChip(
                          label: isComplete ? '완료' : '미완료',
                          isActive: isComplete,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$bookName $chapter:$startVerse-$endVerse',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isComplete)
            PrimaryButton(
              text: '말씀 읽기',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyReadingScreen()),
              ),
              icon: Icons.menu_book_outlined,
            )
          else
            _buildPostReadingActions(provider),
        ],
      ),
    );
  }

  Widget _buildPostReadingActions(AppProvider provider) {
    final myReflectionDone = provider.isTodayReflectionDone;
    final partnerReflectionDone = provider.isPartnerReflectionDone;
    final bothDone = myReflectionDone && partnerReflectionDone;

    if (!myReflectionDone) {
      return PrimaryButton(
        text: '말씀 나누기',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReflectionScreen()),
        ),
        icon: Icons.chat_bubble_outline,
      );
    }

    if (!partnerReflectionDone) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${provider.partner?.displayName ?? "파트너"}의 나눔을 기다리는 중...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (!bothDone)
          const SizedBox()
        else
          PrimaryButton(
            text: 'AI 대화 질문 보기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscussionScreen()),
            ),
            icon: Icons.auto_awesome,
          ),
      ],
    );
  }

  Widget _buildCoupleStatusCard(AppProvider provider) {
    if (provider.partner == null) return const SizedBox();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: '우리의 오늘'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPersonStatus(
                  name: provider.appUser?.displayName ?? '나',
                  isReadingDone: provider.isTodayReadingComplete,
                  isReflectionDone: provider.isTodayReflectionDone,
                  isMe: true,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.favorite, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPersonStatus(
                  name: provider.partner!.displayName,
                  isReadingDone: provider.isPartnerReadingComplete,
                  isReflectionDone: provider.isPartnerReflectionDone,
                  isMe: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonStatus({
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
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(Icons.menu_book_outlined, '읽기', isReadingDone),
          const SizedBox(height: 6),
          _buildStatusRow(Icons.chat_bubble_outline, '나눔', isReflectionDone),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isDone ? AppColors.primary : AppColors.secondaryText,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDone ? AppColors.primaryText : AppColors.secondaryText,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildNoPlanCard() {
    return AppCard(
      backgroundColor: AppColors.softBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBox(
                icon: Icons.calendar_today_outlined,
                size: 48,
                color: Color(0xFF4A90D9),
                backgroundColor: Color(0xFFD0E8FA),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '읽기 플랜 설정',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '어디서부터 읽을지 설정해요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: '플랜 설정하기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
