import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';
import 'demo_reflection_screen.dart';

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

    // 장 단위일 때 타이틀 표시
    String appBarTitle;
    if (provider.readingUnit == ReadingUnit.chapter) {
      if (provider.dailyAmount == 1) {
        appBarTitle = '$bookName ${provider.currentChapter}장';
      } else {
        appBarTitle =
            '$bookName ${provider.currentChapter}-${provider.currentChapter + provider.dailyAmount - 1}장';
      }
    } else {
      appBarTitle =
          '$bookName ${provider.currentChapter}장 ${provider.startVerse}-${provider.endVerse}절';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appBarTitle),
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
                    Expanded(
                      child: Text(
                        '오늘의 범위: ${provider.todayRangeText}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                  ]),
                ),

                // 성경 구절 목록
                ...provider.todayVerses.map((verse) {
                  final verseNum = verse['verse'] as int;
                  final content = verse['content'] as String;
                  final chapterNum = verse['chapterNum'] as int?;

                  // 장 단위일 때 장 구분 헤더
                  final showChapterHeader = provider.readingUnit ==
                          ReadingUnit.chapter &&
                      chapterNum != null &&
                      verseNum == 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showChapterHeader)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 16, bottom: 8),
                          child: Text(
                            '$bookName $chapterNum장',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.15),
                              width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$verseNum',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                content,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.7,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 20),
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
                      if (!context.mounted) return;

                      // 읽기 완료 후 소감 작성 화면으로 바로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DemoReflectionScreen(),
                        ),
                      );
                    },
              isLoading: provider.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
