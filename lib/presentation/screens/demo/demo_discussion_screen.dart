import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';

class DemoDiscussionScreen extends StatefulWidget {
  const DemoDiscussionScreen({super.key});

  @override
  State<DemoDiscussionScreen> createState() => _DemoDiscussionScreenState();
}

class _DemoDiscussionScreenState extends State<DemoDiscussionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DemoProvider>();
      if (provider.aiQuestions.isEmpty) {
        provider.generateAiQuestions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();
    final bookName = BibleConstants.getBookName(provider.currentBook);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI 대화 질문'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: provider.isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더
                  SoftCard(
                    backgroundColor: const Color(0xFFF0EEFF),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0DBFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Color(0xFF6B5CE7), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AI 맞춤 대화 질문',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText)),
                            Text(
                              '$bookName ${provider.currentChapter}장 기반',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '두 분의 소감을 분석하여 함께 나눌 대화 주제를 만들었어요.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 24),

                  // 소감 요약
                  Text('오늘의 소감 요약',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.softMint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.myName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                            const SizedBox(height: 6),
                            Text(
                              provider.myReflection,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.partnerName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4A90D9))),
                            const SizedBox(height: 6),
                            Text(
                              provider.partnerReflection,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // AI 질문 목록
                  Text('대화 질문',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ...provider.aiQuestions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final question = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Q${idx + 1}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                question,
                                style: const TextStyle(
                                    fontSize: 15, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  OutlineButton(
                    text: '질문 다시 생성',
                    onPressed: () =>
                        context.read<DemoProvider>().generateAiQuestions(),
                    icon: Icons.refresh,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.auto_awesome,
                size: 40, color: Color(0xFF6B5CE7)),
          ),
          const SizedBox(height: 24),
          const Text('AI가 대화 질문을 만들고 있어요...',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText)),
          const SizedBox(height: 8),
          const Text('두 분의 소감을 분석 중입니다',
              style: TextStyle(
                  fontSize: 14, color: AppColors.secondaryText)),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
              color: Color(0xFF6B5CE7), strokeWidth: 3),
        ],
      ),
    );
  }
}
