import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/bible_constants.dart';
import '../../providers/app_provider.dart';

class CalendarScreen extends StatefulWidget {
  final bool isActive;

  const CalendarScreen({
    super.key,
    this.isActive = false,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _isForward = true; // 월 전환 방향 추적

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadCalendarData(_currentMonth);
    });
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      context.read<AppProvider>().loadCalendarData(_currentMonth);
    }
  }

  void _previousMonth() {
    setState(() {
      _isForward = false;
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    context.read<AppProvider>().loadCalendarData(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _isForward = true;
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
          SliverAppBar(
            pinned: true,
            centerTitle: true,
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
                // 캘린더 (월 전환 애니메이션)
                PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 300),
                  reverse: !_isForward,
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return SharedAxisTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<DateTime>(_currentMonth),
                    child: _buildCalendar(provider),
                  ),
                ),
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
    final monthStr = DateFormat('yyyy년 M월', 'ko_KR').format(_currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.primary,
        ),
        Text(monthStr,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText)),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildCalendar(AppProvider provider) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 0=일요일

    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDay.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    final calendarData = provider.calendarData;
    final today = DateTime.now();

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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              if (date == null) return const SizedBox();

              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final dayData = calendarData[dateKey];
              final isCompleted = dayData?['readingDone'] == true;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
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
                        ? Border.all(color: AppColors.primary, width: 2)
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
                            color:
                                isSelected ? Colors.white : AppColors.primary,
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

  Widget _buildStats(AppProvider provider) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final calendarData = provider.calendarData;

    // 이번 달 완료 일수 계산
    int completedThisMonth = 0;
    for (final entry in calendarData.entries) {
      final parts = entry.key.split('-');
      if (int.parse(parts[0]) == _currentMonth.year &&
          int.parse(parts[1]) == _currentMonth.month &&
          entry.value['readingDone'] == true) {
        completedThisMonth++;
      }
    }

    final totalCompleted = provider.totalReadingDays;
    final rate =
        daysInMonth > 0 ? (completedThisMonth / daysInMonth * 100).round() : 0;

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
          Expanded(child: _statItem('이번 달 완료', '$completedThisMonth일')),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(child: _statItem('전체 완료', '$totalCompleted일')),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(child: _statItem('달성률', '$rate%')),
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
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
    ]);
  }

  Widget _buildDateDetail(AppProvider provider) {
    final date = _selectedDate!;
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final dayData = provider.calendarData[dateKey];
    final isCompleted = dayData?['readingDone'] == true;
    final displayDate = DateFormat('M월 d일 EEEE', 'ko_KR').format(date);

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isCompleted ? AppColors.softMint : AppColors.chipBackground,
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
          if (isCompleted && dayData != null) ...[
            const SizedBox(height: 16),
            // 읽기 기록
            if (dayData['readingInfo'] != null)
              _buildReadingInfo(dayData['readingInfo']),
            // 나의 나눔
            if (dayData['myReflection'] != null) ...[
              const SizedBox(height: 10),
              _buildReflectionInfo(
                label: '나의 소감',
                content: dayData['myReflection'],
                color: AppColors.softMint,
              ),
            ],
            // 파트너 나눔
            if (dayData['partnerReflection'] != null) ...[
              const SizedBox(height: 10),
              _buildReflectionInfo(
                label: '${provider.partner?.displayName ?? '파트너'}의 소감',
                content: dayData['partnerReflection'],
                color: AppColors.softBlue,
              ),
            ],
            if (dayData['aiQuestions'] != null) ...[
              const SizedBox(height: 10),
              _buildAiQuestionsInfo(
                List<String>.from(dayData['aiQuestions']),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            const Text('이 날은 말씀을 읽지 않았어요.',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingInfo(Map<String, dynamic> readingInfo) {
    final bookName = BibleConstants.getBookName(readingInfo['bookCode'] ?? '창');
    final chapter = readingInfo['chapter'] ?? '';
    final startVerse = readingInfo['startVerse'] ?? '';
    final endVerse = readingInfo['endVerse'] ?? '';

    return Container(
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
          '$bookName $chapter:$startVerse-$endVerse 읽기 완료',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText),
        ),
      ]),
    );
  }

  Widget _buildReflectionInfo({
    required String label,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(fontSize: 14, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildAiQuestionsInfo(List<String> questions) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.purple, size: 16),
              SizedBox(width: 6),
              Text(
                'AI 대화 질문',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...questions.take(3).map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $question',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
