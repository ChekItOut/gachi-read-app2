import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../../data/models/app_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadCalendarData(_currentMonth);
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    context.read<AppProvider>().loadCalendarData(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    context.read<AppProvider>().loadCalendarData(_currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                // 캘린더 카드
                AppCard(
                  child: Column(
                    children: [
                      _buildMonthHeader(),
                      const SizedBox(height: 16),
                      _buildWeekdayHeader(),
                      const SizedBox(height: 8),
                      _buildCalendarGrid(provider),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 범례
                _buildLegend(),
                const SizedBox(height: 20),
                // 선택된 날짜 상세
                if (_selectedDate != null)
                  _buildDayDetail(provider),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Text(
        '읽기 기록',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildMonthHeader() {
    final monthStr = DateFormat('yyyy년 M월', 'ko_KR').format(_currentMonth);
    return Row(
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.chipBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Expanded(
          child: Text(
            monthStr,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.chipBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: weekdays.map((day) {
        final isSunday = day == '일';
        final isSaturday = day == '토';
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSunday
                    ? Colors.red.shade300
                    : isSaturday
                        ? Colors.blue.shade300
                        : AppColors.secondaryText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(AppProvider provider) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0=일, 1=월, ...

    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    final calendarData = provider.calendarData;
    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        if (date == null) return const SizedBox();

        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final dayData = calendarData[dateKey];
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected = _selectedDate != null &&
            date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day;
        final isReadingDone = dayData?['readingDone'] == true;
        final isBothDone = dayData?['bothReflectionDone'] == true;
        final isFuture = date.isAfter(today);

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isBothDone
                      ? AppColors.primary.withOpacity(0.15)
                      : isReadingDone
                          ? AppColors.softMint
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isFuture
                            ? AppColors.secondaryText.withOpacity(0.4)
                            : AppColors.primaryText,
                  ),
                ),
                if (isBothDone && !isSelected)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(AppColors.softMint, '읽기 완료'),
        const SizedBox(width: 20),
        _buildLegendItem(AppColors.primary.withOpacity(0.15), '나눔 완료'),
        const SizedBox(width: 20),
        _buildLegendItem(Colors.transparent, '미완료',
            hasBorder: true),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: AppColors.border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
      ],
    );
  }

  Widget _buildDayDetail(AppProvider provider) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final dayData = provider.calendarData[dateKey];
    final dateStr = DateFormat('M월 d일 EEEE', 'ko_KR').format(_selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateStr, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (dayData == null)
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.secondaryText, size: 40),
                const SizedBox(height: 12),
                Text(
                  '이 날의 기록이 없어요',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                ),
              ],
            ),
          )
        else ...[
          // 읽기 기록
          if (dayData['readingInfo'] != null)
            _buildReadingRecord(dayData['readingInfo']),
          const SizedBox(height: 12),
          // 나눔 기록
          if (dayData['myReflection'] != null)
            _buildReflectionRecord(
              name: provider.appUser?.displayName ?? '나',
              content: dayData['myReflection'],
              color: AppColors.softMint,
            ),
          const SizedBox(height: 12),
          if (dayData['partnerReflection'] != null)
            _buildReflectionRecord(
              name: provider.partner?.displayName ?? '파트너',
              content: dayData['partnerReflection'],
              color: AppColors.softBlue,
            ),
        ],
      ],
    );
  }

  Widget _buildReadingRecord(Map<String, dynamic> readingInfo) {
    final bookName = BibleConstants.getBookName(readingInfo['bookCode'] ?? '창');
    final chapter = readingInfo['chapter'] ?? '';
    final startVerse = readingInfo['startVerse'] ?? '';
    final endVerse = readingInfo['endVerse'] ?? '';

    return AppCard(
      child: Row(
        children: [
          const IconBox(icon: Icons.menu_book_outlined, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('읽은 말씀', style: Theme.of(context).textTheme.labelLarge),
                Text(
                  '$bookName $chapter:$startVerse-$endVerse',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const StatusChip(label: '완료', isActive: true),
        ],
      ),
    );
  }

  Widget _buildReflectionRecord({
    required String name,
    required String content,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$name의 나눔',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const AppDivider(),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
