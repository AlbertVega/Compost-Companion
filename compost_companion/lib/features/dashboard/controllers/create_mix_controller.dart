import 'package:flutter/material.dart';
import 'package:compost_companion/data/models/ingredient.dart';
import 'package:compost_companion/data/services/compost_service.dart';

/// Manages state for the "Create / Build a Mix" screen.
class CreateMixController extends ChangeNotifier {
  final CompostService _service;

  CreateMixController({CompostService? service}) : _service = service ?? CompostService();

  bool loading = false;
  List<Ingredient> allIngredients = [];
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

  void addIngredient(Ingredient ing) {
    if (_selected.containsKey(ing)) {
      _selected[ing] = _selected[ing]! + 1;
    } else {
      _selected[ing] = 1;
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
    if (r < 25) return 'Bad';
    if (r <= 30) return 'Good';
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
      case 'Bad':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
