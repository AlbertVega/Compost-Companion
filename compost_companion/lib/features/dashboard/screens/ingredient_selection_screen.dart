import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IngredientSelectionScreen extends StatelessWidget {
  const IngredientSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 850,
            child: Stack(
              children: [
                // Header
                Positioned(
                  left: 5,
                  top: 37,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset('assets/I104-203;7758-11224.svg', width: 10, height: 20),
                  ),
                ),
                Positioned(
                  left: 64,
                  top: 22,
                  child: Image.asset('assets/75-273.webp', width: 70, height: 70),
                ),
                const Positioned(
                  left: 129,
                  top: 45,
                  child: Text(
                    'Compost Companion',
                    style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),

                // Progress Line
                Positioned(
                  left: 25,
                  top: 88,
                  child: Container(width: 366, height: 1, color: const Color(0xFF757575).withOpacity(0.2)),
                ),

                // Title
                const Positioned(
                  left: 148,
                  top: 156,
                  child: Text('Ingredient', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                Positioned(
                  left: 261,
                  top: 149,
                  child: SvgPicture.asset('assets/75-291.svg', width: 39, height: 39),
                ),

                // Input Card
                Positioned(
                  left: 24,
                  top: 248,
                  child: Container(
                    width: 362,
                    height: 441,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
                    ),
                    child: Stack(
                      children: [
                        _buildInputField(top: 57, label: 'Name'),
                        _buildInputField(top: 151, label: 'Moisture content'),
                        _buildInputField(top: 248, label: 'Nitrogen content'),
                        _buildInputField(top: 345, label: 'Carbon content'),
                      ],
                    ),
                  ),
                ),

                // Save Button
                Positioned(
                  left: 142,
                  top: 752,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 126,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF005428), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
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

  Widget _buildInputField({required double top, required String label}) {
    return Positioned(
      left: 58,
      top: top,
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF757575), fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(width: 245.5, height: 1, color: Colors.black),
        ],
      ),
    );
  }
}
