import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';

class DemoProfileScreen extends StatelessWidget {
  const DemoProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text('프로필'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 프로필 카드
                _buildProfileCard(context, provider),
                const SizedBox(height: 20),

                // 성령의 불 카드
                _buildFireCard(context, provider),
                const SizedBox(height: 20),

                // 통계 카드
                _buildStatsCard(context, provider),
                const SizedBox(height: 20),

                // 커플 정보
                if (provider.hasCoupleConnected)
                  _buildCoupleCard(context, provider),
                const SizedBox(height: 20),

                // 데모 테스트 버튼
                _buildDemoTestCard(context, provider),
                const SizedBox(height: 12),

                // 데모 안내
                _buildDemoNotice(context),
                const SizedBox(height: 20),

                // 로그아웃
                OutlineButton(
                  text: '로그아웃',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('로그아웃'),
                        content: const Text('로그아웃 하시겠어요?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              provider.logout();
                            },
                            child: const Text('로그아웃',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icons.logout,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, DemoProvider provider) {
    return AppCard(
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.softMint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              provider.myName.isNotEmpty
                  ? provider.myName[0]
                  : '?',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.myName,
                  style: Theme.of(context).textTheme.titleLarge),
              Text('데모 사용자',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.secondaryText)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildFireCard(BuildContext context, DemoProvider provider) {
    final levelDescriptions = {
      1: '말씀의 씨앗이 자라고 있어요',
      2: '성령의 불꽃이 타오르고 있어요!',
      3: '성령의 불이 활활 타오르고 있어요! 🔥',
    };

    return AppCard(
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/images/holy_fire_sample.png',
                    fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('성령의 불',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Lv.${provider.fireLevel}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    levelDescriptions[provider.fireLevel] ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          // 레벨 진행 바
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '다음 레벨까지',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.secondaryText),
                  ),
                  Text(
                    provider.currentStreak < 5
                        ? '${provider.currentStreak}/5일'
                        : provider.currentStreak < 10
                            ? '${provider.currentStreak}/10일'
                            : '최고 레벨 달성!',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: provider.currentStreak < 5
                      ? provider.currentStreak / 5
                      : provider.currentStreak < 10
                          ? (provider.currentStreak - 5) / 5
                          : 1.0,
                  backgroundColor: AppColors.chipBackground,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 레벨 안내
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _levelBadge(context, 1, '기본', provider.fireLevel >= 1),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppColors.secondaryText),
              _levelBadge(context, 2, '5일+', provider.fireLevel >= 2),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppColors.secondaryText),
              _levelBadge(context, 3, '10일+', provider.fireLevel >= 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelBadge(
      BuildContext context, int level, String label, bool isUnlocked) {
    return Column(children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.softMint : AppColors.chipBackground,
          borderRadius: BorderRadius.circular(14),
          border: isUnlocked
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text('Lv.$level',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked
                      ? AppColors.primary
                      : AppColors.secondaryText)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: isUnlocked
                  ? AppColors.primary
                  : AppColors.secondaryText)),
    ]);
  }

  Widget _buildStatsCard(BuildContext context, DemoProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '나의 기록'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _statBox(context, '현재 연속',
                    '${provider.currentStreak}일', AppColors.softMint)),
            const SizedBox(width: 12),
            Expanded(
                child: _statBox(context, '최장 연속',
                    '${provider.longestStreak}일', AppColors.softBlue)),
            const SizedBox(width: 12),
            Expanded(
                child: _statBox(context, '총 완료',
                    '${provider.completedDates.length}일',
                    const Color(0xFFFFF3E0))),
          ]),
        ],
      ),
    );
  }

  Widget _statBox(BuildContext context, String label, String value,
      Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.secondaryText)),
      ]),
    );
  }

  Widget _buildCoupleCard(BuildContext context, DemoProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '커플 정보'),
          const SizedBox(height: 16),
          Row(children: [
            _personChip(provider.myName, AppColors.softMint),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.favorite, color: AppColors.primary, size: 20),
            ),
            _personChip(provider.partnerName, AppColors.softBlue),
          ]),
        ],
      ),
    );
  }

  Widget _personChip(String name, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(name,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText)),
    );
  }

  Widget _buildDemoTestCard(BuildContext context, DemoProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCE93D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.science_outlined, color: Color(0xFF7B1FA2), size: 18),
            SizedBox(width: 8),
            Text(
              '🧪 데모 테스트',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B1FA2),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // 스트릭을 5로 설정하여 레벨2 달성 테스트
                  provider.testLevelUp(2);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text('🔥🔥', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 4),
                      Text(
                        'Lv.2 달성',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // 스트릭을 10으로 설정하여 레벨3 달성 테스트
                  provider.testLevelUp(3);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text('🔥🔥🔥', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 4),
                      Text(
                        'Lv.3 달성',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => provider.breakStreak(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text('💨', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 4),
                      Text(
                        '연속 깨짐',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDemoNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline,
            color: Color(0xFFF9A825), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('데모 버전 안내',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF795548))),
              const SizedBox(height: 4),
              Text(
                '현재 데모 버전입니다. 실제 서비스는 Google 로그인과 Firebase를 사용하여 커플 간 실시간 데이터 동기화가 이루어집니다.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF795548)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
