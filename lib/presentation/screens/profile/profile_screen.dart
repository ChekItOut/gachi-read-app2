import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/models/app_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../home/reading_plan_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.appUser;
    final streak = provider.myStreak;
    final partner = provider.partner;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text('프로필', style: Theme.of(context).textTheme.titleLarge),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                // 프로필 카드
                _buildProfileCard(context, user, streak),
                const SizedBox(height: 20),
                // 성령의 불 카드
                _buildFireCard(context, streak),
                const SizedBox(height: 20),
                // 커플 정보
                if (partner != null) ...[
                  _buildCoupleCard(context, user, partner, provider),
                  const SizedBox(height: 20),
                  // 읽기 플랜 정보
                  _buildReadingPlanCard(context, provider),
                  const SizedBox(height: 20),
                ],
                // 통계
                _buildStatsCard(context, provider),
                const SizedBox(height: 20),
                // 설정 메뉴
                _buildSettingsCard(context, provider),
                const SizedBox(height: 20),
                // 로그아웃
                _buildLogoutButton(context, provider),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppUser? user, ReadingStreak? streak) {
    return AppCard(
      child: Row(
        children: [
          // 아바타
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.softMint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: user?.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      user!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarFallback(user.displayName),
                    ),
                  )
                : _buildAvatarFallback(user?.displayName ?? '?'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? '사용자',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  // 레벨별 설명 텍스트
  String _getFireLevelDescription(int level) {
    switch (level) {
      case 2:
        return '성령의 불꽃이 타오르고 있어요!';
      case 3:
        return '성령의 불이 활활 타오르고 있어요!';
      default:
        return '말씀의 씨앗이 자라고 있어요';
    }
  }

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

  Widget _buildFireCard(BuildContext context, ReadingStreak? streak) {
    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;
    final fireLevel = streak?.fireLevel ?? 1;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    _getFireImagePath(fireLevel),
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
                      '성령의 불',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Level $fireLevel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFireLevelDescription(fireLevel),
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
          const SizedBox(height: 20),
          // 레벨 진행 바
          _buildLevelProgress(context, currentStreak, fireLevel),
          const SizedBox(height: 20),
          // 통계
          
          const SizedBox(height: 16),
          // 레벨 안내
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _levelBadge(context, 1, '기본', fireLevel >= 1),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppColors.secondaryText),
              _levelBadge(context, 2, '5일+', fireLevel >= 2, onTap: () => _showFirePreview(context, 2)),
              const Icon(Icons.arrow_forward,
                  size: 16, color: AppColors.secondaryText),
              _levelBadge(context, 3, '10일+', fireLevel >= 3, onTap: () => _showFirePreview(context, 3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, int currentStreak, int fireLevel) {
    double progress;
    String nextLevelText;

    if (currentStreak < 5) {
      progress = currentStreak / 5;
      nextLevelText = 'Level 2까지 ${5 - currentStreak}일';
    } else if (currentStreak < 10) {
      progress = (currentStreak - 5) / 5;
      nextLevelText = 'Level 3까지 ${10 - currentStreak}일';
    } else {
      progress = 1.0;
      nextLevelText = '최고 레벨 달성!';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $fireLevel',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
            Text(
              nextLevelText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.chipBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
      ],
    );
  }

  Widget _levelBadge(
      BuildContext context, int level, String label, bool isUnlocked,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
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
      ]),
    );
  }

  void _showFirePreview(BuildContext context, int level) {
    final imagePath = _getFireImagePath(level);
    final levelName = level == 2 ? '성령의 불꽃' : '성령의 큰 불';
    final description = level == 2
        ? '5일 연속 읽기를 달성하면\n이 캐릭터로 변해요!'
        : '10일 연속 읽기를 달성하면\n이 캐릭터로 변해요!';

    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 280,
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
              // 이미지
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 레벨 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Level $level · $levelName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 설명
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // 닫기 버튼
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
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

  Widget _buildCoupleCard(BuildContext context, AppUser? user, AppUser partner, AppProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '커플 정보'),
          const SizedBox(height: 16),
          Row(children: [
            _personChip(user?.displayName ?? '사용자', AppColors.softMint),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.favorite, color: AppColors.primary, size: 20),
            ),
            _personChip(partner.displayName, AppColors.softBlue),
          ]),
          const SizedBox(height: 16),
          OutlineButton(
            text: '커플 연결 해제',
            onPressed: () => _showDisconnectDialog(context, provider),
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPlanCard(BuildContext context, AppProvider provider) {
    final plan = provider.readingPlan;

    if (plan == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: '읽기 플랜'),
            const SizedBox(height: 16),
            const Text(
              '아직 읽기 플랜이 설정되지 않았어요.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: '플랜 설정하기',
              onPressed: () => Navigator.push(
                context,
                SharedAxisPageRoute(builder: (_) => const ReadingPlanScreen()),
              ),
              icon: Icons.add_circle_outline,
            ),
          ],
        ),
      );
    }

    final bookName = BibleConstants.getBookName(plan.startBook);
    final unitText = plan.dailyChapters > 0
        ? '하루 ${plan.dailyChapters}장'
        : '하루 ${plan.dailyVerses}절';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '읽기 플랜'),
          const SizedBox(height: 16),
          _planInfoRow('시작 위치', '$bookName ${plan.startChapter}:${plan.startVerse}'),
          const SizedBox(height: 10),
          _planInfoRow('읽기 방식', unitText),
          const SizedBox(height: 16),
          OutlineButton(
            text: '플랜 수정하기',
            onPressed: () => Navigator.push(
              context,
              SharedAxisPageRoute(
                builder: (_) => const ReadingPlanScreen(isEditMode: true),
              ),
            ),
            icon: Icons.edit_outlined,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _planInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
      ],
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

  Widget _buildStatsCard(BuildContext context, AppProvider provider) {
    final streak = provider.myStreak;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '나의 기록'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _statBox(context, '현재 연속',
                    '${streak?.currentStreak ?? 0}일', AppColors.softMint)),
            const SizedBox(width: 12),
            Expanded(
                child: _statBox(context, '최장 연속',
                    '${streak?.longestStreak ?? 0}일', AppColors.softBlue)),
            const SizedBox(width: 12),
            Expanded(
                child: _statBox(context, '총 완료',
                    '${provider.totalReadingDays}일',
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

  Widget _buildSettingsCard(BuildContext context, AppProvider provider) {
    return AppCard(
      child: Column(
        children: [
          _buildSettingRow(
            context,
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            onTap: () {},
          ),
          const AppDivider(),
          _buildSettingRow(
            context,
            icon: Icons.info_outline,
            title: '앱 정보',
            onTap: () => _showAppInfo(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBox(icon: icon, size: 40),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppProvider provider) {
    return OutlineButton(
      text: '로그아웃',
      onPressed: () => _showLogoutDialog(context, provider),
      icon: Icons.logout,
    );
  }

  void _showDisconnectDialog(BuildContext context, AppProvider provider) {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('커플 연결 해제'),
        content: const Text('커플 연결을 해제하면 함께 읽기 기록이 초기화됩니다.\n정말 해제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.disconnectCouple();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('커플 연결이 해제되었습니다.')),
                );
              }
            },
            child: const Text('해제', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.signOut();
            },
            child: const Text('로그아웃', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        barrierColor: Color(0x3C000000),
      ),
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('가치읽자'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('버전: 1.0.0'),
            SizedBox(height: 8),
            Text('커플 성경읽기 앱'),
            SizedBox(height: 8),
            Text('매일 말씀을 함께 읽고 나누며\n믿음 안에서 함께 성장하세요'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
