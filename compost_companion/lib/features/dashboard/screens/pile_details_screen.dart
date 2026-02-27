import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PileDetailsScreen extends StatelessWidget {
  const PileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 1100,
            child: Stack(
              children: [
                // Header
                Positioned(
                  left: 17,
                  top: 27,
                  child: GestureDetector(
                    onTap: () {
                      // simply go back to previous screen rather than opening notifications
                      Navigator.pop(context);
                    },
                    child: SvgPicture.asset('assets/I104-206;7758-11224.svg', width: 10, height: 20),
                  ),
                ),
                Positioned(
                  left: 71,
                  top: 12,
                  child: Image.asset('assets/39-341.webp', width: 70, height: 70),
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

                // Title Section
                const Positioned(
                  left: 33,
                  top: 100,
                  child: Text('Backyard Pile A', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                Positioned(
                  left: 33,
                  top: 127,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF2F6F4E), borderRadius: BorderRadius.circular(16)),
                    child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Health Score Card
                Positioned(
                  left: 24,
                  top: 165,
                  child: Container(
                    width: 360,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Stack(
                      children: [
                        const Positioned(left: 15, top: 15, child: Text('Health Score', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                        Positioned(left: 15, top: 45, child: SvgPicture.asset('assets/14-741.svg', width: 120, height: 120)),
                        const Positioned(left: 150, top: 60, child: Text('Excellent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2F6F4E)))),
                        const Positioned(left: 150, top: 95, child: Opacity(opacity: 0.6, child: Text('Your pile is decomposing\nat an optimal rate.', style: TextStyle(fontSize: 13)))),
                      ],
                    ),
                  ),
                ),

                // Ingredients Section
                const Positioned(
                  left: 33,
                  top: 365,
                  child: Text('Ingredients', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  left: 24,
                  top: 395,
                  child: Container(
                    width: 360,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildIngredientRow('Carbon (Browns)', '60%', const Color(0xFFD68D18)),
                        _buildIngredientRow('Nitrogen (Greens)', '30%', const Color(0xFF2F6F4E)),
                        _buildIngredientRow('Other', '10%', Colors.grey),
                      ],
                    ),
                  ),
                ),

                // Tasks Section
                const Positioned(
                  left: 33,
                  top: 565,
                  child: Text('Upcoming Tasks', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildTaskItem(top: 595, title: 'Turn Pile', date: 'Tomorrow, 9:00 AM', icon: Icons.refresh),
                _buildTaskItem(top: 675, title: 'Add Water', date: 'Friday, 10:00 AM', icon: Icons.water_drop),
                _buildTaskItem(top: 755, title: 'Check Temp', date: 'Saturday, 8:00 AM', icon: Icons.thermostat),

                // Bottom Action Button
                Positioned(
                  left: 85,
                  top: 880,
                  child: Container(
                    width: 258,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF065128),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Log Activity',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientRow(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(percent, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTaskItem({required double top, required String title, required String date, required IconData icon}) {
    return Positioned(
      left: 24,
      top: top,
      child: Container(
        width: 360,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF2F6F4E)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(date),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
