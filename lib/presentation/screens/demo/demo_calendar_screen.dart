import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../providers/demo_provider.dart';

class DemoCalendarScreen extends StatefulWidget {
  const DemoCalendarScreen({super.key});

  @override
  State<DemoCalendarScreen> createState() => _DemoCalendarScreenState();
}

class _DemoCalendarScreenState extends State<DemoCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DemoProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text('읽기 기록'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 월 네비게이션
                _buildMonthNavigator(),
                const SizedBox(height: 16),
                // 캘린더
                _buildCalendar(provider),
                const SizedBox(height: 20),
                // 통계
                _buildStats(provider),
                const SizedBox(height: 20),
                // 선택된 날짜 상세
                if (_selectedDate != null) _buildDateDetail(provider),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final monthStr =
        DateFormat('yyyy년 M월', 'ko_KR').format(_currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() {
            _currentMonth = DateTime(
                _currentMonth.year, _currentMonth.month - 1);
          }),
          icon: const Icon(Icons.chevron_left),
          color: AppColors.primary,
        ),
        Text(monthStr,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText)),
        IconButton(
          onPressed: () => setState(() {
            _currentMonth = DateTime(
                _currentMonth.year, _currentMonth.month + 1);
          }),
          icon: const Icon(Icons.chevron_right),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildCalendar(DemoProvider provider) {
    final firstDay =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0=일요일

    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: d == '일'
                                  ? Colors.red[300]
                                  : d == '토'
                                      ? Colors.blue[300]
                                      : AppColors.secondaryText,
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // 날짜 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) return const SizedBox();

              final dateStr =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final isCompleted =
                  provider.completedDates.contains(dateStr);
              final isToday = _isToday(date);
              final isSelected = _selectedDate != null &&
                  _selectedDate!.day == date.day &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.year == date.year;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = isSelected ? null : date;
                }),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.softMint
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday || isCompleted
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : isCompleted
                                  ? AppColors.primary
                                  : AppColors.primaryText,
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildStats(DemoProvider provider) {
    final daysInMonth = DateTime(
            _currentMonth.year, _currentMonth.month + 1, 0)
        .day;
    final completedThisMonth = provider.completedDates.where((d) {
      final parts = d.split('-');
      return int.parse(parts[0]) == _currentMonth.year &&
          int.parse(parts[1]) == _currentMonth.month;
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _statItem('이번 달 완료', '$completedThisMonth일')),
          Container(
              width: 1, height: 40, color: AppColors.divider),
          Expanded(
              child: _statItem('전체 완료',
                  '${provider.completedDates.length}일')),
          Container(
              width: 1, height: 40, color: AppColors.divider),
          Expanded(
              child: _statItem(
                  '달성률',
                  '${(completedThisMonth / daysInMonth * 100).round()}%')),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText)),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.secondaryText)),
    ]);
  }

  Widget _buildDateDetail(DemoProvider provider) {
    final date = _selectedDate!;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final isCompleted = provider.completedDates.contains(dateStr);
    final displayDate =
        DateFormat('M월 d일 EEEE', 'ko_KR').format(date);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(displayDate,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.softMint
                    : AppColors.chipBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isCompleted ? '완료 ✓' : '미완료',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.secondaryText),
              ),
            ),
          ]),
          if (isCompleted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.menu_book_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${BibleConstants.getBookName(provider.currentBook)} ${provider.currentChapter}장 읽기 완료',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText),
                ),
              ]),
            ),
            if (provider.myReflection.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('나의 소감',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryText)),
                    const SizedBox(height: 6),
                    Text(provider.myReflection,
                        style: const TextStyle(
                            fontSize: 14, height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            const Text('이 날은 말씀을 읽지 않았어요.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.secondaryText)),
          ],
        ],
      ),
    );
  }
}
