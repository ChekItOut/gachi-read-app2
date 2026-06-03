import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../data/services/bible_service.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class ReadingPlanScreen extends StatefulWidget {
  final bool isEditMode;
  const ReadingPlanScreen({super.key, this.isEditMode = false});

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  final BibleService _bibleService = BibleService.instance;

  String _selectedBook = '창';
  int _selectedChapter = 1;
  int _selectedStartVerse = 1;
  bool _isChapterMode = true; // true: 장 단위, false: 절 단위
  int _dailyChapters = 1;
  int _dailyVerses = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bibleService.loadBible();

    // 편집 모드일 때 기존 플랜 값으로 초기화
    if (widget.isEditMode) {
      final plan = context.read<AppProvider>().readingPlan;
      if (plan != null) {
        _selectedBook = plan.startBook;
        _selectedChapter = plan.startChapter;
        _selectedStartVerse = plan.startVerse;
        _isChapterMode = plan.dailyChapters > 0;
        _dailyChapters = plan.dailyChapters > 0 ? plan.dailyChapters : 1;
        _dailyVerses = plan.dailyVerses > 0 ? plan.dailyVerses : 5;
      }
    }
  }

  Future<void> _savePlan() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      if (widget.isEditMode) {
        await provider.updateReadingPlan(
          startBook: _selectedBook,
          startChapter: _selectedChapter,
          startVerse: _selectedStartVerse,
          dailyChapters: _isChapterMode ? _dailyChapters : 0,
          dailyVerses: _isChapterMode ? 0 : _dailyVerses,
        );
      } else {
        await provider.createReadingPlan(
          startBook: _selectedBook,
          startChapter: _selectedChapter,
          startVerse: _selectedStartVerse,
          dailyChapters: _isChapterMode ? _dailyChapters : 0,
          dailyVerses: _isChapterMode ? 0 : _dailyVerses,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode ? '읽기 플랜이 수정되었습니다!' : '읽기 플랜이 설정되었습니다!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: AppColors.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.isEditMode ? '읽기 플랜 수정' : '읽기 플랜 설정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시작 위치 설정
            _buildSectionTitle('시작 위치'),
            const SizedBox(height: 12),
            _buildStartPositionCard(),
            const SizedBox(height: 24),

            // 읽기 단위 설정
            _buildSectionTitle('읽기 단위'),
            const SizedBox(height: 12),
            _buildReadingUnitCard(),
            const SizedBox(height: 24),

            // 미리보기
            _buildSectionTitle('플랜 미리보기'),
            const SizedBox(height: 12),
            _buildPreviewCard(),
            const SizedBox(height: 32),

            // 저장 버튼
            PrimaryButton(
              text: widget.isEditMode ? '플랜 수정하기' : '플랜 저장하기',
              onPressed: _savePlan,
              isLoading: _isLoading,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildStartPositionCard() {
    return AppCard(
      child: Column(
        children: [
          // 책 선택
          _buildSelectRow(
            icon: Icons.book_outlined,
            label: '성경 책',
            value: BibleConstants.getBookName(_selectedBook),
            onTap: _showBookPicker,
          ),
          const SizedBox(height: 16),
          const AppDivider(),
          const SizedBox(height: 16),
          // 장 선택
          _buildSelectRow(
            icon: Icons.format_list_numbered,
            label: '시작 장',
            value: '$_selectedChapter장',
            onTap: _showChapterPicker,
          ),
          const SizedBox(height: 16),
          const AppDivider(),
          const SizedBox(height: 16),
          // 절 선택
          _buildSelectRow(
            icon: Icons.format_indent_increase,
            label: '시작 절',
            value: '$_selectedStartVerse절',
            onTap: _showVersePicker,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          IconBox(icon: icon, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.secondaryText),
        ],
      ),
    );
  }

  Widget _buildReadingUnitCard() {
    return AppCard(
      child: Column(
        children: [
          // 모드 선택
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isChapterMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isChapterMode ? AppColors.primary : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '장 단위',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isChapterMode ? Colors.white : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isChapterMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: !_isChapterMode ? AppColors.primary : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '절 단위',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: !_isChapterMode ? Colors.white : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 수량 설정 (전환 애니메이션)
          PageTransitionSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return SharedAxisTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.vertical,
                child: child,
              );
            },
            child: _isChapterMode
                ? KeyedSubtree(
                    key: const ValueKey('chapter'),
                    child: Column(
                      children: [
                        Text(
                          '하루 몇 장씩 읽을까요?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildCountSelector(
                          value: _dailyChapters,
                          min: 1,
                          max: 10,
                          unit: '장',
                          onChanged: (v) => setState(() => _dailyChapters = v),
                        ),
                      ],
                    ),
                  )
                : KeyedSubtree(
                    key: const ValueKey('verse'),
                    child: Column(
                      children: [
                        Text(
                          '하루 몇 절씩 읽을까요?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildCountSelector(
                          value: _dailyVerses,
                          min: 1,
                          max: 50,
                          unit: '절',
                          onChanged: (v) => setState(() => _dailyVerses = v),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountSelector({
    required int value,
    required int min,
    required int max,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          iconSize: 32,
          color: AppColors.primary,
        ),
        const SizedBox(width: 20),
        Text(
          '$value$unit',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(width: 20),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final bookName = BibleConstants.getBookName(_selectedBook);
    final unitText = _isChapterMode
        ? '하루 $_dailyChapters장씩'
        : '하루 $_dailyVerses절씩';

    return SoftCard(
      backgroundColor: AppColors.softMint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '플랜 요약',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewRow('시작 위치', '$bookName $_selectedChapter:$_selectedStartVerse'),
          const SizedBox(height: 8),
          _buildPreviewRow('읽기 방식', unitText),
          const SizedBox(height: 8),
          _buildPreviewRow('시작일', '오늘부터'),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  void _showBookPicker() async {
    final books = BibleConstants.allBookCodes;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SimpleBookPicker(books: books),
    );
    if (result != null) {
      setState(() {
        _selectedBook = result;
        _selectedChapter = 1;
        _selectedStartVerse = 1;
      });
    }
  }

  void _showChapterPicker() async {
    final chapterCount = _bibleService.getChapterCount(_selectedBook);
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NumberPickerSheet(
        title: '시작 장 선택',
        count: chapterCount,
        unit: '장',
        selected: _selectedChapter,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedChapter = result;
        _selectedStartVerse = 1;
      });
    }
  }

  void _showVersePicker() async {
    final verseCount = _bibleService.getVerseCount(_selectedBook, _selectedChapter);
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NumberPickerSheet(
        title: '시작 절 선택',
        count: verseCount,
        unit: '절',
        selected: _selectedStartVerse,
      ),
    );
    if (result != null) {
      setState(() => _selectedStartVerse = result);
    }
  }
}

class _SimpleBookPicker extends StatefulWidget {
  final List<String> books;
  const _SimpleBookPicker({required this.books});

  @override
  State<_SimpleBookPicker> createState() => _SimpleBookPickerState();
}

class _SimpleBookPickerState extends State<_SimpleBookPicker>
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
          Text('성경 책 선택', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
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
              tabs: const [Tab(text: '구약'), Tab(text: '신약')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(BibleConstants.oldTestamentCodes),
                _buildGrid(BibleConstants.newTestamentCodes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<String> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () => Navigator.pop(context, book),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              BibleConstants.getBookName(book),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
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
}

class _NumberPickerSheet extends StatelessWidget {
  final String title;
  final int count;
  final String unit;
  final int selected;

  const _NumberPickerSheet({
    required this.title,
    required this.count,
    required this.unit,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: count,
              itemBuilder: (context, index) {
                final num = index + 1;
                final isSelected = num == selected;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, num),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.chipBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$num',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
