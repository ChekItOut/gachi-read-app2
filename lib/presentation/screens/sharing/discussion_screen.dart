import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../data/services/bible_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  bool _isGenerating = false;

  Future<void> _generateQuestions() async {
    setState(() => _isGenerating = true);
    try {
      final provider = context.read<AppProvider>();
      final todayReading = provider.todayReading;
      if (todayReading == null) return;

      final bibleService = BibleService.instance;
      final verses = bibleService.getVerseRange(
        todayReading['bookCode'],
        todayReading['chapter'],
        todayReading['startVerse'],
        todayReading['endVerse'],
      );

      await provider.generateAiDiscussion(
        verses.map((v) => '${v.verse}절: ${v.content}').toList(),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.aiDiscussion == null &&
          provider.isTodayReflectionDone &&
          provider.isPartnerReflectionDone) {
        _generateQuestions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final aiDiscussion = provider.aiDiscussion;
    final todayReading = provider.todayReading;

    final bookName = todayReading != null
        ? BibleConstants.getBookName(todayReading['bookCode'])
        : '';
    final chapter = todayReading?['chapter'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI 대화 질문'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 카드
            _buildHeaderCard(bookName, chapter.toString()),
            const SizedBox(height: 24),

            // 소감 요약
            _buildReflectionSummary(provider),
            const SizedBox(height: 24),

            // AI 질문 섹션
            if (_isGenerating)
              _buildLoadingCard()
            else if (aiDiscussion != null)
              _buildQuestionsCard(aiDiscussion.questions)
            else
              _buildGenerateCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String bookName, String chapter) {
    return SoftCard(
      backgroundColor: const Color(0xFFF3EEFF),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.purple, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 맞춤형 대화 질문',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$bookName $chapter장 기반',
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

  Widget _buildReflectionSummary(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('나눔 요약', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniReflectionCard(
                name: provider.appUser?.displayName ?? '나',
                content: provider.myReflection?.content ?? '',
                color: AppColors.softMint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniReflectionCard(
                name: provider.partner?.displayName ?? '파트너',
                content: provider.partnerReflection?.content ?? '',
                color: AppColors.softBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniReflectionCard({
    required String name,
    required String content,
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
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.length > 60 ? '${content.substring(0, 60)}...' : content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: AppColors.purple),
          const SizedBox(height: 20),
          Text(
            'AI가 맞춤형 질문을 생성하고 있어요...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '두 분의 소감을 분석하여\n깊이 있는 대화를 위한 질문을 만들고 있어요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuestionsCard(List<String> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('대화 질문', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton.icon(
              onPressed: _generateQuestions,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.purple),
              label: const Text(
                '재생성',
                style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softMint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '이 질문들을 바탕으로 파트너와 깊이 있는 대화를 나눠보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateCard() {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.purple, size: 48),
          const SizedBox(height: 16),
          Text(
            'AI 대화 질문 생성',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '두 분의 소감을 분석하여\n맞춤형 대화 질문을 생성해드려요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _generateQuestions,
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
                    '질문 생성하기',
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
