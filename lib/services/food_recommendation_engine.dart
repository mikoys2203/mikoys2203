// FastFit V19: local, explainable food ranking.
// No AI API, Cloud Functions, paid services, or new Firestore collection.

class FoodRecommendation {
  final String id;
  final Map<String, dynamic> food;
  final String restaurantName;
  final double score;
  final String explanation;

  const FoodRecommendation({
    required this.id,
    required this.food,
    required this.restaurantName,
    required this.score,
    required this.explanation,
  });
}

class FoodRecommendationEngine {
  static double amount(dynamic input) {
    if (input is num && input.isFinite && input >= 0) {
      return input.toDouble();
    }
    return 0;
  }

  static double _clamp(double number) => number.clamp(0.0, 1.0).toDouble();

  /// Scores are relative *only* to the available approved menu.
  /// A larger score does NOT establish that an item is medically healthier.
  static List<FoodRecommendation> rank({
    required Map<String, Map<String, dynamic>> foods,
    required Map<String, String> restaurantNames,
    required String fitnessGoal,
  }) {
    final valid = foods.entries.where((entry) {
      final food = entry.value;
      final restaurantId = food['restaurantId']?.toString() ?? '';
      return food['approvalStatus'] == 'approved' &&
          restaurantNames.containsKey(restaurantId) &&
          (food['name']?.toString().trim().isNotEmpty ?? false) &&
          (food['calories'] is num) &&
          (food['protein'] is num) &&
          (food['carbohydrates'] is num) &&
          (food['fats'] is num) &&
          amount(food['calories']) > 0;
    }).toList();

    if (valid.isEmpty) return [];

    var maxCalories = 1.0;
    var maxProtein = 1.0;
    var maxDensity = 1.0;

    for (final entry in valid) {
      final food = entry.value;
      final kcal = amount(food['calories']);
      final protein = amount(food['protein']);
      if (kcal > maxCalories) maxCalories = kcal;
      if (protein > maxProtein) maxProtein = protein;
      final density = protein * 100 / kcal;
      if (density > maxDensity) maxDensity = density;
    }

    final results = valid.map((entry) {
      final food = entry.value;
      final calories = amount(food['calories']);
      final protein = amount(food['protein']);
      final density = protein * 100 / calories;
      final kcalPortion = _clamp(calories / maxCalories);
      final proteinPortion = _clamp(protein / maxProtein);
      final densityPortion = _clamp(density / maxDensity);

      late final double score;
      late final String explanation;
      switch (fitnessGoal) {
        case 'lose weight':
          score = 100.0 * (0.45 * (1 - kcalPortion) +
              0.35 * densityPortion + 0.20 * proteinPortion);
          explanation = 'Relative lower energy and protein per serving';
          break;
        case 'gain weight':
          score = 100.0 * (0.45 * kcalPortion +
              0.35 * proteinPortion + 0.20 * densityPortion);
          explanation = 'More energy and protein per serving';
          break;
        default:
          score = 100.0 * (0.45 * densityPortion +
              0.35 * proteinPortion + 0.20 * (1 - kcalPortion));
          explanation = 'Protein-focused comparison within this menu';
          break;
      }

      return FoodRecommendation(
        id: entry.key,
        food: food,
        restaurantName:
            restaurantNames[food['restaurantId']?.toString() ?? ''] ??
                'Restaurant',
        score: score,
        explanation: explanation,
      );
    }).toList();

    results.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) return scoreOrder;
      return a.food['name'].toString().compareTo(b.food['name'].toString());
    });
    return results;
  }
}
