import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        children: [
          _BibleReaderTab(tabController: _tabController),
          const _SavedVersesTab(),
        ],
      ),
    );
  }
}

// ─── 성경 읽기 탭 ────────────────────────────────────────────────────────────
class _BibleReaderTab extends StatefulWidget {
  final TabController tabController;
  const _BibleReaderTab({required this.tabController});

  @override
  State<_BibleReaderTab> createState() => _BibleReaderTabState();
}

class _BibleReaderTabState extends State<_BibleReaderTab> {
  // 드래그 선택 상태
  int? _dragStartIdx;
  int? _dragEndIdx;
  bool _isDragging = false;

  Set<int> get _selectedIndices {
    if (_dragStartIdx == null) return {};
    final start =
        _dragStartIdx! < (_dragEndIdx ?? _dragStartIdx!) ? _dragStartIdx! : (_dragEndIdx ?? _dragStartIdx!);
    final end =
        _dragStartIdx! > (_dragEndIdx ?? _dragStartIdx!) ? _dragStartIdx! : (_dragEndIdx ?? _dragStartIdx!);
    return Set.from(List.generate(end - start + 1, (i) => start + i));
  }

  void _clearSelection() {
    setState(() {
      _dragStartIdx = null;
      _dragEndIdx = null;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();
    final book = provider.freeBibleBook;
    final chapter = provider.freeBibleChapter;
    final bookName = BibleConstants.getBookName(book);
    final verses = BibleService.instance.getVerses(book, chapter);
    final totalChapters = BibleService.instance.getChapterCount(book);
    final selected = _selectedIndices;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onPressed:
                  chapter > 1 ? () => provider.goToPrevChapter() : null,
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

        // 선택 중 안내 배너
        if (selected.isNotEmpty)
          _SelectionBanner(
            selectedCount: selected.length,
            onSave: () => _showSaveDialog(context, provider, book, chapter,
                verses, selected.toList()..sort()),
            onClear: _clearSelection,
          ),

        // 사용 안내 (선택 없을 때)
        if (selected.isEmpty)
          Container(
            color: const Color(0xFFFFF8E1),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(Icons.touch_app_outlined,
                  size: 14, color: Color(0xFFF9A825)),
              const SizedBox(width: 6),
              Text(
                '구절을 길게 눌러 선택 시작 · 드래그로 여러 절 선택',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF795548)),
              ),
            ]),
          ),

        // 구절 목록
        Expanded(
          child: GestureDetector(
            // 빈 공간 탭 시 선택 해제
            onTap: selected.isNotEmpty ? _clearSelection : null,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                final verseNum = verse['verse'] as int;
                final content = verse['content'] as String;
                final isSelected = selected.contains(index);
                final isDragStart = _dragStartIdx == index;

                return _VerseItem(
                  index: index,
                  verseNum: verseNum,
                  content: content,
                  isSelected: isSelected,
                  isDragStart: isDragStart,
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _dragStartIdx = index;
                      _dragEndIdx = index;
                      _isDragging = true;
                    });
                  },
                  onDragUpdate: (details) {
                    if (!_isDragging) return;
                    // RenderBox를 통해 현재 드래그 위치의 아이템 인덱스 계산
                    // 간단한 방법: 포지션 기반으로 인덱스 추정
                  },
                  onTap: () {
                    if (selected.isNotEmpty) {
                      // 선택 모드에서 탭: 해당 절 토글
                      setState(() {
                        if (_dragStartIdx == null) {
                          _dragStartIdx = index;
                          _dragEndIdx = index;
                        } else {
                          // 범위 확장
                          if (index < _dragStartIdx!) {
                            _dragStartIdx = index;
                          } else if (index > (_dragEndIdx ?? _dragStartIdx!)) {
                            _dragEndIdx = index;
                          } else {
                            // 이미 선택된 범위 내 탭 → 해제
                            _clearSelection();
                          }
                        }
                      });
                    }
                  },
                  onExtendSelection: (idx) {
                    if (_isDragging || _dragStartIdx != null) {
                      setState(() => _dragEndIdx = idx);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showSaveDialog(
    BuildContext context,
    DemoProvider provider,
    String book,
    int chapter,
    List<Map<String, dynamic>> allVerses,
    List<int> selectedIndices,
  ) {
    final bookName = BibleConstants.getBookName(book);
    final selectedVerses =
        selectedIndices.map((i) => allVerses[i]).toList();
    final firstVerse = selectedVerses.first['verse'] as int;
    final lastVerse = selectedVerses.last['verse'] as int;

    // 참조 텍스트
    final reference = selectedVerses.length == 1
        ? '$bookName ${chapter}장 ${firstVerse}절'
        : '$bookName ${chapter}장 ${firstVerse}~${lastVerse}절';

    // 전체 내용 합치기
    final content = selectedVerses
        .map((v) => '${v['verse']}. ${v['content']}')
        .join('\n');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            // 참조
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(reference,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            // 내용 미리보기 (최대 4절까지)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                selectedVerses.length > 4
                    ? selectedVerses
                            .take(4)
                            .map((v) => '${v['verse']}. ${v['content']}')
                            .join('\n') +
                        '\n... (${selectedVerses.length - 4}절 더)'
                    : content,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: '구절 저장하기',
              onPressed: () {
                provider.saveVerseGroup(
                  book: book,
                  chapter: chapter,
                  startVerse: firstVerse,
                  endVerse: lastVerse,
                  reference: reference,
                  content: content,
                );
                Navigator.pop(context);
                _clearSelection();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$reference 저장되었어요 📖'),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                              borderRadius: BorderRadius.circular(10),
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
                            onTap: () =>
                                setModalState(() => selectedChapter = ch),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.chipBackground,
                                borderRadius: BorderRadius.circular(8),
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

// ─── 구절 아이템 위젯 ─────────────────────────────────────────────────────────
class _VerseItem extends StatelessWidget {
  final int index;
  final int verseNum;
  final String content;
  final bool isSelected;
  final bool isDragStart;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final Function(Map) onDragUpdate;
  final Function(int) onExtendSelection;

  const _VerseItem({
    required this.index,
    required this.verseNum,
    required this.content,
    required this.isSelected,
    required this.isDragStart,
    required this.onLongPress,
    required this.onTap,
    required this.onDragUpdate,
    required this.onExtendSelection,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      // 드래그 진입 감지: 다른 절 위로 드래그 시 선택 확장
      onVerticalDragUpdate: (details) {
        onExtendSelection(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isDragStart
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택 인디케이터
            SizedBox(
              width: 28,
              child: isSelected
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$verseNum',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      '$verseNum',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondaryText,
                      ),
                    ),
            ),
            Expanded(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: AppColors.primaryText,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 선택 배너 ───────────────────────────────────────────────────────────────
class _SelectionBanner extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const _SelectionBanner({
    required this.selectedCount,
    required this.onSave,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        GestureDetector(
          onTap: onClear,
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          '$selectedCount절 선택됨',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSave,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '저장하기',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── 저장한 구절 탭 ───────────────────────────────────────────────────────────
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
        subtitle: '성경을 읽다가 마음에 드는 구절을\n길게 눌러서 선택하고 저장해보세요',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        final reference = verse['reference'] as String;
        final content = verse['content'] as String;
        final bookCode = verse['bookCode'] as String;
        final chapter = verse['chapter'] as int;

        return _SavedVerseItem(
          reference: reference,
          content: content,
          onTap: () {
            // 해당 구절 위치로 이동 후 성경 읽기 탭으로 전환
            provider.setFreeBiblePosition(bookCode, chapter);
            // 부모 TabController에 접근하기 위해 DefaultTabController 사용
            DefaultTabController.of(context).animateTo(0);
          },
          onDelete: () => provider.deleteVerse(reference),
        );
      },
    );
  }
}

// ─── 저장된 구절 아이템 (제목만 표시, 확장 가능) ─────────────────────────────
class _SavedVerseItem extends StatefulWidget {
  final String reference;
  final String content;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedVerseItem({
    required this.reference,
    required this.content,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SavedVerseItem> createState() => _SavedVerseItemState();
}

class _SavedVerseItemState extends State<_SavedVerseItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 제목 행 (항상 표시)
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                // 북마크 아이콘
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isExpanded
                        ? AppColors.primary
                        : AppColors.softMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isExpanded
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _isExpanded ? Colors.white : AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // 참조 텍스트
                Expanded(
                  child: Text(
                    widget.reference,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isExpanded
                          ? AppColors.primary
                          : AppColors.primaryText,
                    ),
                  ),
                ),
                // 확장 화살표
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                ),
              ]),
            ),
          ),

          // 확장 내용 (애니메이션)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 구절 내용
                      Text(
                        widget.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 액션 버튼들
                      Row(children: [
                        // 해당 구절로 이동
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onTap,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.softMint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.open_in_new,
                                      size: 14, color: AppColors.primary),
                                  SizedBox(width: 6),
                                  Text(
                                    '성경에서 보기',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // 삭제
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 14, color: Colors.red),
                                SizedBox(width: 4),
                                Text(
                                  '삭제',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
