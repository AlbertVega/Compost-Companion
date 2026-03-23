import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/features/dashboard/controllers/create_mix_controller.dart';
import 'package:compost_companion/data/models/ingredient.dart';

class IngredientSelectionScreen extends StatefulWidget {
  const IngredientSelectionScreen({super.key});

  @override
  State<IngredientSelectionScreen> createState() => _IngredientSelectionScreenState();
}

class _IngredientSelectionScreenState extends State<IngredientSelectionScreen> {
  final CreateMixController _ctrl = CreateMixController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    _ctrl.loadIngredients();
  }

  @override
  void dispose() {
    _ctrl.removeListener(() {});
    _searchController.dispose();
    super.dispose();
  }

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
                if (_ctrl.loading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withOpacity(0.7),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
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

                // Search + selected list
                Positioned(
                  left: 24,
                  top: 248,
                  right: 24,
                  bottom: 120,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add ingredient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Autocomplete<Ingredient>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Ingredient>.empty();
                            }
                            return _ctrl.allIngredients.where((ing) =>
                                ing.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          displayStringForOption: (ing) => ing.name,
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            controller.text = _searchController.text;
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Search ingredients...',
                              ),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                child: Container(
                                  width: 300,
                                  color: Colors.white,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final ing = options.elementAt(index);
                                      return ListTile(
                                        title: Text(ing.name),
                                        subtitle: Text(
                                            'C:${ing.carbonContent ?? 0} N:${ing.nitrogenContent ?? 0} M:${ing.moistureContent ?? 0}'),
                                        onTap: () {
                                          onSelected(ing);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          onSelected: (ing) {
                            _ctrl.addIngredient(ing);
                            _searchController.clear();
                          },
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView(
                            children: _ctrl.selected.entries.map((e) {
                              final ing = e.key;
                              final qty = e.value;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(ing.name),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () => _ctrl.changeQuantity(ing, -1.0),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final controller = TextEditingController(text: qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2));
                                          final result = await showDialog<double>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text('Edit Quantity for ${ing.name}'),
                                              content: TextField(
                                                controller: controller,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                decoration: const InputDecoration(
                                                  hintText: 'Enter quantity (e.g., 12.50)',
                                                ),
                                                autofocus: true,
                                                onSubmitted: (val) {
                                                  final valDouble = double.tryParse(val);
                                                  Navigator.pop(ctx, valDouble);
                                                },
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    final valDouble = double.tryParse(controller.text);
                                                    Navigator.pop(ctx, valDouble);
                                                  },
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (result != null && result > 0) {
                                            _ctrl.setQuantity(ing, double.parse(result.toStringAsFixed(2)));
                                          } else if (result != null && result <= 0) {
                                            _ctrl.setQuantity(ing, 0); // removes it
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade400),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () => _ctrl.changeQuantity(ing, 1.0),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Totals card
                Positioned(
                  left: 24,
                  bottom: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total C: ${_ctrl.totalCarbon.toStringAsFixed(2)}'),
                      Text('Total N: ${_ctrl.totalNitrogen.toStringAsFixed(2)}'),
                      Text('Moisture: ${_ctrl.moisture.toStringAsFixed(2)}%'),
                      Row(
                        children: [
                          Text('C:N ${_ctrl.ratioLabel}'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _ctrl.ratioColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _ctrl.ratioStatus,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_ctrl.suggestion, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),

                // Save Button (close selection screen and return selection)
                Positioned(
                  left: 142,
                  top: 752,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, _ctrl.selected),
                    child: Container(
                      width: 126,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF005428), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
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

}
