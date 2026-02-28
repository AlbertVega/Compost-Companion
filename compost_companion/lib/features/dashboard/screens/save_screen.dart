import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/data/models/ingredient.dart';

class SaveScreen extends StatefulWidget {
  final Function(String) onSave;
  final Map<Ingredient,int> selected;
  const SaveScreen({super.key, required this.onSave, required this.selected});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Backyard Sprint Mix');
  final TextEditingController _pileController = TextEditingController();
  int _selectedPile = 0;

  @override
  void initState() {
    super.initState();
    // selected ingredients available via widget.selected
  }

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
                    child: SvgPicture.asset('assets/I64-268;7758-11224.svg', width: 10, height: 20),
                  ),
                ),
                Positioned(
                  left: 71,
                  top: 12,
                  child: Image.asset('assets/64-249.webp', width: 70, height: 70),
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
                  left: 275,
                  top: 113,
                  child: Container(width: 63.5, height: 2, color: const Color(0xFF2F6F4E)),
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
                  left: 178,
                  top: 88,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Review', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Positioned(
                  left: 283,
                  top: 89,
                  child: Text('Save', style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 13, fontWeight: FontWeight.bold)),
                ),

                // Save Mix Section
                const Positioned(
                  left: 41,
                  top: 144,
                  child: Text('Save Mix', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                const Positioned(
                  left: 41,
                  top: 180,
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Customize your compost settings.', style: TextStyle(color: Colors.black, fontSize: 13)),
                  ),
                ),

                // Save Card
                Positioned(
                  left: 24,
                  top: 246,
                  child: Container(
                    width: 360,
                    height: 372,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
                    ),
                    child: Stack(
                      children: [
                        const Positioned(left: 18, top: 25, child: Text('Mix name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500))),
                        Positioned(
                          left: 19,
                          top: 65,
                          child: Container(
                            width: 181,
                            height: 22,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black.withOpacity(0.2))),
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF757575)),
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(left: 13, bottom: 12)),
                            ),
                          ),
                        ),
                        Positioned(left: 7.5, top: 102.5, child: Container(width: 335, height: 1, color: const Color(0xFF757575).withOpacity(0.4))),
                        const Positioned(left: 18, top: 117, child: Text('Assign to Pile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500))),
                        
                        _buildPileOption(top: 152, title: 'Backyard Pile A', index: 0),
                        _buildPileOption(top: 183, title: 'Community Pile B', index: 1),
                        _buildPileOption(top: 216, title: 'New pile (optional)', index: 2),

                        Positioned(
                          left: 50,
                          top: 274,
                          child: Container(
                            width: 168,
                            height: 29,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black.withOpacity(0.2))),
                            child: TextField(
                              controller: _pileController,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF757575)),
                              decoration: const InputDecoration(hintText: 'Enter pile name', hintStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF757575)), border: InputBorder.none, contentPadding: EdgeInsets.only(left: 23, bottom: 10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                Positioned(
                  left: 118,
                  top: 712,
                  child: GestureDetector(
                    onTap: () {
                      widget.onSave(_selectedPile == 2 ? _pileController.text : (_selectedPile == 0 ? 'Backyard Pile A' : 'Community Pile B'));
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Container(
                      width: 200,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF2F6F4E), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
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

  Widget _buildPileOption({required double top, required String title, required int index}) {
    return Positioned(
      left: 18,
      top: top,
      child: GestureDetector(
        onTap: () => setState(() => _selectedPile = index),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF757575).withOpacity(0.5)),
                color: _selectedPile == index ? const Color(0xFF2F6F4E) : Colors.white,
              ),
            ),
            const SizedBox(width: 18),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
