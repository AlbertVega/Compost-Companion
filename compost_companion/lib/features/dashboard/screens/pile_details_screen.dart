import 'package:flutter/material.dart';
import 'package:compost_companion/data/services/compost_service.dart';
import 'package:compost_companion/data/models/dashboard_pile.dart';
import 'package:compost_companion/data/models/pile_ingredient_selection.dart';
import 'package:compost_companion/data/services/pile_ingredient_store.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/features/dashboard/screens/notification_screen.dart';
import 'package:compost_companion/features/calendar/screens/task_details_screen.dart';

class PileDetailsScreen extends StatefulWidget {
  final int pileId;
  final String? pileName;

  const PileDetailsScreen({super.key, required this.pileId, this.pileName});

  @override
  State<PileDetailsScreen> createState() => _PileDetailsScreenState();
}

class _PileDetailsScreenState extends State<PileDetailsScreen> {
  final CompostService _service = CompostService();
  HealthRecord? _record;
  String? _error;
  bool _loading = true;
  final PileIngredientStore _pileIngredientStore = PileIngredientStore();
  List<PileIngredientSelection> _selectedIngredients = const [];
  List<dynamic> _activeTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchLatest();
  }

  Future<void> _fetchLatest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _service.fetchLatestHealthRecord(widget.pileId);
      final storedIngredients = await _pileIngredientStore.getPileIngredients(widget.pileId);
      final tasks = await _service.fetchActiveTasksForPile(widget.pileId);
      setState(() {
        _record = r;
        _selectedIngredients = storedIngredients;
        _activeTasks = tasks;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color _colorForStatus(String? hs) {
    switch (hs) {
      case 'good':
        return const Color(0xFF2F6F4E);
      case 'acceptable':
        return const Color(0xFFD68D18);
      case 'bad':
        return const Color(0xFFDB181B);
      default:
        return Colors.grey;
    }
  }

  String _labelForStatus(String? hs) {
    switch (hs) {
      case 'good':
        return 'Good';
      case 'acceptable':
        return 'Acceptable';
      case 'bad':
        return 'Needs Attention';
      default:
        return 'Unknown';
    }
  }


  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(_record?.status);
    final label = _labelForStatus(_record?.status);
    final score = (_record?.healthScore != null)
        ? (_record!.healthScore! / 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/I64-321;7758-11128.svg',
                        width: 24,
                        height: 24,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.pileName ?? 'Pile ${widget.pileId}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text('Error: $_error',
                      style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),

                // Health Score Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                                value: score, color: color, strokeWidth: 10),
                            Text('${(score * 100).round()}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: TextStyle(fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: color)),
                            const SizedBox(height: 8),
                            Opacity(opacity: 0.7,
                                child: Text(
                                    _record != null
                                        ? 'Updated ${_record!.timestamp
                                        .toLocal()}'
                                        : 'No recent record')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Metrics Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.thermostat, color: color),
                      const SizedBox(width: 8),
                      Text(_record != null ? '${_record!.temperature
                          .toStringAsFixed(1)} °C' : '—'),
                      const SizedBox(width: 24),
                      Icon(Icons.water_drop, color: color),
                      const SizedBox(width: 8),
                      Text(_record != null ? '${_record!.moisture
                          .toStringAsFixed(1)} %' : '—'),
                      const Spacer(),
                      // mini chart
                      Container(width: 60,
                          height: 34,
                          decoration: BoxDecoration(color: color.withOpacity(
                              0.12), borderRadius: BorderRadius.circular(8)),
                          child: CustomPaint(painter: _MiniChartPainter(
                              color: color))),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Ingredients (placeholder)
                const Text('Ingredients', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildIngredientsCard(),
                const SizedBox(height: 16),

                const Text('Upcoming Tasks', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildUpcomingTasksCard(),

                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 14)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsCard() {
    final selectedIngredients = _selectedIngredients;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: selectedIngredients.isEmpty
          ? const Text(
        'No saved ingredient mix found for this pile yet.',
        style: TextStyle(color: Colors.grey),
      )
          : Column(
        children: selectedIngredients
            .map(
              (ingredient) =>
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ingredient.ingredientName),
                trailing: Text(
                  'x${ingredient.quantity.toStringAsFixed(ingredient.quantity.truncateToDouble() == ingredient.quantity ? 0 : 2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
        )
            .toList(),
      ),
    );
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

  Widget _buildUpcomingTasksCard() {
    if (_activeTasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Text('No active tasks right now.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
            children: _activeTasks.map((task) {
          final title = task['title'] ?? 'Task';
          final actionType = task['action_type'] ?? 'MONITOR';
          final dateStr = task['date_scheduled'] ?? '';
          final timeScheduled = _formatTime(task['time_scheduled']);

          Widget icon;
          if (actionType == 'WATER_PILE') {
            icon = const Icon(Icons.opacity, color: Colors.blue);
          } else if (actionType == 'TURN_PILE') {
            icon = const Icon(Icons.loop, color: Colors.orange);
          } else if (actionType == 'ADD_BROWNS') {
            icon = const Icon(Icons.park, color: Colors.brown);
          } else {
            icon = const Icon(Icons.warning_amber_rounded, color: Colors.green);
          }

          return InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailsScreen(task: task),
                ),
              );
              if (result == true) {
                _fetchLatest(); // Refresh if task was marked done
              }
            },
            child: ListTile(
              leading: icon,
              title: Text(title),
              subtitle: Text('$dateStr  $timeScheduled'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          );
        }).toList()));
  }
}

class _MiniChartPainter extends CustomPainter {
  final Color color;
  _MiniChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.25, size.height * 0.6);
    path.lineTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
