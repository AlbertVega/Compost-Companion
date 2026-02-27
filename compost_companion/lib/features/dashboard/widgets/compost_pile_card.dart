import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:compost_companion/data/models/dashboard_pile.dart';

class CompostPileCard extends StatelessWidget {
  final DashboardPile pile;
  final VoidCallback? onTap;

  const CompostPileCard({super.key, required this.pile, this.onTap});

  // colour based strictly on the status string returned by the server.
  // if the database didn't supply one we fall back to grey.
  Color get _statusColor => pile.statusColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title / status / chart row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pile.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pile.displayStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // placeholder chart
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomPaint(
                      painter: _MiniChartPainter(color: _statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pile.error != null) ...[
                Text(
                  'Error: ${pile.error}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 8),
              ],
              if (pile.latestRecord != null) ...[
                Row(
                  children: [
                    Icon(Icons.thermostat, color: _statusColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Temp: ${pile.latestRecord!.temperature.toStringAsFixed(1)} °C',
                      style: TextStyle(color: _statusColor, fontSize: 13),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.water_drop, color: _statusColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Moisture: ${pile.latestRecord!.moisture.toStringAsFixed(1)} %',
                      style: TextStyle(color: _statusColor, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'At: ${DateFormat.yMMMd().add_jm().format(pile.latestRecord!.timestamp)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ] else ...[
                const Text('No data yet', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    // draw a simple zig-zag line as placeholder
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.25, size.height * 0.6);
    path.lineTo(size.width * 0.5, size.height * 0.75);
    path.lineTo(size.width * 0.75, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
