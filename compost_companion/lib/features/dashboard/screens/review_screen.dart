import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/data/models/ingredient.dart';
import 'save_screen.dart';

class ReviewScreen extends StatelessWidget {
  final Function(String) onSave;
  final Map<Ingredient,int> selected;
  const ReviewScreen({super.key, required this.onSave, required this.selected});

  double get carbonTotal {
    double sum = 0;
    selected.forEach((ing, qty) {
      sum += (ing.carbonContent ?? 0) * qty;
    });
    return sum;
  }

  double get nitrogenTotal {
    double sum = 0;
    selected.forEach((ing, qty) {
      sum += (ing.nitrogenContent ?? 0) * qty;
    });
    return sum;
  }

  double get phosphorusTotal => 0;

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
                  left: 4,
                  top: 26,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset('assets/I52-239;7758-11224.svg', width: 10, height: 20),
                  ),
                ),
                Positioned(
                  left: 71,
                  top: 12,
                  child: Image.asset('assets/44-580.webp', width: 70, height: 70),
                ),
                const Positioned(
                  left: 136,
                  top: 35,
                  child: Text(
                    'Compost Companion',
                    style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),

                // Progress Tabs
                Positioned(
                  left: 24,
                  top: 81,
                  child: Container(width: 366, height: 1, color: const Color(0xFF757575).withOpacity(0.2)),
                ),
                Positioned(
                  left: 170,
                  top: 113,
                  child: Container(width: 77.5, height: 2, color: const Color(0xFF2F6F4E)),
                ),
                const Positioned(
                  left: 53,
                  top: 89,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Ingredients', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Positioned(
                  left: 179,
                  top: 89,
                  child: Text('Review', style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const Positioned(
                  left: 283,
                  top: 89,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Save', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Review Mix Section
                const Positioned(
                  left: 37,
                  top: 120,
                  child: Text('Review Mix', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                const Positioned(
                  left: 37,
                  top: 147,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Confirm mix details.', style: TextStyle(color: Colors.black, fontSize: 13)),
                  ),
                ),

                // Review Card
                Positioned(
                  left: 19,
                  top: 171,
                  child: Container(
                    width: 360,
                    height: 230,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
                    ),
                    child: Stack(
                      children: [
                        _buildReviewItem(top: 8, title: 'Carbon Content', tag: 'Green', tagColor: const Color(0xFF2F6F4E), value: carbonTotal.toStringAsFixed(1)),
                        Positioned(left: 2, top: 73, child: Container(width: 355, height: 1, color: const Color(0xFF757575))),
                        _buildReviewItem(top: 80, title: 'Nitrogen Content', tag: 'Brown', tagColor: const Color(0xFFD68D18), value: nitrogenTotal.toStringAsFixed(1)),
                        Positioned(left: 4, top: 144, child: Container(width: 355, height: 1, color: const Color(0xFF757575))),
                        _buildReviewItem(top: 151, title: 'Phosphorus Content', tag: 'Green', tagColor: const Color(0xFF2F6F4E), value: phosphorusTotal.toStringAsFixed(1)),
                      ],
                    ),
                  ),
                ),

                // Summary Section
                Positioned(
                  left: 8,
                  top: 438,
                  child: SvgPicture.asset('assets/44-560.svg', width: 382, height: 284),
                ),

                // Buttons
                Positioned(
                  left: 21,
                  top: 730,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Text('Back', style: TextStyle(color: Colors.black54, fontSize: 20, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                Positioned(
                  left: 193,
                  top: 730,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SaveScreen(onSave: onSave, selected: selected)),
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF005428), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Text('Continue to Save', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
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

  Widget _buildReviewItem({
    required double top,
    required String title,
    required String tag,
    required Color tagColor,
    required String value,
  }) {
    return Positioned(
      left: 15,
      top: top,
      child: SizedBox(
        width: 330,
        height: 65,
        child: Stack(
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            Positioned(
              top: 29,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(16)),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              right: 0,
              top: 10,
              child: Row(
                children: [
                  const Icon(Icons.close, size: 14),
                  const SizedBox(width: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
