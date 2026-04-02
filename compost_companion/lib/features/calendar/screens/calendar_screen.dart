import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:compost_companion/core/theme/app_colors.dart';
import 'package:compost_companion/features/dashboard/screens/notification_screen.dart';
import 'package:compost_companion/data/services/auth_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  
  List<dynamic> _tasksForSelectedDate = [];
  bool _isLoadingTasks = false;

  final AuthService _auth = AuthService();

  String get _baseUrl => _auth.baseUrl;

  static const List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchTasksForDate(_selectedDate!);
  }

  Future<void> _fetchTasksForDate(DateTime date) async {
    setState(() {
      _isLoadingTasks = true;
      _tasksForSelectedDate = [];
    });

    final String dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final Uri url = Uri.parse('$_baseUrl/tasks/date/$dateString');
    final String? token = _auth.currentToken?.accessToken;

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _tasksForSelectedDate = json.decode(response.body);
        });
      } else {
        print('Error fetching tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
        });
      }
    }
  }

  void _prevMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });
  }

  int _leadingEmpty() {
    // Dart's weekday: Monday=1 ... Sunday=7. We want week to start on Sunday.
    final firstWeekday = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday; // 1..7
    return firstWeekday % 7; // Sunday -> 0, Monday -> 1, ..., Saturday -> 6
  }

  int _daysInMonth() {
    final nextMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return now.year == _focusedDate.year && now.month == _focusedDate.month && now.day == day;
  }

  bool _isSelected(int day) {
    if (_selectedDate == null) return false;
    return _selectedDate!.year == _focusedDate.year && _selectedDate!.month == _focusedDate.month && _selectedDate!.day == day;
  }

  @override
  Widget build(BuildContext context) {
    final leading = _leadingEmpty();
    final days = _daysInMonth();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
                    icon: const Icon(Icons.notifications_none),
                    color: AppColors.darkText,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.darkText,
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            child: ClipOval(
                              child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Calendar',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.darkText,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 20),

              // Month selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.darkText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_monthNames[_focusedDate.month - 1]} ${_focusedDate.year}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.darkText,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Weekday labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Su'),
                    Text('Mo'),
                    Text('Tu'),
                    Text('We'),
                    Text('Th'),
                    Text('Fr'),
                    Text('Sa'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Calendar grid (includes prev/next month filler days)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: ((leading + days + 6) ~/ 7) * 7,
                  itemBuilder: (context, index) {
                    final prevMonthLastDay = DateTime(_focusedDate.year, _focusedDate.month, 0).day;

                    if (index < leading) {
                      // previous month's trailing days
                      final day = prevMonthLastDay - (leading - 1 - index);
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    if (index >= leading + days) {
                      // next month's leading days
                      final day = index - (leading + days) + 1;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // current month day
                    final day = index - leading + 1;
                    final isToday = _isToday(day);
                    final isSelected = _isSelected(day);

                    return Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(_focusedDate.year, _focusedDate.month, day);
                          });
                          _fetchTasksForDate(_selectedDate!);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.darkGreen
                                  : isToday
                                      ? AppColors.accentGreen.withValues(alpha: 0.18)
                                      : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.darkText,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Today's Schedule header (mocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Schedule",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dynamic Schedule card
              if (_isLoadingTasks)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_tasksForSelectedDate.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No tasks scheduled for this day', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: _tasksForSelectedDate.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;

                        final title = task['title'] ?? 'Task';
                        final actionType = task['action_type'] ?? 'MONITOR';

                        Widget icon;
                        Color iconColor = AppColors.accentGreen;
                        if (actionType == 'WATER_PILE') {
                          icon = const Icon(Icons.opacity, color: Colors.blue);
                          iconColor = Colors.blue;
                        } else if (actionType == 'TURN_PILE') {
                          icon = const Icon(Icons.loop, color: Colors.orange);
                          iconColor = Colors.orange;
                        } else if (actionType == 'ADD_BROWNS') {
                          icon = const Icon(Icons.park, color: Colors.brown);
                          iconColor = Colors.brown;
                        } else {
                          icon = Icon(Icons.warning_amber_rounded, color: AppColors.accentGreen);
                        }

                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: iconColor.withValues(alpha: 0.12),
                                  child: icon,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: AppColors.darkText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGreen.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Active',
                                          style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (index < _tasksForSelectedDate.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
