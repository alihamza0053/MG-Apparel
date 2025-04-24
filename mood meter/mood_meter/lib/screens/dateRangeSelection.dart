import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DateRangeSelectionScreen extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime, DateTime) onDateRangeSelected;

  const DateRangeSelectionScreen({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<DateRangeSelectionScreen> createState() => _DateRangeSelectionScreenState();
}

class _DateRangeSelectionScreenState extends State<DateRangeSelectionScreen> {
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTimeRange? _selectedDateRange;

  // Color theme
  final Color primaryColor = const Color(0xFF2AABE2);

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialStartDate ?? DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now();
    _selectedStartDate = widget.initialStartDate;
    _selectedEndDate = widget.initialEndDate;

    if (_selectedStartDate != null && _selectedEndDate != null) {
      _selectedDateRange = DateTimeRange(
          start: _selectedStartDate!,
          end: _selectedEndDate!
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select Date Range',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick selection buttons
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Select',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildPresetButton('Today', _getToday),
                                  _buildPresetButton('Yesterday', _getYesterday),
                                  _buildPresetButton('Last 7 Days', _getLast7Days),
                                  _buildPresetButton('Last 30 Days', _getLast30Days),
                                  _buildPresetButton('This Month', _getThisMonth),
                                  _buildPresetButton('Last Month', _getLastMonth),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Selected range display
                        if (_selectedStartDate != null && _selectedEndDate != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event_available, color: primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Selected Range',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Start Date',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('MMM dd, yyyy').format(_selectedStartDate!),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          height: 30,
                                          width: 1,
                                          color: Colors.grey[300],
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'End Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat('MMM dd, yyyy').format(_selectedEndDate!),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_daysBetween(_selectedStartDate!, _selectedEndDate!)} day(s) selected',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Calendar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TableCalendar(
                                firstDay: _firstDay,
                                lastDay: _lastDay,
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                rangeStartDay: _selectedStartDate,
                                rangeEndDay: _selectedEndDate,
                                rangeSelectionMode: RangeSelectionMode.enforced,
                                onRangeSelected: (start, end, focusedDay) {
                                  setState(() {
                                    _selectedStartDate = start;
                                    _selectedEndDate = end ?? start;
                                    _focusedDay = focusedDay;

                                    if (start != null && end != null) {
                                      _selectedDateRange = DateTimeRange(
                                          start: start,
                                          end: end
                                      );
                                    } else if (start != null) {
                                      _selectedDateRange = DateTimeRange(
                                          start: start,
                                          end: start
                                      );
                                    }
                                  });
                                },
                                headerStyle: HeaderStyle(
                                  titleCentered: true,
                                  formatButtonVisible: true,
                                  formatButtonDecoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  formatButtonTextStyle: TextStyle(color: primaryColor),
                                  leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                                  rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
                                ),
                                calendarStyle: CalendarStyle(
                                  rangeHighlightColor: primaryColor.withOpacity(0.1),
                                  rangeStartDecoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  rangeEndDecoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  weekendTextStyle: const TextStyle(color: Colors.red),
                                  outsideDaysVisible: false,
                                ),
                                onFormatChanged: (format) {
                                  setState(() {
                                    _calendarFormat = format;
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: (_selectedStartDate != null && _selectedEndDate != null)
                            ? () {
                          widget.onDateRangeSelected(
                            _selectedStartDate!,
                            _selectedEndDate!,
                          );
                          Navigator.of(context).pop();
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(String title, Function() dateRange) {
    return ElevatedButton(
      onPressed: () {
        final range = dateRange();
        setState(() {
          _selectedStartDate = range.start;
          _selectedEndDate = range.end;
          _focusedDay = range.start;
          _selectedDateRange = range;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(title),
    );
  }

  // Quick date range presets
  DateTimeRange _getToday() {
    final today = DateTime.now();
    return DateTimeRange(
      start: DateTime(today.year, today.month, today.day),
      end: DateTime(today.year, today.month, today.day),
    );
  }

  DateTimeRange _getYesterday() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    return DateTimeRange(
      start: DateTime(yesterday.year, yesterday.month, yesterday.day),
      end: DateTime(yesterday.year, yesterday.month, yesterday.day),
    );
  }

  DateTimeRange _getLast7Days() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    return DateTimeRange(
      start: DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day),
      end: DateTime(today.year, today.month, today.day),
    );
  }

  DateTimeRange _getLast30Days() {
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(const Duration(days: 29));
    return DateTimeRange(
      start: DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day),
      end: DateTime(today.year, today.month, today.day),
    );
  }

  DateTimeRange _getThisMonth() {
    final today = DateTime.now();
    return DateTimeRange(
      start: DateTime(today.year, today.month, 1),
      end: DateTime(today.year, today.month + 1, 0),
    );
  }

  DateTimeRange _getLastMonth() {
    final today = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(today.year, today.month, 1);
    final lastDayOfLastMonth = firstDayOfCurrentMonth.subtract(const Duration(days: 1));
    final firstDayOfLastMonth = DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, 1);

    return DateTimeRange(
      start: firstDayOfLastMonth,
      end: lastDayOfLastMonth,
    );
  }

  int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round() + 1;
  }
}