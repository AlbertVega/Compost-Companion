import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:compost_companion/data/models/ingredient.dart';
import 'package:compost_companion/features/dashboard/controllers/create_mix_controller.dart';

import 'notification_screen.dart';
import 'ingredient_create_screen.dart';
import 'review_screen.dart';

class CreateScreen extends StatefulWidget {
  final Function(String) onSave;
  final VoidCallback? onFlowCompleted;
  const CreateScreen({super.key, required this.onSave, this.onFlowCompleted});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final CreateMixController _controller = CreateMixController();
  final TextEditingController _searchController = TextEditingController();
  late final VoidCallback _controllerListener;

  bool _showIngredientDropdown = false;

  List<Ingredient> get _filteredIngredients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _controller.allIngredients;
    }
    return _controller.allIngredients
        .where((ingredient) => ingredient.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _controllerListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _controller.addListener(_controllerListener);
    _controller.loadIngredients();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onAddIngredientTap() async {
    final createdIngredient = await Navigator.push<Ingredient>(
      context,
      MaterialPageRoute(builder: (context) => const IngredientCreateScreen()),
    );

    if (createdIngredient != null) {
      _controller.addAvailableIngredient(createdIngredient);
      _searchController.text = createdIngredient.name;
      setState(() {
        _showIngredientDropdown = true;
      });
    }
  }

  void _onIngredientSelected(Ingredient ingredient) {
    _controller.addIngredient(ingredient);
    _searchController.clear();
    setState(() {
      _showIngredientDropdown = false;
    });
  }

  void _onContinue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          onSave: widget.onSave,
          controller: _controller,
          onFlowCompleted: widget.onFlowCompleted,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
        Image.asset('assets/39-341.webp', width: 56, height: 56),
        const SizedBox(width: 10),
        const Text(
          'Compost Companion',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildProgressTabs() {
    return Column(
      children: [
        Container(height: 1, color: const Color(0xFF757575).withValues(alpha: 0.2)),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Ingredients',
              style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Opacity(
              opacity: 0.5,
              child: Text(
                'Review',
                style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
              ),
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
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 24),
            width: 102,
            height: 2,
            color: const Color(0xFF2F6F4E),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    return TextField(
      controller: _searchController,
      onTap: () {
        if (!_showIngredientDropdown) {
          setState(() {
            _showIngredientDropdown = true;
          });
        }
      },
      decoration: InputDecoration(
        hintText: 'Search ingredients...',
        prefixIcon: const Icon(Icons.search, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF2F6F4E)),
        ),
      ),
    );
  }

  Widget _buildIngredientDropdown() {
    if (!_showIngredientDropdown) {
      return const SizedBox.shrink();
    }

    final ingredients = _filteredIngredients;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ingredients.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No ingredients found'),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: ingredients.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
              itemBuilder: (context, index) {
                final ingredient = ingredients[index];
                return ListTile(
                  dense: true,
                  title: Text(ingredient.name),
                  subtitle: Text(
                    'C: ${ (ingredient.carbonContent ?? 0).toStringAsFixed(1) }  N: ${ (ingredient.nitrogenContent ?? 0).toStringAsFixed(1) }',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _onIngredientSelected(ingredient),
                );
              },
            ),
    );
  }

  Widget _buildSelectedIngredients() {
    final selectedEntries = _controller.selected.entries.toList();
    if (selectedEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No ingredients selected yet',
          style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 13),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
                IconButton(
                  onPressed: () => _controller.changeQuantity(ingredient, -1),
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
                Text(quantity.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                IconButton(
                  onPressed: () => _controller.changeQuantity(ingredient, 1),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
                IconButton(
                  onPressed: () => _controller.removeIngredient(ingredient),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNutrientCard({
    required String title,
    required String tag,
    required Color tagColor,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatesCard() {
    return Container(
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
            'Estimated Mix',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('C:N Ratio', style: TextStyle(fontSize: 14)),
              Text(_controller.ratioLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Moisture', style: TextStyle(fontSize: 14)),
              Text(
                '${_controller.moisture.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _controller.ratioColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _controller.ratioStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _controller.suggestion,
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildProgressTabs(),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Build a Mix',
                            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 4),
                          Opacity(
                            opacity: 0.5,
                            child: Text(
                              'Give your new compost pile a name',
                              style: TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _onAddIngredientTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          SvgPicture.asset('assets/75-206;54626-27715.svg', width: 24, height: 22),
                          const SizedBox(width: 4),
                          const Text(
                            'Add ingredient',
                            style: TextStyle(color: Color(0xFF2F6F4E), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchInput(),
                _buildIngredientDropdown(),
                const SizedBox(height: 12),
                _buildSelectedIngredients(),
                const SizedBox(height: 14),
                _buildNutrientCard(
                  title: 'Carbon Content',
                  tag: 'Green',
                  tagColor: const Color(0xFF2F6F4E),
                  value: _controller.totalCarbon.toStringAsFixed(1),
                ),
                const SizedBox(height: 10),
                _buildNutrientCard(
                  title: 'Nitrogen Content',
                  tag: 'Brown',
                  tagColor: const Color(0xFFD68D18),
                  value: _controller.totalNitrogen.toStringAsFixed(1),
                ),
                const SizedBox(height: 10),
                _buildEstimatesCard(),
                const SizedBox(height: 22),
                Center(
                  child: GestureDetector(
                    onTap: _onContinue,
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
