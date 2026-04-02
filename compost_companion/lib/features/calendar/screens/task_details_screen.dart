import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:compost_companion/core/theme/app_colors.dart';
import 'package:compost_companion/data/services/auth_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late bool isDone;
  bool _isLoading = false;
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    isDone = widget.task['status'] == 'Done';
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      int hour = int.parse(parts[0]);
      final min = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour == 0) hour = 12;
      if (hour > 12) hour -= 12;
      return '$hour:$min $period';
    }
    return timeStr;
  }

  String _getTaskDescription(String actionType, String title) {
    // Extracting the pile name dynamically
    final pileName = title
        .replaceAll(RegExp(r'^(Turn|Water|Add Browns to|Harvest|Monitor)\s+'), '')
        .replaceAll(RegExp(r'\s*\(Curing/Active\)$'), '');

    switch (actionType) {
      case 'WATER_PILE':
        return "Hey! You need to water the pile '$pileName' since I've detected a drop in the moisture. I think it will be decreasing in the next few days. Keeping the moisture at optimum levels ensures microorganisms thrive.";
      case 'TURN_PILE':
        return "Hey! You need to turn the pile '$pileName' since the temperature indicates it needs aeration. Turning it will provide oxygen for the aerobic decomposition to speed up.";
      case 'ADD_BROWNS':
        return "Hey! You need to add more browns (carbon-rich materials) to '$pileName'. This will balance the C:N ratio, absorb excess moisture, and prevent bad odors.";
      case 'HARVEST':
        return "Great news! The pile '$pileName' seems to be ready for harvesting. Check its texture and smell. If it's dark and earthy, it's time to use your compost!";
      case 'MONITOR':
      default:
        return "Just keep an eye on '$pileName'. Continue monitoring its temperature and moisture. Let the curing process continue naturally.";
    }
  }

  Future<void> _markTaskAsDone() async {
    setState(() {
      _isLoading = true;
    });

    final taskId = widget.task['task_id'];
    final url = Uri.parse('${_auth.baseUrl}/tasks/$taskId/complete');
    final token = _auth.currentToken?.accessToken;

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isDone = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task marked as completed!')),
          );
          Navigator.of(context).pop(true); // Return to previous screen with true (needs refresh)
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update task: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.task['title'] ?? 'Task';
    final actionType = widget.task['action_type'] ?? 'MONITOR';
    final dateScheduled = widget.task['date_scheduled'] ?? '';
    final timeScheduled = _formatTime(widget.task['time_scheduled']);
    final status = isDone ? 'Done' : (widget.task['status'] ?? 'Active');

    IconData iconData;
    Color iconColor = AppColors.accentGreen;
    if (actionType == 'WATER_PILE') {
      iconData = Icons.opacity;
      iconColor = Colors.blue;
    } else if (actionType == 'TURN_PILE') {
      iconData = Icons.loop;
      iconColor = Colors.orange;
    } else if (actionType == 'ADD_BROWNS') {
      iconData = Icons.park;
      iconColor = Colors.brown;
    } else {
      iconData = Icons.warning_amber_rounded;
    }

    if (isDone) {
      iconData = Icons.check_circle;
      iconColor = Colors.grey;
    }

    final description = _getTaskDescription(actionType, title);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).pop(), // Pop without refresh request if not done
        ),
        title: Text(
          'Task Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: iconColor.withValues(alpha: 0.12),
                  child: Icon(iconData, color: iconColor, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IconText(Icons.calendar_today, dateScheduled),
                  if (timeScheduled.isNotEmpty) _IconText(Icons.access_time, timeScheduled),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.grey.withValues(alpha: 0.14) : AppColors.accentGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            color: isDone ? Colors.grey : AppColors.darkGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ),
              const Spacer(),
              if (!isDone)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _markTaskAsDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Task completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconText(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}