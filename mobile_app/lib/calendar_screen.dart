import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'notification_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 19,
              top: 33,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                },
                child: SvgPicture.asset('assets/I64-321;7758-11128.svg', width: 20, height: 20),
              ),
            ),
            const Center(child: Text('Calendar Screen - Coming Soon', style: TextStyle(fontSize: 20))),
          ],
        ),
      ),
    );
  }
}
