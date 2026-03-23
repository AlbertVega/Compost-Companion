import 'package:compost_companion/data/models/pile_ingredient_selection.dart';

class PileIngredientStore {
  static final PileIngredientStore _instance = PileIngredientStore._internal();

  factory PileIngredientStore() => _instance;

  PileIngredientStore._internal();

  final Map<int, List<PileIngredientSelection>> _ingredientsByPileId = {};

  void savePileIngredients(int pileId, Map<String, double> ingredientSummary) {
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
  }

  List<PileIngredientSelection> getPileIngredients(int pileId) {
    return List.unmodifiable(_ingredientsByPileId[pileId] ?? const []);
  }
}