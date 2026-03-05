import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/core/theme/app_theme.dart';
import 'package:compost_companion/features/auth/screens/login_screen.dart';
import 'package:compost_companion/features/dashboard/screens/dashboard_screen.dart';
import 'package:compost_companion/features/dashboard/screens/create_screen.dart';
import 'package:compost_companion/features/calendar/screens/calendar_screen.dart';
import 'package:compost_companion/features/dashboard/screens/map_screen.dart';

void main() {
  runApp(const MyPilesApp());
}

class MyPilesApp extends StatefulWidget {
  const MyPilesApp({super.key});

  @override
  State<MyPilesApp> createState() => _MyPilesAppState();
}

class _MyPilesAppState extends State<MyPilesApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Piles',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const LoginScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _dashboardVersion = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCreateFlowCompleted() {
    setState(() {
      _dashboardVersion += 1;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(key: ValueKey(_dashboardVersion)),
      CreateScreen(onSave: (name) {}, onFlowCompleted: _onCreateFlowCompleted),
      const CalendarScreen(),
      const MapScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 83,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'assets/64-200.svg', 'Dashboard'),
            _buildNavItem(1, 'assets/I64-198;54626-27715.svg', 'Create', isCenter: true),
            _buildNavItem(2, 'assets/I64-195;54616-25498.svg', 'Calendar'),
            _buildNavItem(3, 'assets/I64-196;58640-72987.svg', 'Map'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconAsset, String label, {bool isCenter = false}) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: isCenter ? 38 : 24,
            height: isCenter ? 38 : 24,
            color: isSelected ? const Color(0xFF2F6F4E) : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2F6F4E) : Colors.black,
              fontSize: 10,
              fontFamily: 'SF Pro',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
