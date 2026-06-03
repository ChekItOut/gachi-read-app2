import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../data/services/bible_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/models/app_models.dart';
import '../../widgets/common_widgets.dart';

class FreeBibleScreen extends StatefulWidget {
  const FreeBibleScreen({super.key});

  @override
  State<FreeBibleScreen> createState() => FreeBibleScreenState();
}

class FreeBibleScreenState extends State<FreeBibleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 외부에서 특정 book/chapter/verse로 이동
  void navigateTo(String bookCode, int chapter, {int? startVerse}) {
    _tabController.animateTo(0);
    // 탭 전환 후 상태가 준비된 시점에 navigateTo 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readerKey.currentState?.navigateTo(bookCode, chapter, startVerse: startVerse);
    });
  }

  final GlobalKey<_BibleReaderTabState> _readerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 300),
                reverse: _tabController.index == 0,
                transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                  return SharedAxisTransition(
                    animation: primaryAnimation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_tabController.index),
                  child: _tabController.index == 0
                      ? _BibleReaderTab(
                          key: _readerKey,
                          tabController: _tabController,
                        )
                      : _SavedVersesTab(
                          onNavigateToVerse: (bookCode, chapter, startVerse) {
                            navigateTo(bookCode, chapter, startVerse: startVerse);
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 0),
      child: Column(
        children: [
          Center(
            child: Text(
              '성경',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 24),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.primaryText,
            unselectedLabelColor: AppColors.secondaryText,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            dividerColor: AppColors.divider,
            tabs: const [
              Tab(text: '성경 읽기'),
              Tab(text: '저장한 구절'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 성경 읽기 탭 ────────────────────────────────────────────────────────────
class _BibleReaderTab extends StatefulWidget {
  final TabController tabController;
  const _BibleReaderTab({super.key, required this.tabController});

  @override
  State<_BibleReaderTab> createState() => _BibleReaderTabState();
}

class _BibleReaderTabState extends State<_BibleReaderTab> {
  final BibleService _bibleService = BibleService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;

  String _selectedBook = '창';
  int _selectedChapter = 1;
  List<BibleVerse> _verses = [];
  bool _isLoading = true;
  Set<String> _savedVerseKeys = {};
  StreamSubscription? _savedVersesSub;
  final ScrollController _scrollController = ScrollController();
  int? _pendingScrollToVerse;

  // 드래그 선택 상태
  int? _dragStartIdx;
  int? _dragEndIdx;
  bool _isDragging = false;

  Set<int> get _selectedIndices {
    if (_dragStartIdx == null) return {};
    final start = _dragStartIdx! < (_dragEndIdx ?? _dragStartIdx!)
        ? _dragStartIdx!
        : (_dragEndIdx ?? _dragStartIdx!);
    final end = _dragStartIdx! > (_dragEndIdx ?? _dragStartIdx!)
        ? _dragStartIdx!
        : (_dragEndIdx ?? _dragStartIdx!);
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
  void initState() {
    super.initState();
    _loadChapter();
    _loadSavedVerses();
  }

  @override
  void dispose() {
    _savedVersesSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void navigateTo(String bookCode, int chapter, {int? startVerse}) {
    _pendingScrollToVerse = startVerse;
    setState(() {
      _selectedBook = bookCode;
      _selectedChapter = chapter;
    });
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() => _isLoading = true);
    await _bibleService.loadBible();
    final verses = _bibleService.getChapter(_selectedBook, _selectedChapter);
    setState(() {
      _verses = verses;
      _isLoading = false;
      _dragStartIdx = null;
      _dragEndIdx = null;
      _isDragging = false;
    });

    // 특정 절로 스크롤
    if (_pendingScrollToVerse != null && verses.isNotEmpty) {
      final targetVerse = _pendingScrollToVerse!;
      _pendingScrollToVerse = null;
      // 절 번호에 해당하는 인덱스 찾기
      final targetIndex = verses.indexWhere((v) => v.verse >= targetVerse);
      if (targetIndex >= 0) {
        // 프레임 렌더링 후 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            // 각 아이템 높이를 약 52px로 추정하여 스크롤 위치 계산
            final estimatedOffset = targetIndex * 52.0;
            _scrollController.animateTo(
              estimatedOffset.clamp(0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  Future<void> _loadSavedVerses() async {
    final user = _firebaseService.currentUser;
    if (user == null) return;
    _savedVersesSub = _firebaseService.watchSavedVerses(user.uid).listen((verses) {
      if (mounted) {
        setState(() {
          _savedVerseKeys = verses
              .map((v) => '${v.bookCode}${v.chapter}:${v.verse}')
              .toSet();
        });
      }
    });
  }

  void _navigateChapter(int direction) {
    Map<String, dynamic>? next;
    if (direction > 0) {
      next = _bibleService.getNextChapter(_selectedBook, _selectedChapter);
    } else {
      next = _bibleService.getPrevChapter(_selectedBook, _selectedChapter);
    }
    if (next != null) {
      setState(() {
        _selectedBook = next!['bookCode'];
        _selectedChapter = next['chapter'];
      });
      _loadChapter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookName = BibleConstants.getBookName(_selectedBook);
    final totalChapters = _bibleService.getChapterCount(_selectedBook);
    final selected = _selectedIndices;

    return Column(
      children: [
        // 책/장 선택 헤더
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => _showBookSelector(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(children: [
                  Text(
                    '$bookName $_selectedChapter장',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.primary, size: 18),
                ]),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _selectedChapter > 1
                  ? () => _navigateChapter(-1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              color: AppColors.primary,
            ),
            Text('$_selectedChapter / $totalChapters',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.secondaryText)),
            IconButton(
              onPressed: _selectedChapter < totalChapters
                  ? () => _navigateChapter(1)
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
            onSave: () => _showSaveDialog(selected.toList()..sort()),
            onClear: _clearSelection,
          ),

        // 사용 안내 (선택 없을 때)
        if (selected.isEmpty)
          Container(
            color: const Color(0xFFFFF8E1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : GestureDetector(
                  onTap: selected.isNotEmpty ? _clearSelection : null,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _verses.length,
                    itemBuilder: (context, index) {
                      final verse = _verses[index];
                      final isSelected = selected.contains(index);
                      final isDragStart = _dragStartIdx == index;
                      final isSaved = _savedVerseKeys.contains(
                          '${verse.bookCode}${verse.chapter}:${verse.verse}');

                      return _VerseItem(
                        index: index,
                        verseNum: verse.verse,
                        content: verse.content,
                        isSelected: isSelected,
                        isDragStart: isDragStart,
                        isSaved: isSaved,
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _dragStartIdx = index;
                            _dragEndIdx = index;
                            _isDragging = true;
                          });
                        },
                        onTap: () {
                          if (selected.isNotEmpty) {
                            setState(() {
                              if (_dragStartIdx == null) {
                                _dragStartIdx = index;
                                _dragEndIdx = index;
                              } else {
                                if (index < _dragStartIdx!) {
                                  _dragStartIdx = index;
                                } else if (index > (_dragEndIdx ?? _dragStartIdx!)) {
                                  _dragEndIdx = index;
                                } else {
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

  // 저장 바텀시트 (demo 스타일)
  void _showSaveDialog(List<int> selectedIndices) {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    final bookName = BibleConstants.getBookName(_selectedBook);
    final selectedVerses = selectedIndices.map((i) => _verses[i]).toList();
    final firstVerse = selectedVerses.first.verse;
    final lastVerse = selectedVerses.last.verse;

    final reference = selectedVerses.length == 1
        ? '$bookName ${_selectedChapter}장 ${firstVerse}절'
        : '$bookName ${_selectedChapter}장 ${firstVerse}~${lastVerse}절';

    final content = selectedVerses
        .map((v) => '${v.verse}. ${v.content}')
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 참조 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                reference,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 내용 미리보기 (최대 4절)
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
                            .map((v) => '${v.verse}. ${v.content}')
                            .join('\n') +
                        '\n... (${selectedVerses.length - 4}절 더)'
                    : content,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: '구절 저장하기',
              onPressed: () async {
                // Firebase에 각 구절 저장
                for (final verse in selectedVerses) {
                  await _firebaseService.saveVerse(SavedVerse(
                    id: '',
                    userId: user.uid,
                    bookCode: _selectedBook,
                    chapter: _selectedChapter,
                    verse: verse.verse,
                    content: verse.content,
                    savedAt: DateTime.now(),
                  ));
                }
                if (mounted) {
                  Navigator.pop(context);
                  _clearSelection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$reference 저장되었어요'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              icon: Icons.bookmark_add_outlined,
            ),
          ],
        ),
      ),
    );
  }

  // 책/장 선택기 바텀시트
  Future<void> _showBookSelector() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookSelectorSheet(
        selectedBook: _selectedBook,
        selectedChapter: _selectedChapter,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedBook = result['book'];
        _selectedChapter = result['chapter'];
      });
      _loadChapter();
    }
  }
}

// ─── 구절 아이템 위젯 ─────────────────────────────────────────────────────────
class _VerseItem extends StatelessWidget {
  final int index;
  final int verseNum;
  final String content;
  final bool isSelected;
  final bool isDragStart;
  final bool isSaved;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final Function(int) onExtendSelection;

  const _VerseItem({
    required this.index,
    required this.verseNum,
    required this.content,
    required this.isSelected,
    required this.isDragStart,
    required this.isSaved,
    required this.onLongPress,
    required this.onTap,
    required this.onExtendSelection,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
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
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4), width: 1.5)
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSaved)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.bookmark, size: 16, color: AppColors.primary),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
  final void Function(String bookCode, int chapter, int startVerse) onNavigateToVerse;

  const _SavedVersesTab({required this.onNavigateToVerse});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다'));
    }

    return StreamBuilder<List<SavedVerse>>(
      stream: FirebaseService.instance.watchSavedVerses(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('데이터를 불러올 수 없습니다\n${snapshot.error}',
                textAlign: TextAlign.center),
          );
        }

        final verses = snapshot.data ?? [];
        if (verses.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.bookmark_border,
            title: '저장된 구절이 없어요',
            subtitle: '성경을 읽다가 마음에 드는 구절을\n길게 눌러서 선택하고 저장해보세요',
          );
        }

        // book+chapter 기준으로 그룹화하여 reference 문자열 생성
        final groupedItems = _buildGroupedItems(verses);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: groupedItems.length,
          itemBuilder: (context, index) {
            final item = groupedItems[index];
            return _SavedVerseItem(
              reference: item.reference,
              content: item.content,
              onTap: () {
                onNavigateToVerse(
                  item.bookCode,
                  item.chapter,
                  item.verses.first.verse,
                );
              },
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('구절 삭제'),
                    content: Text('${item.reference}을(를) 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('삭제',
                            style: TextStyle(color: AppColors.warning)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirebaseService.instance.deleteVersesByGroup(
                    user.uid,
                    item.bookCode,
                    item.chapter,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  // 그룹화된 아이템 생성
  List<_GroupedVerseData> _buildGroupedItems(List<SavedVerse> verses) {
    final Map<String, _GroupedVerseData> groupMap = {};

    for (final verse in verses) {
      final key = '${verse.bookCode}_${verse.chapter}';
      if (groupMap.containsKey(key)) {
        groupMap[key]!.verses.add(verse);
      } else {
        groupMap[key] = _GroupedVerseData(
          bookCode: verse.bookCode,
          chapter: verse.chapter,
          verses: [verse],
        );
      }
    }

    // 각 그룹 내 구절을 절 번호순으로 정렬 후 reference/content 생성
    for (final group in groupMap.values) {
      group.verses.sort((a, b) => a.verse.compareTo(b.verse));
      final bookName = BibleConstants.getBookName(group.bookCode);
      final first = group.verses.first.verse;
      final last = group.verses.last.verse;
      group.reference = group.verses.length == 1
          ? '$bookName ${group.chapter}장 ${first}절'
          : '$bookName ${group.chapter}장 ${first}~${last}절';
      group.content = group.verses
          .map((v) => '${v.verse}. ${v.content}')
          .join('\n');
    }

    return groupMap.values.toList();
  }
}

class _GroupedVerseData {
  final String bookCode;
  final int chapter;
  final List<SavedVerse> verses;
  String reference = '';
  String content = '';

  _GroupedVerseData({
    required this.bookCode,
    required this.chapter,
    required this.verses,
  });
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
          // 제목 행
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isExpanded ? AppColors.primary : AppColors.softMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.bookmark : Icons.bookmark_border,
                    color: _isExpanded ? Colors.white : AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
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
                      Text(
                        widget.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
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

// ─── 책 선택 바텀시트 ────────────────────────────────────────────────────────
class _BookSelectorSheet extends StatefulWidget {
  final String selectedBook;
  final int selectedChapter;

  const _BookSelectorSheet({
    required this.selectedBook,
    required this.selectedChapter,
  });

  @override
  State<_BookSelectorSheet> createState() => _BookSelectorSheetState();
}

class _BookSelectorSheetState extends State<_BookSelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedBook;
  final BibleService _bibleService = BibleService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedBook = widget.selectedBook;

    if (BibleConstants.newTestamentCodes.contains(widget.selectedBook)) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '성경 선택',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.primary, width: 3),
                insets: EdgeInsets.symmetric(horizontal: 24),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primaryText,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              dividerColor: AppColors.divider,
              tabs: const [
                Tab(text: '구약'),
                Tab(text: '신약'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSplitPanel(BibleConstants.oldTestamentCodes),
                _buildSplitPanel(BibleConstants.newTestamentCodes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPanel(List<String> books) {
    final activeBook = books.contains(_selectedBook) ? _selectedBook : books.first;
    final chapterCount = _bibleService.getChapterCount(activeBook);

    return Row(
      children: [
        Expanded(
          flex: 55,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isSelected = book == activeBook;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedBook = book);
                },
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.softMint : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    BibleConstants.getBookName(book),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 45,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              itemCount: chapterCount,
              itemBuilder: (context, index) {
                final chapter = index + 1;
                final isCurrentChapter = activeBook == widget.selectedBook &&
                    chapter == widget.selectedChapter;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, {'book': activeBook, 'chapter': chapter});
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: isCurrentChapter ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$chapter장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentChapter ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrentChapter ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
