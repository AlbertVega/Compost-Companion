import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/data/models/ingredient.dart';

import 'notification_screen.dart';
import 'ingredient_selection_screen.dart';
import 'review_screen.dart';

class CreateScreen extends StatefulWidget {
  final Function(String) onSave;
  const CreateScreen({super.key, required this.onSave});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  Map<Ingredient, int> _selected = {};

  double get carbonTotal {
    double sum = 0;
    _selected.forEach((ing, qty) {
      sum += (ing.carbonContent ?? 0) * qty;
    });
    return sum;
  }

  double get nitrogenTotal {
    double sum = 0;
    _selected.forEach((ing, qty) {
      sum += (ing.nitrogenContent ?? 0) * qty;
    });
    return sum;
  }

  // Phosphorus isn't tracked in the model; placeholder
  double get phosphorusTotal => 0;

  void _openIngredientPicker() async {
    final result = await Navigator.push<Map<Ingredient, int>>(
      context,
      MaterialPageRoute(builder: (context) => const IngredientSelectionScreen()),
    );
    if (result != null) {
      setState(() {
        _selected = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6).withOpacity(0.9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 900, // Fixed height for the stack content
            child: Stack(
              children: [
                // Header
                Positioned(
                  left: 17,
                  top: 27,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
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

                // Progress Tabs
                Positioned(
                  left: 24,
                  top: 81,
                  child: Container(width: 366, height: 1, color: const Color(0xFF757575).withOpacity(0.2)),
                ),
                Positioned(
                  left: 48,
                  top: 114,
                  child: Container(width: 102, height: 2, color: const Color(0xFF2F6F4E)),
                ),
                const Positioned(
                  left: 53,
                  top: 90,
                  child: Text('Ingredients', style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const Positioned(
                  left: 179,
                  top: 90,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Review', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Positioned(
                  left: 283,
                  top: 90,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Save', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Build a Mix Section
                const Positioned(
                  left: 33,
                  top: 139,
                  child: Text('Build a Mix', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                const Positioned(
                  left: 33,
                  top: 170,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Give your new compost pile a name', style: TextStyle(color: Colors.black, fontSize: 13)),
                  ),
                ),
                Positioned(
                  right: 30,
                  top: 139,
                  child: GestureDetector(
                    onTap: _openIngredientPicker,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/75-206;54626-27715.svg', width: 27, height: 24),
                        const SizedBox(width: 5),
                        const Text('Add ingredient', style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                // Search Field
                // Search field - now shows count of selected items
                Positioned(
                  left: 54,
                  top: 210,
                  child: Container(
                    width: 306,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 16, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selected.isEmpty
                                ? 'Search ingredients...'
                                : '${_selected.length} ingredient${_selected.length > 1 ? 's' : ''} selected',
                            style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Ingredient Cards
                _buildIngredientCard(
                  top: 260,
                  title: 'Carbon Content',
                  tag: 'Green',
                  tagColor: const Color(0xFF2F6F4E),
                  value: carbonTotal.toStringAsFixed(1),
                ),
                _buildIngredientCard(
                  top: 343,
                  title: 'Nitrogen Content',
                  tag: 'Brown',
                  tagColor: const Color(0xFFD68D18),
                  value: nitrogenTotal.toStringAsFixed(1),
                ),
                _buildIngredientCard(
                  top: 426,
                  title: 'Phosphorus Content',
                  tag: 'Green',
                  tagColor: const Color(0xFF2F6F4E),
                  value: phosphorusTotal.toStringAsFixed(1),
                ),

                // Summary Section
                Positioned(
                  left: 16,
                  top: 535,
                  child: SvgPicture.asset('assets/18-221.svg', width: 382, height: 284),
                ),

                // Continue Button
                Positioned(
                  left: 85,
                  top: 830,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReviewScreen(onSave: widget.onSave, selected: _selected)),
                      );
                    },
                    child: Container(
                      width: 258,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF065128),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildIngredientCard({
    required double top,
    required String title,
    required String tag,
    required Color tagColor,
    required String value,
  }) {
    return Positioned(
      left: 25,
      top: top,
      child: Container(
        width: 360,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 10,
              child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            ),
            Positioned(
              left: 12,
              top: 38,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(16)),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
                Positioned(
                  right: 15,
                  top: 15,
                  child: Container(
                    width: 80,
                    height: 40,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.remove, size: 16),
                    Container(width: 1, color: Colors.grey.withOpacity(0.3)),
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Container(width: 1, color: Colors.grey.withOpacity(0.3)),
                    const Icon(Icons.add, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
