import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/features/dashboard/controllers/create_mix_controller.dart';
import 'package:compost_companion/data/services/pile_ingredient_store.dart';

class SaveScreen extends StatefulWidget {
  final Function(String) onSave;
  final CreateMixController controller;
  final VoidCallback? onFlowCompleted;

  const SaveScreen({
    super.key,
    required this.onSave,
    required this.controller,
    this.onFlowCompleted,
  });

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Backyard Sprint Mix');
  final TextEditingController _locationController = TextEditingController();

  int? _selectedExistingPileId;
  bool _createNewPile = true;
  final PileIngredientStore _pileIngredientStore = PileIngredientStore();

  @override
  void initState() {
    super.initState();
    widget.controller.loadExistingPiles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final mixName = _nameController.text.trim();
    if (mixName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a mix name')),
      );
      return;
    }

    if (_createNewPile) {
      try {
        final createdPile = await widget.controller.createNewPile(
          mixName: mixName,
          location: _locationController.text.trim().isEmpty ? 'Not specified' : _locationController.text.trim(),
        );
        await _pileIngredientStore.savePileIngredients(
          createdPile.id,
          widget.controller.selectedIngredientSummary,
        );
        if (!mounted) return;
        widget.onSave(mixName);
        widget.onFlowCompleted?.call();
        widget.controller.clearSelectedIngredients();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compost pile created successfully'), backgroundColor: Colors.green),
        );
        _finishCreateFlow();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create pile: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final selectedPile = widget.controller.existingPiles
        .where((pile) => pile.id == _selectedExistingPileId)
        .toList();

    if (selectedPile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an existing pile or choose New pile')),
      );
      return;
    }

    if (!mounted) return;
    await _pileIngredientStore.savePileIngredients(
      _selectedExistingPileId!,
      widget.controller.selectedIngredientSummary,
    );
    widget.onSave(mixName);
    widget.onFlowCompleted?.call();
    widget.controller.clearSelectedIngredients();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mix saved'), backgroundColor: Colors.green),
    );
    _finishCreateFlow();
  }

  void _finishCreateFlow() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(); // Save -> Review
    }
    if (navigator.canPop()) {
      navigator.pop(); // Review -> Create tab (inside MainNavigation)
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final existingPiles = widget.controller.existingPiles;
        final saving = widget.controller.saving;

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
                          child: SvgPicture.asset('assets/I64-268;7758-11224.svg', width: 10, height: 20),
                        ),
                        const Spacer(),
                        Image.asset('assets/64-249.webp', width: 56, height: 56),
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
                          child: Text('Ingredients', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        Opacity(
                          opacity: 0.5,
                          child: Text('Review', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        Text('Save', style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(width: 64, height: 2, color: const Color(0xFF2F6F4E)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Save Mix', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    const Opacity(
                      opacity: 0.5,
                      child: Text('Customize your compost settings.', style: TextStyle(color: Colors.black, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mix name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          ),
                          const SizedBox(height: 14),
                          const Text('Assign to pile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (widget.controller.loadingPiles)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: LinearProgressIndicator(),
                            ),
                          ...existingPiles.map(
                            (pile) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onTap: () {
                                setState(() {
                                  _createNewPile = false;
                                  _selectedExistingPileId = pile.id;
                                });
                              },
                              leading: Icon(
                                !_createNewPile && _selectedExistingPileId == pile.id
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: const Color(0xFF2F6F4E),
                              ),
                              title: Text(pile.name),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onTap: () {
                              setState(() {
                                _createNewPile = true;
                                _selectedExistingPileId = null;
                              });
                            },
                            leading: Icon(
                              _createNewPile ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: const Color(0xFF2F6F4E),
                            ),
                            title: const Text('New pile'),
                          ),
                          if (_createNewPile) ...[
                            const SizedBox(height: 8),
                            const Text('Pile location (optional)', style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter location',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Volume at creation: ${widget.controller.totalVolume.toStringAsFixed(1)}',
                              style: TextStyle(color: Colors.black.withValues(alpha: 0.7)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F6F4E),
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save'),
                      ),
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
}
