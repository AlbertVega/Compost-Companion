import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models.dart';
import 'dashboard_screen.dart';
import 'create_screen.dart';
import 'calendar_screen.dart';
import 'map_screen.dart';

void main() {
  runApp(const MyPilesApp());
}

class MyPilesApp extends StatefulWidget {
  const MyPilesApp({super.key});

  @override
  State<MyPilesApp> createState() => _MyPilesAppState();
}

class _MyPilesAppState extends State<MyPilesApp> {
  final List<PileData> _piles = [
    PileData(
      title: 'Pile A',
      status: 'Active',
      statusColor: const Color(0xFF2F6F4E),
      temp: '52 C',
      moisture: '58%',
      chartAsset: 'assets/14-741.svg',
      tempIconAsset: 'assets/I18-94;14-733.svg',
      moistureIconAsset: 'assets/14-733.svg',
      buttonColor: const Color(0xFF2F6F4E),
    ),
    PileData(
      title: 'Pile B',
      status: 'Curing',
      statusColor: const Color(0xFFD68D18),
      temp: '38 C',
      moisture: '45%',
      chartAsset: 'assets/I14-749;14-741.svg',
      tempIconAsset: 'assets/I18-121;14-733.svg',
      moistureIconAsset: 'assets/I18-112;14-733.svg',
      buttonColor: const Color(0xFF2F6F4E),
    ),
    PileData(
      title: 'Pile C',
      status: 'Needs Attention',
      statusColor: const Color(0xFFDB181B),
      temp: '47 C',
      moisture: '25%',
      chartAsset: 'assets/I14-746;14-741.svg',
      tempIconAsset: 'assets/I18-103;14-733.svg',
      moistureIconAsset: 'assets/I18-130;14-733.svg',
      buttonColor: const Color(0xFFDB181B),
    ),
  ];

  // Global state for map pins to ensure persistence across tabs
  final Map<String, SoilPin> _globalSoilPins = {};

  void _addNewPile(String name) {
    setState(() {
      _piles.add(PileData(
        title: name.isEmpty ? 'New Pile' : name,
        status: 'Active',
        statusColor: const Color(0xFF2F6F4E),
        temp: '45 C',
        moisture: '60%',
        chartAsset: 'assets/14-741.svg',
        tempIconAsset: 'assets/I18-94;14-733.svg',
        moistureIconAsset: 'assets/14-733.svg',
        buttonColor: const Color(0xFF2F6F4E),
      ));
    });
  }

  void _addGlobalPin(SoilPin pin) {
    setState(() {
      _globalSoilPins[pin.id] = pin;
    });
  }

  void _removeGlobalPin(String id) {
    setState(() {
      _globalSoilPins.remove(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Piles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F4E)),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: MainNavigation(
        piles: _piles, 
        onSave: _addNewPile,
        globalPins: _globalSoilPins,
        onAddPin: _addGlobalPin,
        onRemovePin: _removeGlobalPin,
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final List<PileData> piles;
  final Function(String) onSave;
  final Map<String, SoilPin> globalPins;
  final Function(SoilPin) onAddPin;
  final Function(String) onRemovePin;

  const MainNavigation({
    super.key, 
    required this.piles, 
    required this.onSave,
    required this.globalPins,
    required this.onAddPin,
    required this.onRemovePin,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(piles: widget.piles),
      CreateScreen(onSave: widget.onSave),
      const CalendarScreen(),
      MapScreen(
        globalPins: widget.globalPins,
        onAddPin: widget.onAddPin,
        onRemovePin: widget.onRemovePin,
      ),
    ];

    return Scaffold(
      // IndexedStack keeps all screens alive in the background
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
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
            colorFilter: isSelected 
                ? const ColorFilter.mode(Color(0xFF2F6F4E), BlendMode.srcIn)
                : null,
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
