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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header with notification, logo, and title
              _buildHeader(context),
              const SizedBox(height: 24),

              // Next Action Card
              _buildNextActionCard(),
              const SizedBox(height: 40),

              // Pile Cards List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < piles.length; i++) ...[
                      _buildPileCard(context, pile: piles[i]),
                      if (i < piles.length - 1) const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
            child: SvgPicture.asset('assets/I64-321;7758-11128.svg', width: 24, height: 24),
          ),
          const Spacer(),
          Image.asset('assets/102-213.webp', width: 50, height: 50),
          const SizedBox(width: 12),
          const Text(
            'My Piles',
            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildNextActionCard() {
    return Center(
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next Action',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SvgPicture.asset('assets/88-213.svg', width: 32, height: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Turn Pile',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Opacity(
                      opacity: 0.6,
                      child: Text(
                        'Tomorrow 9:00 AM',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPileCard(BuildContext context, {required PileData pile}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PileDetailsScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            // Top section with pile name, status, and chart
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pile.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pile.statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pile.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(pile.chartAsset, width: 60, height: 60),
                ],
              ),
            ),
            
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(height: 1, color: Colors.grey[300]),
            ),

            // Bottom section with temperature, moisture, and button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SvgPicture.asset(pile.tempIconAsset, width: 20, height: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Temp: ${pile.temp}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 20),
                  SvgPicture.asset(pile.moistureIconAsset, width: 20, height: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Moisture: ${pile.moisture}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: pile.buttonColor,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
