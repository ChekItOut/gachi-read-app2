import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';

class DemoReadingScreen extends StatefulWidget {
  const DemoReadingScreen({super.key});

  @override
  State<DemoReadingScreen> createState() => _DemoReadingScreenState();
}

class _DemoReadingScreenState extends State<DemoReadingScreen> {
  bool _hasScrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!_hasScrolledToBottom) {
          setState(() => _hasScrolledToBottom = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();
    final bookName = BibleConstants.getBookName(provider.currentBook);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$bookName ${provider.currentChapter}장'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // 오늘의 범위 표시
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bookmark,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '오늘의 범위: ${provider.startVerse}~${provider.endVerse}절',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ]),
                ),

                // 성경 구절 목록
                ...provider.todayVerses.map((verse) {
                  final verseNum = verse['verse'] as int;
                  final content = verse['content'] as String;
                  final isInRange = verseNum >= provider.startVerse &&
                      verseNum <= provider.endVerse;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isInRange
                          ? AppColors.surface
                          : AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: isInRange
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1.5)
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isInRange
                                ? AppColors.primary
                                : AppColors.chipBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$verseNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isInRange
                                  ? Colors.white
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            content,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.7,
                              color: isInRange
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
                // 스크롤 유도
                if (!_hasScrolledToBottom)
                  Center(
                    child: Column(children: [
                      const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.secondaryText),
                      Text('아래로 스크롤하여 말씀을 읽어요',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.secondaryText)),
                    ]),
                  ),
              ],
            ),
          ),

          // 완료 버튼
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            color: AppColors.background,
            child: PrimaryButton(
              text: provider.isTodayReadingComplete
                  ? '읽기 완료 ✓'
                  : '읽기 완료',
              onPressed: provider.isTodayReadingComplete
                  ? null
                  : () async {
                      await context
                          .read<DemoProvider>()
                          .completeReading();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('오늘의 말씀을 완료했어요! 🎉'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
              isLoading: provider.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
