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

  Map<Ingredient, int> get selected => Map.unmodifiable(_selected);

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
    notifyListeners();
  }

  double get totalCarbon {
    double sum = 0;
    _selected.forEach((ing, qty) {
      sum += (ing.carbonContent ?? 0) * qty;
    });
    return sum;
  }

  double get totalNitrogen {
    double sum = 0;
    _selected.forEach((ing, qty) {
      sum += (ing.nitrogenContent ?? 0) * qty;
    });
    return sum;
  }

  double get moisture {
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
    if (totalNitrogen == 0) return 0;
    return totalCarbon / totalNitrogen;
  }

  String get ratioLabel {
    final ratio = cnRatio;
    if (ratio == 0) return '—';
    return '${ratio.toStringAsFixed(1)}:1';
  }

  String get ratioStatus {
    final r = cnRatio;
    if (r == 0) return '—';
    if (r >= 25 && r <= 30) return 'Good';
    if (r >= 20 && r < 25) return 'Acceptable';
    if (r > 30 && r <= 35) return 'Acceptable';
    return 'Bad';
  }

  String get suggestion {
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

  Future<void> createNewPile({
    required String mixName,
    required String location,
  }) async {
    saving = true;
    saveError = null;
    notifyListeners();

    try {
      await _service.createCompostPile(
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
}
