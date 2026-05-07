import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../data/services/bible_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/models/app_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class FreeBibleScreen extends StatefulWidget {
  const FreeBibleScreen({super.key});

  @override
  State<FreeBibleScreen> createState() => _FreeBibleScreenState();
}

class _FreeBibleScreenState extends State<FreeBibleScreen> {
  final BibleService _bibleService = BibleService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;

  String _selectedBook = '창';
  int _selectedChapter = 1;
  List<BibleVerse> _verses = [];
  bool _isLoading = true;
  Set<int> _selectedVerses = {};
  Set<String> _savedVerseKeys = {};

  @override
  void initState() {
    super.initState();
    _loadChapter();
    _loadSavedVerses();
  }

  Future<void> _loadChapter() async {
    setState(() => _isLoading = true);
    await _bibleService.loadBible();
    final verses = _bibleService.getChapter(_selectedBook, _selectedChapter);
    setState(() {
      _verses = verses;
      _isLoading = false;
      _selectedVerses.clear();
    });
  }

  Future<void> _loadSavedVerses() async {
    final user = _firebaseService.currentUser;
    if (user == null) return;
    // 저장된 구절 키 로드
    _firebaseService.watchSavedVerses(user.uid).listen((verses) {
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

  Future<void> _saveSelectedVerses() async {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    for (final verseNum in _selectedVerses) {
      final verse = _verses.firstWhere((v) => v.verse == verseNum);
      await _firebaseService.saveVerse(SavedVerse(
        id: '',
        userId: user.uid,
        bookCode: _selectedBook,
        chapter: _selectedChapter,
        verse: verseNum,
        content: verse.content,
        savedAt: DateTime.now(),
      ));
    }

    setState(() => _selectedVerses.clear());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('구절이 저장되었습니다'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showBookSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${BibleConstants.getBookName(_selectedBook)} $_selectedChapter장',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
        actions: [
          if (_selectedVerses.isNotEmpty)
            TextButton.icon(
              onPressed: _saveSelectedVerses,
              icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.primary),
              label: Text(
                '저장 (${_selectedVerses.length})',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedVersesScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 챕터 네비게이션
          _buildChapterNav(),
          // 성경 본문
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildVerseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: () => _navigateChapter(-1),
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.chipBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${BibleConstants.getBookName(_selectedBook)} $_selectedChapter장',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _navigateChapter(1),
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.chipBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verse = _verses[index];
        final isSelected = _selectedVerses.contains(verse.verse);
        final isSaved = _savedVerseKeys.contains('${verse.bookCode}${verse.chapter}:${verse.verse}');

        return GestureDetector(
          onLongPress: () {
            setState(() {
              if (isSelected) {
                _selectedVerses.remove(verse.verse);
              } else {
                _selectedVerses.add(verse.verse);
              }
            });
          },
          onTap: () {
            if (_selectedVerses.isNotEmpty) {
              setState(() {
                if (isSelected) {
                  _selectedVerses.remove(verse.verse);
                } else {
                  _selectedVerses.add(verse.verse);
                }
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${verse.verse}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.secondaryText,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    verse.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: AppColors.primaryText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSaved)
                  const Icon(Icons.bookmark, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 책 선택 바텀시트
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
  String? _selectedBook;
  final BibleService _bibleService = BibleService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedBook = widget.selectedBook;

    // 현재 선택된 책이 구약인지 신약인지 확인
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
          // 핸들
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
          // 탭바
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                _buildBookList(BibleConstants.oldTestamentCodes),
                _buildBookList(BibleConstants.newTestamentCodes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(List<String> books) {
    if (_selectedBook != null && books.contains(_selectedBook)) {
      // 챕터 선택 화면
      return _buildChapterSelector(_selectedBook!);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = book == _selectedBook;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedBook = book);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.chipBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              BibleConstants.getBookName(book),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterSelector(String book) {
    final chapterCount = _bibleService.getChapterCount(book);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedBook = null),
                icon: const Icon(Icons.arrow_back_ios, size: 18),
              ),
              Text(
                BibleConstants.getBookName(book),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: chapterCount,
            itemBuilder: (context, index) {
              final chapter = index + 1;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context, {'book': book, 'chapter': chapter});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.chipBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$chapter',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// 저장된 구절 화면
class SavedVersesScreen extends StatelessWidget {
  const SavedVersesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('저장한 구절'),
      ),
      body: StreamBuilder<List<SavedVerse>>(
        stream: FirebaseService.instance.watchSavedVerses(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final verses = snapshot.data ?? [];
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.softMint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              verse.reference,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () async {
                              await FirebaseService.instance.deleteVerse(verse.id);
                            },
                            icon: const Icon(Icons.close, size: 18),
                            color: AppColors.secondaryText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
