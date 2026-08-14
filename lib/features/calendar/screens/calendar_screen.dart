import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:structflow/core/theme/app_colors.dart';
import 'package:structflow/features/calendar/models/calendar_event_model.dart';
import 'package:structflow/features/calendar/repositories/calendar_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() =>
      _CalendarScreenState();
}

class _CalendarScreenState
    extends State<CalendarScreen> {
  final CalendarRepository _repository =
      CalendarRepository.instance;

  DateTime _selectedDate = DateTime(
    2026,
    8,
    14,
  );

  DateTime _focusedMonth = DateTime(
    2026,
    8,
    1,
  );

  @override
  void initState() {
    super.initState();

    _repository.addListener(
      _onCalendarChanged,
    );
  }

  @override
  void dispose() {
    _repository.removeListener(
      _onCalendarChanged,
    );

    super.dispose();
  }

  void _onCalendarChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                width < 600 ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHeader(width),

                  const SizedBox(height: 24),

                  _buildCalendarCard(width),

                  const SizedBox(height: 24),

                  _buildSelectedDaySection(width),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(double width) {
    final isMobile =
        width < 650;

    if (isMobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              context.go('/');
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
            label: const Text(
              'Back to Dashboard',
            ),
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Calendar',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textDark,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Track project deadlines, tasks and milestones.',
            style: TextStyle(
              fontSize: 14,
              color:
                  AppColors.textLight,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.go('/');
          },
          tooltip:
              'Back to Dashboard',
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        const SizedBox(width: 8),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.textDark,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Track project deadlines, tasks and milestones.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================================================================
  // CALENDAR CARD
  // ================================================================

  Widget _buildCalendarCard(
    double width,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        width < 600 ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthHeader(),

          const SizedBox(height: 20),

          _buildWeekDays(),

          const SizedBox(height: 8),

          _buildCalendarGrid(width),
        ],
      ),
    );
  }

  // ================================================================
  // MONTH HEADER
  // ================================================================

  Widget _buildMonthHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(
            Icons.chevron_left_rounded,
          ),
        ),

        Expanded(
          child: Center(
            child: Text(
              _monthName(
                _focusedMonth.month,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textDark,
              ),
            ),
          ),
        ),

        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(
            Icons.chevron_right_rounded,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // WEEK DAYS
  // ================================================================

  Widget _buildWeekDays() {
    const days = [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ];

    return Row(
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================================================================
  // CALENDAR GRID
  // ================================================================

  Widget _buildCalendarGrid(
    double width,
  ) {
    final firstDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    final startingWeekday =
        firstDay.weekday % 7;

    final totalCells =
        startingWeekday + daysInMonth;

    final rows =
        (totalCells / 7).ceil();

    return Column(
      children: List.generate(
        rows,
        (rowIndex) {
          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children:
                List.generate(
              7,
              (columnIndex) {
                final cellIndex =
                    rowIndex * 7 +
                        columnIndex;

                final dayNumber =
                    cellIndex -
                        startingWeekday +
                        1;

                if (dayNumber < 1 ||
                    dayNumber >
                        daysInMonth) {
                  return const Expanded(
                    child: SizedBox(
                      height: 76,
                    ),
                  );
                }

                final date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  dayNumber,
                );

                return Expanded(
                  child:
                      _buildDayCell(
                    date,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // DAY CELL
  // ================================================================

  Widget _buildDayCell(
    DateTime date,
  ) {
    final events =
        _repository.getEventsForDate(
      date,
    );

    final selected =
        _isSameDay(
      date,
      _selectedDate,
    );

    final today =
        _isSameDay(
      date,
      DateTime.now(),
    );

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        height: 76,
        margin:
            const EdgeInsets.all(3),
        padding:
            const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
                  .withValues(alpha: .08)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.shade200,
            width:
                selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textDark,
                  ),
                ),

                const Spacer(),

                if (today)
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors.primary,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 5),

            ...events
                .take(2)
                .map(
                  (event) =>
                      _buildEventDot(
                    event,
                  ),
                ),

            if (events.length > 2)
              Text(
                '+${events.length - 2} more',
                style:
                    const TextStyle(
                  fontSize: 9,
                  color:
                      AppColors.textLight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDot(
    CalendarEventModel event,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 2,
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(
              color: event.color,
              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: Text(
              event.title,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  TextStyle(
                fontSize: 9,
                color: event.color,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SELECTED DAY
  // ================================================================

  Widget _buildSelectedDaySection(
    double width,
  ) {
    final events =
        _repository.getEventsForDate(
      _selectedDate,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        width < 600 ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_rounded,
                color:
                    AppColors.primary,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  _formatSelectedDate(
                    _selectedDate,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.textDark,
                  ),
                ),
              ),

              Text(
                '${events.length} event${events.length == 1 ? '' : 's'}',
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AppColors.textLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (events.isEmpty)
            _buildNoEvents()
          else
            Column(
              children: events
                  .map(
                    (event) =>
                        _buildEventCard(
                      event,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoEvents() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 35,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 45,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(height: 10),

            const Text(
              'No events for this day',
              style:
                  TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EVENT CARD
  // ================================================================

  Widget _buildEventCard(
    CalendarEventModel event,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(
          0xffFBFCFE,
        ),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 62,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.textDark,
                        ),
                      ),
                    ),

                    _eventTypeBadge(
                      event.type,
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  event.description,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color:
                          AppColors.textLight,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        '${event.projectCode} • ${event.projectName}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              AppColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTypeBadge(
    String type,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            AppColors.primary.withValues(
          alpha: .08,
        ),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
          color:
              AppColors.primary,
        ),
      ),
    );
  }

  // ================================================================
  // NAVIGATION
  // ================================================================

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        1,
      );
    });
  }

  // ================================================================
  // HELPERS
  // ================================================================

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _monthName(
    int month,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatSelectedDate(
    DateTime date,
  ) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }
}