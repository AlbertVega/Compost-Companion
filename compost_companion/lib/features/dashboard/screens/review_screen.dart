import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/features/dashboard/controllers/create_mix_controller.dart';

import 'save_screen.dart';

class ReviewScreen extends StatelessWidget {
  final Function(String) onSave;
  final CreateMixController controller;
  final VoidCallback? onFlowCompleted;

  const ReviewScreen({
    super.key,
    required this.onSave,
    required this.controller,
    this.onFlowCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedEntries = controller.selected.entries.toList();
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9F6).withValues(alpha: 0.9),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgPicture.asset('assets/I52-239;7758-11224.svg', width: 10, height: 20),
                        ),
                        const Spacer(),
                        Image.asset('assets/44-580.webp', width: 56, height: 56),
                        const SizedBox(width: 10),
                        const Text(
                          'Compost Companion',
                          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: const Color(0xFF757575).withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Opacity(
                          opacity: 0.5,
                          child: Text(
                            'Ingredients',
                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          'Review',
                          style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Opacity(
                          opacity: 0.5,
                          child: Text(
                            'Save',
                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.center,
                      child: Container(width: 86, height: 2, color: const Color(0xFF2F6F4E)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Review Mix',
                      style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    const Opacity(
                      opacity: 0.5,
                      child: Text('Confirm mix details.', style: TextStyle(color: Colors.black, fontSize: 13)),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: selectedEntries.isEmpty
                          ? const Text('No ingredients selected')
                          : Column(
                              children: selectedEntries.map((entry) {
                                final ingredient = entry.key;
                                final quantity = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ingredient.name,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        'x$quantity',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Values',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          _buildValueRow('Carbon Content', controller.totalCarbon.toStringAsFixed(1)),
                          _buildValueRow('Nitrogen Content', controller.totalNitrogen.toStringAsFixed(1)),
                          _buildValueRow('C:N Ratio', controller.ratioLabel),
                          _buildValueRow('Moisture', '${controller.moisture.toStringAsFixed(1)}%'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: controller.ratioColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  controller.ratioStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.suggestion,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SaveScreen(
                                    onSave: onSave,
                                    controller: controller,
                                    onFlowCompleted: onFlowCompleted,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005428),
                            ),
                            child: const Text('Continue to Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
