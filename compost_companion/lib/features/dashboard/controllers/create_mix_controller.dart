import 'dart:async';
import 'package:flutter/material.dart';
import 'package:compost_companion/data/models/ingredient.dart';
import 'package:compost_companion/data/models/compost_pile.dart';
import 'package:compost_companion/data/services/compost_service.dart';

/// Manages state for the "Create / Build a Mix" screen.
class CreateMixController extends ChangeNotifier {
  final CompostService _service;

  CreateMixController({CompostService? service}) : _service = service ?? CompostService();

  bool loading = false;
  bool saving = false;
  String? saveError;
  bool loadingPiles = false;
  List<Ingredient> allIngredients = [];
  List<CompostPile> existingPiles = [];
  /// map ingredient -> quantity
  final Map<Ingredient, int> _selected = {};

  Map<String, dynamic>? expertEvaluation;
  bool evaluating = false;
  Timer? _debounce;

  Map<Ingredient, int> get selected => Map.unmodifiable(_selected);

  Map<String, int> get selectedIngredientSummary {
    final Map<String, int> summary = {};
    _selected.forEach((ingredient, quantity) {
      summary[ingredient.name] = quantity;
    });
    return summary;
  }

  Future<void> loadIngredients() async {
    loading = true;
    notifyListeners();
    try {
      allIngredients = await _service.fetchIngredients();
    } catch (e) {
      // ignore/errors can be bubbled by callers
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadExistingPiles() async {
    loadingPiles = true;
    notifyListeners();
    try {
      existingPiles = await _service.fetchMyPiles();
    } catch (_) {
      existingPiles = [];
    } finally {
      loadingPiles = false;
      notifyListeners();
    }
  }

  void addIngredient(Ingredient ing) {
    if (_selected.containsKey(ing)) {
      _selected[ing] = _selected[ing]! + 1;
    } else {
      _selected[ing] = 1;
    }
    _triggerEvaluation();
    notifyListeners();
  }

  void addAvailableIngredient(Ingredient ingredient) {
    final existingIndex = allIngredients.indexWhere(
      (item) => item.name.toLowerCase() == ingredient.name.toLowerCase(),
    );

    if (existingIndex >= 0) {
      allIngredients[existingIndex] = ingredient;
    } else {
      allIngredients = [...allIngredients, ingredient];
    }
    notifyListeners();
  }

  void removeIngredient(Ingredient ing) {
    _selected.remove(ing);
    _triggerEvaluation();
    notifyListeners();
  }

  void changeQuantity(Ingredient ing, int delta) {
    if (!_selected.containsKey(ing)) return;
    final newQty = _selected[ing]! + delta;
    if (newQty <= 0) {
      _selected.remove(ing);
    } else {
      _selected[ing] = newQty;
    }
    _triggerEvaluation();
    notifyListeners();
  }

  void clearSelectedIngredients() {
    _selected.clear();
    _triggerEvaluation();
    notifyListeners();
  }

  void _triggerEvaluation() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_selected.isEmpty) {
        expertEvaluation = null;
        evaluating = false;
        notifyListeners();
        return;
      }
      
      evaluating = true;
      notifyListeners();
      
      try {
        expertEvaluation = await _service.evaluateRecipe(_selected, allIngredients);
      } catch (e) {
        print('Error evaluating recipe: $e');
        expertEvaluation = null;
      } finally {
        evaluating = false;
        notifyListeners();
      }
    });
  }

  double get totalCarbon {
    if (expertEvaluation != null && expertEvaluation!['total_carbon_weight'] != null) {
      return (expertEvaluation!['total_carbon_weight'] as num).toDouble();
    }
    double sum = 0;
    _selected.forEach((ing, qty) {
      sum += (ing.carbonContent ?? 0) * qty;
    });
    return sum;
  }

  double get totalNitrogen {
    if (expertEvaluation != null && expertEvaluation!['total_nitrogen_weight'] != null) {
      return (expertEvaluation!['total_nitrogen_weight'] as num).toDouble();
    }
    double sum = 0;
    _selected.forEach((ing, qty) {
      sum += (ing.nitrogenContent ?? 0) * qty;
    });
    return sum;
  }

  double get moisture {
    if (expertEvaluation != null && expertEvaluation!['calculated_moisture_percent'] != null) {
      return (expertEvaluation!['calculated_moisture_percent'] as num).toDouble();
    }
    double totalMoisture = 0;
    int totalQty = 0;
    _selected.forEach((ing, qty) {
      totalMoisture += (ing.moistureContent ?? 0) * qty;
      totalQty += qty;
    });
    return totalQty > 0 ? totalMoisture / totalQty : 0;
  }

  double get totalVolume {
    int totalQty = 0;
    _selected.forEach((_, qty) {
      totalQty += qty;
    });
    return totalQty.toDouble();
  }

  double get cnRatio {
    if (expertEvaluation != null && expertEvaluation!['calculated_cn_ratio'] != null) {
      return (expertEvaluation!['calculated_cn_ratio'] as num).toDouble();
    }
    if (totalNitrogen == 0) return 0;
    return totalCarbon / totalNitrogen;
  }

  String get ratioLabel {
    final ratio = cnRatio;
    if (ratio == 0) return '—';
    return '${ratio.toStringAsFixed(2)}:1';
  }

  String get ratioStatus {
    final r = cnRatio;
    if (r == 0) return '—';
    if (r >= 25 && r <= 30) return 'Good';
    if (r >= 15 && r < 25) return 'Acceptable';
    if (r > 30 && r <= 35) return 'Acceptable';
    return 'Bad';
  }

  String get suggestion {
    if (evaluating) {
      return 'Analyzing recipe...';
    }

    if (expertEvaluation != null && expertEvaluation!['suggestions'] != null) {
      final suggestionsList = expertEvaluation!['suggestions'] as List;
      if (suggestionsList.isNotEmpty) {
        // Return the recommendation from the highest severity issue
        // or just the first suggestion
        return suggestionsList.first['recommendation'].toString();
      }
    }

    final r = cnRatio;
    if (r == 0) return '';
    if (r < 25) return 'Add carbon-rich ingredients';
    if (r > 30) return 'Add nitrogen-rich ingredients';
    return 'Composition is balanced';
  }

  Color get ratioColor {
    switch (ratioStatus) {
      case 'Good':
        return Colors.green;
      case 'Acceptable':
        return Colors.orange;
      case 'Bad':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<CompostPile> createNewPile({
    required String mixName,
    required String location,
  }) async {
    saving = true;
    saveError = null;
    notifyListeners();

    try {
      return await _service.createCompostPile(
        name: mixName,
        volumeAtCreation: totalVolume,
        location: location,
      );
    } catch (e) {
      saveError = e.toString();
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
