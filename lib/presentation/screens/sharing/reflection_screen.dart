import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/services/bible_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import 'discussion_screen.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 기존 소감 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.myReflection != null) {
        _controller.text = provider.myReflection!.content;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('소감을 작성해주세요'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<AppProvider>().saveReflection(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('소감이 저장되었습니다'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 파트너 소감 확인 화면으로 이동
        Navigator.pushReplacement(
          context,
          SharedAxisPageRoute(builder: (_) => const ReflectionViewScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final todayReading = provider.todayReading;
    final rangeText = todayReading != null
        ? BibleService.instance.formatReadingRange(todayReading)
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('말씀 나누기'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 오늘 읽은 말씀 표시
              if (todayReading != null) ...[
                SoftCard(
                  backgroundColor: AppColors.softMint,
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book,
                          color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘 읽은 말씀',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              rangeText,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 소감 작성 안내
              Text(
                '오늘의 말씀 소감',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '오늘 읽은 말씀에서 느낀 점, 깨달은 점,\n마음에 와닿은 구절을 자유롭게 나눠보세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
              const SizedBox(height: 16),

              // 소감 입력 필드
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 10,
                  minLines: 8,
                  decoration: InputDecoration(
                    hintText:
                        '오늘 말씀을 읽으며 어떤 생각이 들었나요?\n파트너와 나누고 싶은 이야기를 적어보세요...',
                    hintStyle: TextStyle(
                      color: AppColors.secondaryText.withOpacity(0.6),
                      fontSize: 15,
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 글자 수
              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, value, __) => Text(
                    '${value.text.length}자',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 저장 버튼
              PrimaryButton(
                text: '소감 저장하기',
                onPressed: _saveReflection,
                isLoading: _isSaving,
                icon: Icons.send_outlined,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// 소감 확인 화면 (내 소감 + 파트너 소감)
class ReflectionViewScreen extends StatefulWidget {
  const ReflectionViewScreen({super.key});

  @override
  State<ReflectionViewScreen> createState() => _ReflectionViewScreenState();
}

class _ReflectionViewScreenState extends State<ReflectionViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshTodayData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final myReflection = provider.myReflection;
    final partnerReflection = provider.partnerReflection;
    final partner = provider.partner;
    final bothDone =
        provider.isTodayReflectionDone && provider.isPartnerReflectionDone;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('말씀 나눔'),
        actions: [
          if (myReflection != null)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                SharedAxisPageRoute(builder: (_) => const ReflectionScreen()),
              ),
              child: const Text(
                '수정',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshTodayData(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 내 소감
              _buildReflectionCard(
                context: context,
                name: provider.appUser?.displayName ?? '나',
                reflection: myReflection?.content,
                isMe: true,
                onWrite: () => Navigator.push(
                  context,
                  SharedAxisPageRoute(builder: (_) => const ReflectionScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // 파트너 소감
              _buildReflectionCard(
                context: context,
                name: partner?.displayName ?? '파트너',
                reflection: partnerReflection?.content,
                isMe: false,
                isWaiting: myReflection == null,
              ),

              // 둘 다 완료했을 때 AI 질문 버튼
              if (bothDone) ...[
                const SizedBox(height: 24),
                _buildAiDiscussionCard(provider),
              ],

              // 파트너 대기 중일 때 홈으로 돌아가기 버튼
              if (myReflection != null && !provider.isPartnerReflectionDone) ...[
                const SizedBox(height: 24),
                PrimaryButton(
                  text: '홈으로 돌아가기',
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: Icons.home_outlined,
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReflectionCard({
    required BuildContext context,
    required String name,
    String? reflection,
    required bool isMe,
    VoidCallback? onWrite,
    bool isWaiting = false,
  }) {
    final bgColor = isMe ? AppColors.softMint : AppColors.softBlue;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      isMe ? '나의 소감' : '파트너의 소감',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: reflection != null ? '작성 완료' : '미작성',
                isActive: reflection != null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppDivider(),
          const SizedBox(height: 16),
          if (reflection != null)
            Text(
              reflection,
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: AppColors.primaryText,
              ),
            )
          else if (!isMe && isWaiting)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: AppColors.secondaryText, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '먼저 소감을 작성해야 파트너의 소감을 볼 수 있어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!isMe && !isWaiting)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty,
                      color: AppColors.secondaryText, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '파트너가 아직 소감을 작성하지 않았어요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                    ),
                  ),
                ],
              ),
            )
          else if (isMe && onWrite != null)
            PrimaryButton(
              text: '소감 작성하기',
              onPressed: onWrite,
              icon: Icons.edit_outlined,
            ),
        ],
      ),
    );
  }

  Widget _buildAiDiscussionCard(AppProvider provider) {
    return AppCard(
      backgroundColor: const Color(0xFFF8F3FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.purple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 대화 질문',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '두 분의 소감을 분석한 맞춤형 질문',
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
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                SharedAxisPageRoute(builder: (_) => const DiscussionScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '대화 질문 보기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
