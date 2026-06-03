import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../data/services/bible_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../sharing/reflection_screen.dart';

class DailyReadingScreen extends StatefulWidget {
  const DailyReadingScreen({super.key});

  @override
  State<DailyReadingScreen> createState() => _DailyReadingScreenState();
}

class _DailyReadingScreenState extends State<DailyReadingScreen> {
  final BibleService _bibleService = BibleService.instance;
  List<BibleVerse> _verses = [];
  bool _isLoading = true;
  bool _hasScrolledToEnd = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVerses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_hasScrolledToEnd) {
        setState(() => _hasScrolledToEnd = true);
      }
    }
  }

  Future<void> _loadVerses() async {
    final provider = context.read<AppProvider>();
    final todayReading = provider.todayReading;
    if (todayReading == null) return;

    await _bibleService.loadBible();
    final verses = _bibleService.getReadingVerses(todayReading);

    setState(() {
      _verses = verses;
      _isLoading = false;
    });
  }

  Future<void> _markComplete() async {
    final provider = context.read<AppProvider>();
    await provider.markTodayReadingComplete();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        SharedAxisPageRoute(builder: (_) => const ReflectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final todayReading = provider.todayReading;

    if (todayReading == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('오늘의 말씀')),
        body: const EmptyStateWidget(
          icon: Icons.menu_book_outlined,
          title: '읽기 플랜이 없어요',
          subtitle: '홈에서 읽기 플랜을 설정해주세요',
        ),
      );
    }

    final rangeText = _bibleService.formatReadingRange(todayReading);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(rangeText),
        actions: [
          if (provider.isTodayReadingComplete)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const StatusChip(label: '완료', isActive: true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // 오늘의 말씀 헤더
                _buildReadingHeader(rangeText),
                // 성경 본문
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: _verses.length,
                    itemBuilder: (context, index) {
                      final verse = _verses[index];
                      final showChapterHeader = index == 0 ||
                          _verses[index - 1].bookCode != verse.bookCode ||
                          _verses[index - 1].chapter != verse.chapter;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showChapterHeader) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 12),
                                child: Text(
                                  '${BibleConstants.getBookName(verse.bookCode)} ${verse.chapter}장',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${verse.verse}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    verse.content,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      height: 1.8,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // 하단 완료 버튼
                _buildBottomButton(provider),
              ],
            ),
    );
  }

  Widget _buildReadingHeader(String rangeText) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softMint,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.menu_book, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 말씀',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  rangeText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Text(
            '${_verses.length}절',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: provider.isTodayReadingComplete
          ? PrimaryButton(
              text: '말씀 나누기로 이동',
              onPressed: () => Navigator.pushReplacement(
                context,
                SharedAxisPageRoute(builder: (_) => const ReflectionScreen()),
              ),
              icon: Icons.chat_bubble_outline,
            )
          : PrimaryButton(
              text: '읽기 완료',
              onPressed: _hasScrolledToEnd ? _markComplete : null,
              isLoading: provider.isLoading,
              icon: Icons.check_circle_outline,
            ),
    );
  }
}
