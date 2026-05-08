import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';
import 'demo_discussion_screen.dart';

class DemoReflectionScreen extends StatefulWidget {
  const DemoReflectionScreen({super.key});

  @override
  State<DemoReflectionScreen> createState() => _DemoReflectionScreenState();
}

class _DemoReflectionScreenState extends State<DemoReflectionScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  int _step = 0; // 0: 작성, 1: 파트너 대기, 2: 둘 다 완료

  // 대기 화면 애니메이션
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();

    // 상태에 따라 step 업데이트
    if (provider.isMyReflectionDone && provider.isPartnerReflectionDone) {
      _step = 2;
    } else if (provider.isMyReflectionDone) {
      _step = 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('말씀 나누기'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _step == 0
          ? _buildWriteStep(provider)
          : _step == 1
              ? _buildWaitingStep(provider)
              : _buildBothDoneStep(provider),
    );
  }

  // ─── Step 0: 소감 작성 ───────────────────────────────────────────────────
  Widget _buildWriteStep(DemoProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 오늘의 말씀 요약
          SoftCard(
            backgroundColor: AppColors.softMint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 말씀',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  provider.todayRangeText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (provider.todayVerses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${provider.todayVerses.first['content']}"',
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.secondaryText,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('나의 소감', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '오늘 말씀을 읽고 느낀 점, 마음에 와닿은 부분을 자유롭게 적어보세요.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '오늘 말씀을 읽으면서...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: '소감 나누기',
            isLoading: provider.isLoading,
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () async {
                    await context
                        .read<DemoProvider>()
                        .saveMyReflection(_controller.text.trim());
                  },
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }

  // ─── Step 1: 파트너 대기 중 ──────────────────────────────────────────────
  Widget _buildWaitingStep(DemoProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // 편지 봉투 애니메이션 아이콘
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha(30),
                    const Color(0xFF4A90D9).withAlpha(30),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primary.withAlpha(60),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            '내 소감을 보냈어요! 💌',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${provider.partnerName}가 소감을 작성하면\n서로의 나눔을 확인할 수 있어요.',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 내 소감 미리보기 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withAlpha(30),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.softMint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '나의 소감',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    const Text('전송됨',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.secondaryText)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  provider.myReflection,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 파트너 대기 상태 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90D9).withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4A90D9).withAlpha(40),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Color(0xFF4A90D9),
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${provider.partnerName}의 소감을 기다리는 중',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '파트너가 작성하면 알림을 드릴게요',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 홈으로 돌아가기 버튼
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).popUntil(
              (route) => route.isFirst,
            ),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('홈으로 돌아가기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondaryText,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: 둘 다 완료 ──────────────────────────────────────────────────
  Widget _buildBothDoneStep(DemoProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료 배너
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '둘 다 소감을 작성했어요! 🎉',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '서로의 마음을 확인해보세요',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // 내 소감
          Text('나의 소감', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AppCard(
            backgroundColor: AppColors.softMint,
            child: Text(provider.myReflection,
                style: const TextStyle(fontSize: 15, height: 1.7)),
          ),
          const SizedBox(height: 20),

          // 파트너 소감
          Text('${provider.partnerName}의 소감',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          AppCard(
            backgroundColor: AppColors.softBlue,
            child: Text(provider.partnerReflection,
                style: const TextStyle(fontSize: 15, height: 1.7)),
          ),
          const SizedBox(height: 28),

          PrimaryButton(
            text: 'AI 대화 질문 받기',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const DemoDiscussionScreen()),
              );
            },
            icon: Icons.auto_awesome,
          ),
        ],
      ),
    );
  }
}
