import 'fitness_service.dart';

/// Matches *optional* activity ideas with the selected food's nutrient profile,
/// portion count, and the user's chosen fitness level. These suggestions are
/// not calorie-offset prescriptions or medical guidance.
class MealActivityPick {
  final FitnessActivity activity;
  final String reason;
  final String tag;
  const MealActivityPick({
    required this.activity,
    required this.reason,
    required this.tag,
  });
}

class MealActivityPlanner {
  static String mealDescription({
    required double calories,
    required double protein,
    required double carbohydrates,
    required double fats,
  }) {
    if (protein >= 25 && protein >= carbohydrates * 0.35) {
      return 'This meal provides a useful amount of protein. You might enjoy some light strength work or a walk.';
    }
    if (carbohydrates >= 45) {
      return 'This meal contains carbohydrates. Walking, easy cycling or dancing can be fun ways to stay active.';
    }
    if (calories >= 650 || fats >= 25) {
      return 'This is a more substantial meal. Gentle movement may feel more comfortable when you are ready.';
    }
    return 'This meal can fit into an active day. Choose a movement you enjoy, at a comfortable pace.';
  }

  static List<MealActivityPick> suggestions({
    required double calories,
    required double protein,
    required double carbohydrates,
    required double fats,
    required String fitnessLevel,
    String goal = '',
  }) {
    final allowed = FitnessService.recommendedActivities(fitnessLevel);
    final scores = <String, int>{};
    for (final activity in allowed) {
      scores[activity.id] = 1;
    }

    void prefer(String id, int score) {
      if (scores.containsKey(id)) scores[id] = scores[id]! + score;
    }

    // After a substantial or fat-rich meal, prioritize gentle choices rather
    // than intense sessions. No activity is prescribed to "burn off" a food.
    if (calories >= 650 || fats >= 25) {
      prefer('walk', 9);
      prefer('stretch', 8);
      prefer('yoga', 6);
      prefer('cycle', 4);
    } else if (protein >= 25 && protein >= carbohydrates * 0.35) {
      prefer('home_beginner', 9);
      prefer('bodyweight', 8);
      prefer('home_strength', 7);
      prefer('walk', 5);
      prefer('core', 4);
    } else if (carbohydrates >= 45) {
      prefer('cycle', 9);
      prefer('walk', 8);
      prefer('dance', 7);
      prefer('home_beginner', 4);
    } else {
      prefer('walk', 9);
      prefer('yoga', 7);
      prefer('home_beginner', 6);
      prefer('dance', 5);
    }

    if (goal == 'gain' || goal == 'gain_weight' || goal == 'gain weight') {
      prefer('home_strength', 5);
      prefer('bodyweight', 5);
      prefer('home_beginner', 5);
    }
    if (goal == 'maintain' || goal == 'maintain_weight' || goal == 'maintain weight') {
      prefer('walk', 3);
      prefer('yoga', 3);
    }

    final ranked = [...allowed]
      ..sort((a, b) {
        final byScore = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
        return byScore != 0 ? byScore : a.name.compareTo(b.name);
      });

    return ranked.take(5).map((activity) {
      switch (activity.id) {
        case 'walk':
          return MealActivityPick(
            activity: activity,
            tag: 'Low impact',
            reason: 'A relaxed way to move, whenever you feel comfortable.',
          );
        case 'cycle':
          return MealActivityPick(
            activity: activity,
            tag: 'Cardio',
            reason: carbohydrates >= 45
                ? 'An enjoyable cardio option for your active day.'
                : 'Gentle movement at a comfortable pace.',
          );
        case 'home_beginner':
        case 'bodyweight':
        case 'home_strength':
        case 'core':
          return MealActivityPick(
            activity: activity,
            tag: 'Home workout',
            reason: protein >= 25
                ? 'A light strength option to pair with your fitness routine.'
                : 'Build a sustainable routine at home, at your own pace.',
          );
        case 'stretch':
        case 'yoga':
          return MealActivityPick(
            activity: activity,
            tag: 'Recovery',
            reason: 'An easy-going option for mobility and relaxation.',
          );
        default:
          return MealActivityPick(
            activity: activity,
            tag: 'Stay active',
            reason: 'Choose a comfortable session when it suits you.',
          );
      }
    }).toList();
  }
}
