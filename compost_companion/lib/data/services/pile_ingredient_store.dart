import 'dart:convert';
import 'package:compost_companion/data/models/pile_ingredient_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PileIngredientStore {
  static final PileIngredientStore _instance = PileIngredientStore._internal();

  factory PileIngredientStore() => _instance;

  PileIngredientStore._internal();
  static const String _storageKey = 'pile_ingredients_by_pile_id_v1';

  final Map<int, List<PileIngredientSelection>> _ingredientsByPileId = {};
  Future<void>? _loadFuture;

  Future<void> _ensureLoaded() {
    return _loadFuture ??= _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      _ingredientsByPileId.clear();
      decoded.forEach((pileIdStr, value) {
        final pileId = int.tryParse(pileIdStr);
        if (pileId == null || value is! List) {
          return;
        }

        final selections = <PileIngredientSelection>[];
        for (final item in value) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          final ingredientName = item['ingredient_name'];
          final quantityValue = item['quantity'];
          if (ingredientName is! String || quantityValue is! num) {
            continue;
          }
          selections.add(
            PileIngredientSelection(
              ingredientName: ingredientName,
              quantity: quantityValue.toDouble(),
            ),
          );
        }

        _ingredientsByPileId[pileId] = selections;
      });
    } catch (_) {
      // Corrupted/invalid data should not break app usage.
      _ingredientsByPileId.clear();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    final data = <String, List<Map<String, dynamic>>>{};
    _ingredientsByPileId.forEach((pileId, selections) {
      data['$pileId'] = selections
          .map(
            (selection) => {
              'ingredient_name': selection.ingredientName,
              'quantity': selection.quantity,
            },
          )
          .toList();
    });

    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> savePileIngredients(int pileId, Map<String, double> ingredientSummary) async {
    await _ensureLoaded();

    final selections = ingredientSummary.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => PileIngredientSelection(
            ingredientName: entry.key,
            quantity: entry.value,
          ),
        )
        .toList();

    _ingredientsByPileId[pileId] = selections;
    await _persist();
  }

  Future<List<PileIngredientSelection>> getPileIngredients(int pileId) async {
    await _ensureLoaded();
    return List.unmodifiable(_ingredientsByPileId[pileId] ?? const []);
  }
  Future<void> deletePileIngredients(int pileId) async {
    await _ensureLoaded();
    _ingredientsByPileId.remove(pileId);
    await _persist();
  }

  Future<void> clearAllPileIngredients() async {
    await _ensureLoaded();
    _ingredientsByPileId.clear();
    await _persist();
  }
}