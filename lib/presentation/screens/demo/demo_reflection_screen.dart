import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';

class DemoReflectionScreen extends StatefulWidget {
  const DemoReflectionScreen({super.key});

  @override
  State<DemoReflectionScreen> createState() => _DemoReflectionScreenState();
}

class _DemoReflectionScreenState extends State<DemoReflectionScreen> {
  final _controller = TextEditingController();
  int _step = 0; // 0: 작성, 1: 파트너 대기, 2: 둘 다 완료

  @override
  void dispose() {
    _controller.dispose();
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

  Widget _buildWriteStep(DemoProvider provider) {
    final bookName =
        BibleConstants.getBookName(provider.currentBook);
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
                  '$bookName ${provider.currentChapter}장 ${provider.startVerse}-${provider.endVerse}절',
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

  Widget _buildWaitingStep(DemoProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.hourglass_empty,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('내 소감을 보냈어요! 💌',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              '${provider.partnerName}가 소감을 작성하면\n서로의 나눔을 확인할 수 있어요.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // 내 소감 미리보기
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.softMint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('나의 소감',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(provider.myReflection,
                      style: const TextStyle(
                          fontSize: 15, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
            const SizedBox(height: 8),
            Text('잠시 후 ${provider.partnerName}의 소감이 도착해요...',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }

  Widget _buildBothDoneStep(DemoProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 완료 배너
          SoftCard(
            backgroundColor: AppColors.softMint,
            child: Row(children: [
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '둘 다 소감을 작성했어요! 서로의 마음을 확인해보세요 💚',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText),
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
              Navigator.pop(context);
              // 홈으로 돌아가면 AI 버튼이 보임
            },
            icon: Icons.auto_awesome,
          ),
        ],
      ),
    );
  }
}
