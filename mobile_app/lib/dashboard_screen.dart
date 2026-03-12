import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models.dart';
import 'notification_screen.dart';
import 'pile_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<PileData> piles;
  const DashboardScreen({super.key, required this.piles});

  @override
  Widget build(BuildContext context) {
    // Calculate total height based on number of piles
    final double totalHeight = 323.0 + (piles.length * 166.0) + 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: totalHeight > 1000 ? totalHeight : 1000,
            child: Stack(
              children: [
                // Header
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
                Positioned(
                  left: 71,
                  top: 24,
                  child: Image.asset('assets/102-213.webp', width: 70, height: 70),
                ),
                const Positioned(
                  left: 162,
                  top: 47,
                  child: Text(
                    'My Piles',
                    style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),

                // Next Action Card
                Positioned(
                  left: 105,
                  top: 146,
                  child: Container(
                    width: 184,
                    height: 143,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 24,
                          top: 13,
                          child: Text('Next Action', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                        ),
                        Positioned(
                          left: 12,
                          top: 47,
                          child: SvgPicture.asset('assets/88-213.svg', width: 40, height: 40),
                        ),
                        const Positioned(
                          left: 57,
                          top: 53,
                          child: Text('Turn Pile', style: TextStyle(fontSize: 13)),
                        ),
                        const Positioned(
                          left: 55,
                          top: 71,
                          child: Opacity(
                            opacity: 0.5,
                            child: Text('Tomorrow 9:00 AM', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pile Cards
                for (int i = 0; i < piles.length; i++)
                  _buildPileCard(
                    context,
                    top: 323.0 + (i * 166.0),
                    pile: piles[i],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPileCard(
    BuildContext context, {
    required double top,
    required PileData pile,
  }) {
    return Positioned(
      left: 25,
      top: top,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PileDetailsScreen()),
          );
        },
        child: Container(
          width: 358,
          height: 125,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
              Positioned(left: 13, top: 6, child: Text(pile.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              Positioned(
                left: 14,
                top: 31,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(color: pile.statusColor, borderRadius: BorderRadius.circular(16)),
                  child: Text(pile.status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(right: 10, top: -10, child: SvgPicture.asset(pile.chartAsset, width: 70, height: 70)),
              Positioned(left: 6, top: 63, child: Container(width: 349.5, height: 1, color: const Color(0xFF757575))),
              Positioned(left: 7, top: 70, child: SvgPicture.asset(pile.tempIconAsset, width: 24, height: 24)),
              Positioned(left: 33, top: 74, child: Text('Temp: ${pile.temp}', style: const TextStyle(fontSize: 13))),
              Positioned(left: 112, top: 70, child: SvgPicture.asset(pile.moistureIconAsset, width: 24, height: 24)),
              Positioned(left: 139, top: 74, child: Text('Moisture: ${pile.moisture}', style: const TextStyle(fontSize: 13))),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  width: 100,
                  height: 21,
                  decoration: BoxDecoration(color: pile.buttonColor, borderRadius: BorderRadius.circular(5)),
                  alignment: Alignment.center,
                  child: const Text('View Details', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
