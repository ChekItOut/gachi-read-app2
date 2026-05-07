import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/app_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

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
                  _buildCoupleCard(context, partner, provider),
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
          Row(
            children: [
              Expanded(
                child: _buildStatItem(context, '현재 연속', '$currentStreak일'),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildStatItem(context, '최장 연속', '$longestStreak일'),
              ),
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

  Widget _buildCoupleCard(BuildContext context, AppUser partner, AppProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: '커플 정보'),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    partner.displayName.isNotEmpty ? partner.displayName[0] : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner.displayName, style: Theme.of(context).textTheme.titleMedium),
                    Text(partner.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText)),
                  ],
                ),
              ),
              const Icon(Icons.favorite, color: AppColors.primary, size: 20),
            ],
          ),
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

  Widget _buildStatsCard(BuildContext context, AppProvider provider) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: '읽기 통계'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  icon: Icons.menu_book_outlined,
                  label: '총 읽은 날',
                  value: '${provider.totalReadingDays}일',
                  color: AppColors.softMint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: '나눔 횟수',
                  value: '${provider.totalReflections}회',
                  color: AppColors.softBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
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
      ),
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

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
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

  void _showDisconnectDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('커플 연결 해제'),
        content: const Text('커플 연결을 해제하면 공유된 읽기 기록이 초기화됩니다.\n정말 해제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.disconnectCouple();
            },
            child: const Text('해제', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
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
