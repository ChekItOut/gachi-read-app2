import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../data/services/bible_service.dart';
import '../../providers/demo_provider.dart';
import '../../widgets/common_widgets.dart';

class DemoBibleScreen extends StatefulWidget {
  const DemoBibleScreen({super.key});

  @override
  State<DemoBibleScreen> createState() => _DemoBibleScreenState();
}

class _DemoBibleScreenState extends State<DemoBibleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('성경'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: '성경 읽기'),
            Tab(text: '저장한 구절'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BibleReaderTab(),
          _SavedVersesTab(),
        ],
      ),
    );
  }
}

class _BibleReaderTab extends StatefulWidget {
  const _BibleReaderTab();

  @override
  State<_BibleReaderTab> createState() => _BibleReaderTabState();
}

class _BibleReaderTabState extends State<_BibleReaderTab> {
  int? _selectedVerseIdx;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();
    final book = provider.freeBibleBook;
    final chapter = provider.freeBibleChapter;
    final bookName = BibleConstants.getBookName(book);
    final verses = BibleService.instance.getVerses(book, chapter);
    final totalChapters = BibleService.instance.getChapterCount(book);

    return Column(
      children: [
        // 책/장 선택 헤더
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => _showBookChapterPicker(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(children: [
                  Text(
                    '$bookName $chapter장',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.primary, size: 18),
                ]),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: chapter > 1
                  ? () => provider.goToPrevChapter()
                  : null,
              icon: const Icon(Icons.chevron_left),
              color: AppColors.primary,
            ),
            Text('$chapter / $totalChapters',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.secondaryText)),
            IconButton(
              onPressed: chapter < totalChapters
                  ? () => provider.goToNextChapter()
                  : null,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.primary,
            ),
          ]),
        ),

        // 구절 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              final verseNum = verse['verse'] as int;
              final content = verse['content'] as String;
              final isSelected = _selectedVerseIdx == index;

              return GestureDetector(
                onLongPress: () {
                  setState(() => _selectedVerseIdx = index);
                  _showSaveDialog(context, provider, book, chapter,
                      verseNum, content);
                },
                onTap: () {
                  if (_selectedVerseIdx != null) {
                    setState(() => _selectedVerseIdx = null);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$verseNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.secondaryText,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: isSelected
                                ? AppColors.primaryText
                                : AppColors.primaryText,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context, DemoProvider provider,
      String book, int chapter, int verse, String content) {
    final bookName = BibleConstants.getBookName(book);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$bookName $chapter:$verse',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            Text(content,
                style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 20),
            PrimaryButton(
              text: '구절 저장하기',
              onPressed: () {
                provider.saveVerse(book, chapter, verse, content);
                Navigator.pop(context);
                setState(() => _selectedVerseIdx = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('구절이 저장되었어요 📖'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: Icons.bookmark_add_outlined,
            ),
          ],
        ),
      ),
    );
  }

  void _showBookChapterPicker(
      BuildContext context, DemoProvider provider) {
    final books = BibleConstants.bookOrder;
    String selectedBook = provider.freeBibleBook;
    int selectedChapter = provider.freeBibleChapter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
              Text('성경 선택',
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Expanded(
                child: Row(children: [
                  // 책 목록
                  Expanded(
                    child: ListView.builder(
                      itemCount: books.length,
                      itemBuilder: (_, i) {
                        final b = books[i];
                        final isSelected = b == selectedBook;
                        return GestureDetector(
                          onTap: () => setModalState(() {
                            selectedBook = b;
                            selectedChapter = 1;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.softMint
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Text(
                              BibleConstants.getBookName(b),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.primaryText,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // 장 목록
                  Expanded(
                    child: Builder(builder: (ctx) {
                      final total = BibleService.instance
                          .getChapterCount(selectedBook);
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: total,
                        itemBuilder: (_, i) {
                          final ch = i + 1;
                          final isSel = ch == selectedChapter;
                          return GestureDetector(
                            onTap: () => setModalState(
                                () => selectedChapter = ch),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.chipBackground,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$ch',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : AppColors.primaryText,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: '이동하기',
                onPressed: () {
                  provider.setFreeBiblePosition(
                      selectedBook, selectedChapter);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedVersesTab extends StatelessWidget {
  const _SavedVersesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();
    final verses = provider.savedVerses;

    if (verses.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.bookmark_border,
        title: '저장된 구절이 없어요',
        subtitle: '성경을 읽다가 마음에 드는 구절을\n길게 눌러서 저장해보세요',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AppCard(
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
                    child: Text(
                      verse['reference'] as String,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => provider
                        .deleteVerse(verse['reference'] as String),
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.secondaryText,
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  verse['content'] as String,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
