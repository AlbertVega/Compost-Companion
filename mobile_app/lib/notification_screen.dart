import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 800,
            child: Stack(
              children: [
                // Header
                Positioned(
                  left: 17,
                  top: 27,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset('assets/I104-209;7758-11224.svg', width: 10, height: 20),
                  ),
                ),
                Positioned(
                  left: 71,
                  top: 12,
                  child: Image.asset('assets/102-207.webp', width: 70, height: 70),
                ),
                const Positioned(
                  left: 136,
                  top: 35,
                  child: Text(
                    'Compost Companion',
                    style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),

                // Progress Line
                Positioned(
                  left: 24,
                  top: 81,
                  child: Container(width: 366, height: 1, color: const Color(0xFF757575).withOpacity(0.2)),
                ),

                // Title
                const Positioned(
                  left: 33,
                  top: 100,
                  child: Text('Notifications', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                const Positioned(
                  left: 280,
                  top: 105,
                  child: Text('Mark all as read', style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 13, fontWeight: FontWeight.w600)),
                ),

                // Notification List
                _buildNotificationItem(
                  top: 145,
                  title: 'Garden Pile C is too dry!',
                  subtitle: 'Moisture level is at 25%. Add water soon.',
                  time: '2h ago',
                  tag: 'Needs Attention',
                  tagColor: const Color(0xFFDB181B),
                ),
                _buildNotificationItem(
                  top: 255,
                  title: 'Temperature is too high',
                  subtitle: 'Backyard Pile A reached 72°C. Turn the pile.',
                  time: '5h ago',
                  tag: 'Needs Attention',
                  tagColor: const Color(0xFFDB181B),
                ),
                _buildNotificationItem(
                  top: 365,
                  title: 'Pile B is ready to harvest!',
                  subtitle: 'Curing process is complete. Enjoy your compost.',
                  time: '1d ago',
                  tag: 'Completed',
                  tagColor: const Color(0xFF2F6F4E),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required double top,
    required String title,
    required String subtitle,
    required String time,
    required String tag,
    required Color tagColor,
  }) {
    return Positioned(
      left: 24,
      top: top,
      child: Container(
        width: 360,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(left: 15, top: 12, child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            Positioned(left: 15, top: 32, child: Opacity(opacity: 0.6, child: Text(subtitle, style: const TextStyle(fontSize: 12)))),
            Positioned(
              left: 15,
              top: 65,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(12)),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(right: 15, top: 12, child: Opacity(opacity: 0.4, child: Text(time, style: const TextStyle(fontSize: 10)))),
            const Positioned(right: 15, bottom: 12, child: Icon(Icons.delete_outline, size: 20, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
