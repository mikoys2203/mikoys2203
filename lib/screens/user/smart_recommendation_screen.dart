import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/customer_service.dart';
import '../../services/fitness_service.dart';
import '../../services/food_recommendation_engine.dart';
import 'food_details_screen.dart';
import 'fitness_hub_screen.dart';

/// V19: Food recommendations + exercise suggestions + a weekly movement plan.
/// Only uses Firestore paths already covered by the FastFit V18 rules.
class SmartRecommendationScreen extends StatefulWidget {
  const SmartRecommendationScreen({super.key});

  @override
  State<SmartRecommendationScreen> createState() =>
      _SmartRecommendationScreenState();
}

class _SmartRecommendationScreenState extends State<SmartRecommendationScreen>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  final customer = CustomerService();
  final fitness = FitnessService();

  late final TabController tabs;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> fitnessStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> foodsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> restaurantsStream;

  String search = '';
  String category = 'All';
  String sortBy = 'My goal';
  String? referenceFoodId;
  int exerciseMinutes = 20;
  String? busyFoodId;
  String? busyActivityId;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    profileStream = db.collection('users').doc(uid).snapshots();
    fitnessStream = db
        .collection('users')
        .doc(uid)
        .collection('fitness_settings')
        .doc('profile')
        .snapshots();
    foodsStream = db
        .collection('food_items')
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
    restaurantsStream = db
        .collection('restaurants')
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  void notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> logMeal(FoodRecommendation suggestion) async {
    if (busyFoodId != null) return;
    var quantity = 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record a meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(suggestion.food['name']?.toString() ?? 'Food'),
              const SizedBox(height: 12),
              const Text('How many servings did you eat?'),
              DropdownButton<int>(
                value: quantity,
                items: List.generate(
                  5,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => quantity = value);
                  }
                },
              ),
              const Text(
                'Only record food you actually consumed.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add to history'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => busyFoodId = suggestion.id);
    try {
      await customer.logMeal(
        foodId: suggestion.id,
        foodName: suggestion.food['name']?.toString() ?? 'Food',
        restaurantName: suggestion.restaurantName,
        calories: FoodRecommendationEngine.amount(suggestion.food['calories']),
        quantity: quantity,
      );
      notice('Meal saved to your history.');
    } catch (error) {
      notice('Could not save meal: $error');
    } finally {
      if (mounted) setState(() => busyFoodId = null);
    }
  }

  Future<void> toggleFavorite(String foodId, bool saved) async {
    if (busyFoodId != null) return;
    setState(() => busyFoodId = foodId);
    try {
      await customer.toggleFavorite(foodId, saved);
      notice(saved ? 'Removed from favorites.' : 'Saved to favorites.');
    } catch (error) {
      notice('Unable to update favorite: $error');
    } finally {
      if (mounted) setState(() => busyFoodId = null);
    }
  }

  Future<void> recordExercise(
    FitnessActivity activity,
    double weightKg,
    int duration,
  ) async {
    if (busyActivityId != null) return;
    final didFinish = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log completed workout?'),
        content: Text(
          'Only save this after finishing $duration minutes of ${activity.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('I completed it'),
          ),
        ],
      ),
    );
    if (didFinish != true || !mounted) return;

    setState(() => busyActivityId = activity.id);
    try {
      await fitness.logWorkout(
        activity: activity,
        minutes: duration,
        weightKg: weightKg,
      );
      notice('${activity.name} added to workout history.');
    } catch (error) {
      notice('Could not save workout: $error');
    } finally {
      if (mounted) setState(() => busyActivityId = null);
    }
  }

  Widget _sectionTitle(String title, [String? detail]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (detail != null) ...[
            const SizedBox(height: 5),
            Text(detail, style: const TextStyle(color: Colors.black54)),
          ],
        ],
      ),
    );
  }

  String _goalName(String goal) {
    switch (goal) {
      case 'lose weight':
        return 'Lose weight';
      case 'gain weight':
        return 'Gain weight';
      default:
        return 'Maintain weight';
    }
  }

  Widget _foodImage(String imageUrl) {
    if (!imageUrl.startsWith('https://')) {
      return const ColoredBox(
        color: Color(0xFFFFEEEE),
        child: Center(child: Icon(Icons.fastfood, color: Colors.red, size: 48)),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Color(0xFFFFEEEE),
        child: Center(child: Icon(Icons.fastfood, color: Colors.red, size: 48)),
      ),
    );
  }

  Widget _foodCard(FoodRecommendation suggestion) {
    final food = suggestion.food;
    final kcal = FoodRecommendationEngine.amount(food['calories']);
    final protein = FoodRecommendationEngine.amount(food['protein']);
    final carb = FoodRecommendationEngine.amount(food['carbohydrates']);
    final fats = FoodRecommendationEngine.amount(food['fats']);
    final name = food['name']?.toString() ?? 'Food';
    final busy = busyFoodId != null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 124,
            width: double.infinity,
            child: _foodImage(food['imageUrl']?.toString() ?? ''),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 3),
                Text(suggestion.restaurantName,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 6),
                Text('Serving: ${food['servingSize'] ?? 'Not specified'}',
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 9),
                Text('${kcal.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                Text('Protein ${protein.toStringAsFixed(1)}g  •  '
                    'Carbs ${carb.toStringAsFixed(1)}g  •  '
                    'Fat ${fats.toStringAsFixed(1)}g',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Text(suggestion.explanation,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const Divider(height: 24),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FoodDetailsScreen(
                                    foodId: suggestion.id,
                                    food: food,
                                    restaurantName: suggestion.restaurantName,
                                  ),
                                ),
                              ),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                    ),
                    TextButton.icon(
                      onPressed: busy ? null : () => logMeal(suggestion),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Log'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => referenceFoodId = suggestion.id);
                        tabs.animateTo(1);
                      },
                      icon: const Icon(Icons.directions_run, size: 18),
                      label: const Text('Exercise'),
                    ),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: customer.isFavorite(suggestion.id),
                      builder: (context, snapshot) {
                        final saved = snapshot.data?.exists ?? false;
                        return IconButton(
                          tooltip: saved ? 'Remove favorite' : 'Add favorite',
                          onPressed: snapshot.hasData && !busy
                              ? () => toggleFavorite(suggestion.id, saved)
                              : null,
                          icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _foodRecommendations(
    List<FoodRecommendation> ranked,
    String goal,
  ) {
    final categories = <String>{'All'};
    for (final suggestion in ranked) {
      final c = suggestion.food['category']?.toString().trim() ?? '';
      if (c.isNotEmpty) categories.add(c);
    }
    final chosenCategory = categories.contains(category) ? category : 'All';
    final items = ranked.where((suggestion) {
      final food = suggestion.food;
      final name = food['name']?.toString().toLowerCase() ?? '';
      final restaurant = suggestion.restaurantName.toLowerCase();
      final matchesText = name.contains(search) || restaurant.contains(search);
      return matchesText &&
          (chosenCategory == 'All' || food['category'] == chosenCategory);
    }).toList();

    if (sortBy == 'Lower calories') {
      items.sort((a, b) => FoodRecommendationEngine.amount(a.food['calories'])
          .compareTo(FoodRecommendationEngine.amount(b.food['calories'])));
    } else if (sortBy == 'More protein') {
      items.sort((a, b) => FoodRecommendationEngine.amount(b.food['protein'])
          .compareTo(FoodRecommendationEngine.amount(a.food['protein'])));
    } else if (sortBy == 'More calories') {
      items.sort((a, b) => FoodRecommendationEngine.amount(b.food['calories'])
          .compareTo(FoodRecommendationEngine.amount(a.food['calories'])));
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionTitle('Food recommendations',
            'Goal: ${_goalName(goal)} • Based on currently approved restaurant menu items.'),
        const Card(
          color: Color(0xFFFFF5F5),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Recommendations compare calories and protein within the available menu. '
              'They are not a medical or dietary prescription. Consider serving size, '
              'variety, allergies, and verified nutrition sources.',
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search foods or restaurants',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (text) => setState(() => search = text.toLowerCase().trim()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: chosenCategory,
              items: categories.map((c) => DropdownMenuItem(
                value: c, child: Text(c, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (c) => setState(() => category = c ?? 'All'),
            ),
            DropdownButton<String>(
              value: sortBy,
              items: const [
                DropdownMenuItem(value: 'My goal', child: Text('For my goal')),
                DropdownMenuItem(value: 'Lower calories', child: Text('Lower calories')),
                DropdownMenuItem(value: 'More protein', child: Text('More protein')),
                DropdownMenuItem(value: 'More calories', child: Text('More calories')),
              ],
              onChanged: (s) => setState(() => sortBy = s ?? 'My goal'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('${items.length} matching approved foods',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: Text('No matching foods. Try a different search or filter.')),
          )
        else
          LayoutBuilder(
            builder: (context, size) {
              final cols = size.maxWidth >= 980 ? 3 : (size.maxWidth >= 630 ? 2 : 1);
              const gap = 12.0;
              final width = (size.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final suggestion in items)
                    SizedBox(width: width, child: _foodCard(suggestion)),
                ],
              );
            },
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _exerciseTab(
    List<FoodRecommendation> ranked,
    double weightKg,
    String fitnessLevel,
  ) {
    final suitable = FitnessService.recommendedActivities(fitnessLevel);
    final foodReference = ranked.any((f) => f.id == referenceFoodId)
        ? ranked.firstWhere((f) => f.id == referenceFoodId)
        : (ranked.isEmpty ? null : ranked.first);
    final foodCalories = foodReference == null
        ? 0.0
        : FoodRecommendationEngine.amount(foodReference.food['calories']);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionTitle('Exercise recommendations',
            'Choose an enjoyable activity appropriate to your abilities.'),
        if (weightKg <= 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('Set your weight in your FastFit profile to see personalized estimates.'),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FitnessHubScreen())),
                    child: const Text('Open Fitness Hub'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Card(
            color: const Color(0xFFFFF4F4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text('Weight: ${weightKg.toStringAsFixed(1)} kg'),
                  Text('Experience: $fitnessLevel'),
                  const Text('Estimates use the MET method.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (foodReference != null) ...[
            const Text('Optional food-energy reference',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(foodReference.id),
              initialValue: foodReference.id,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ranked.map((item) => DropdownMenuItem(
                value: item.id,
                child: Text('${item.food['name']} • '
                    '${FoodRecommendationEngine.amount(item.food['calories']).toStringAsFixed(0)} kcal',
                    overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (id) => setState(() => referenceFoodId = id),
            ),
            const SizedBox(height: 7),
            const Text(
              'Food energy is shown for context only; you do not need to exercise to compensate for eating.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 18),
          ],
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              const Text('Session duration:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: exerciseMinutes,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  DropdownMenuItem(value: 20, child: Text('20 minutes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  DropdownMenuItem(value: 45, child: Text('45 minutes')),
                  DropdownMenuItem(value: 60, child: Text('60 minutes')),
                ],
                onChanged: (value) => setState(() => exerciseMinutes = value ?? 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final activity in suitable)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(activity.icon, color: Colors.red, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activity.name, style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                              Text(activity.description),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('~${FitnessService.calculateCalories(
                      met: activity.met,
                      weightKg: weightKg,
                      minutes: exerciseMinutes,
                    ).toStringAsFixed(0)} kcal estimated for $exerciseMinutes minutes',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    if (foodCalories > 0) ...[
                      const SizedBox(height: 3),
                      Builder(builder: (_) {
                        final perMinute = FitnessService.calculateCalories(
                          met: activity.met, weightKg: weightKg, minutes: 1);
                        final comparableMinutes = perMinute > 0
                            ? (foodCalories / perMinute).ceil()
                            : 0;
                        return Text(
                          'Numerical food-energy equivalent: '
                          '${comparableMinutes > 180 ? 'over 180' : comparableMinutes} min '
                          '(not an exercise target)',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        );
                      }),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: busyActivityId != null
                            ? null
                            : () => recordExercise(activity, weightKg, exerciseMinutes),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Log if completed'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Calorie burn is approximate. If you have symptoms, injuries, or activity limitations, '
              'choose a suitable activity and seek qualified guidance when needed.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  List<({String day, String? activityId, int minutes, String note})>
      _weekPlan(String level) {
    if (level == 'advanced') {
      return [
        (day: 'Monday', activityId: 'jog', minutes: 20, note: 'Easy pace + warm-up'),
        (day: 'Tuesday', activityId: 'bodyweight', minutes: 30, note: 'Strength + breaks'),
        (day: 'Wednesday', activityId: null, minutes: 0, note: 'Rest or light mobility'),
        (day: 'Thursday', activityId: 'cycle', minutes: 45, note: 'Comfortable cycling'),
        (day: 'Friday', activityId: 'jog', minutes: 30, note: 'Steady pace'),
        (day: 'Saturday', activityId: 'walk', minutes: 30, note: 'Recovery walk'),
        (day: 'Sunday', activityId: null, minutes: 0, note: 'Rest day'),
      ];
    }
    if (level == 'intermediate') {
      return [
        (day: 'Monday', activityId: 'walk', minutes: 30, note: 'Comfortable walk'),
        (day: 'Tuesday', activityId: 'bodyweight', minutes: 20, note: 'Light strength'),
        (day: 'Wednesday', activityId: null, minutes: 0, note: 'Rest or stretching'),
        (day: 'Thursday', activityId: 'cycle', minutes: 30, note: 'Relaxed cycling'),
        (day: 'Friday', activityId: 'walk', minutes: 30, note: 'Walking outdoors'),
        (day: 'Saturday', activityId: 'bodyweight', minutes: 20, note: 'Movement session'),
        (day: 'Sunday', activityId: null, minutes: 0, note: 'Rest day'),
      ];
    }
    return [
      (day: 'Monday', activityId: 'walk', minutes: 20, note: 'Comfortable start'),
      (day: 'Tuesday', activityId: 'walk', minutes: 20, note: 'Easy movement'),
      (day: 'Wednesday', activityId: null, minutes: 0, note: 'Rest or gentle stretches'),
      (day: 'Thursday', activityId: 'cycle', minutes: 20, note: 'Easy cycling'),
      (day: 'Friday', activityId: 'walk', minutes: 20, note: 'Comfortable walk'),
      (day: 'Saturday', activityId: 'dance', minutes: 15, note: 'Enjoyable movement'),
      (day: 'Sunday', activityId: null, minutes: 0, note: 'Rest day'),
    ];
  }

  Widget _weeklyPlan(String level, double weight) {
    final plan = _weekPlan(level);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _sectionTitle('Your 7-day movement plan',
            'An optional, adaptable example for $level activity experience.'),
        const Card(
          color: Color(0xFFFFF4F4),
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Text('Start with less if needed, warm up, take rest days, and '
                'adjust duration to your comfort. These are suggestions, not medical advice.'),
          ),
        ),
        const SizedBox(height: 12),
        for (final day in plan)
          Builder(builder: (context) {
            FitnessActivity? activity;
            for (final item in FitnessService.activities) {
              if (item.id == day.activityId) activity = item;
            }
            final selected = activity;
            return Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFE9E9),
                  child: Icon(selected?.icon ?? Icons.spa, color: Colors.red),
                ),
                title: Text(day.day, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(selected == null
                    ? day.note
                    : '${selected.name} • ${day.minutes} min • ${day.note}'),
                trailing: selected == null || weight <= 0
                    ? null
                    : IconButton(
                        tooltip: 'Log only after completing this workout',
                        onPressed: busyActivityId != null
                            ? null
                            : () => recordExercise(selected, weight, day.minutes),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.red),
                      ),
              ),
            );
          }),
        const SizedBox(height: 12),
        const Text(
          'This plan is not automatically scheduled and does not claim the activities were completed. '
          'Tap the check icon only after finishing a session.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _todayPanel() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: customer.mealHistory(),
      builder: (context, mealSnapshot) {
        if (mealSnapshot.hasError) {
          return Center(child: Text('Meal history error: ${mealSnapshot.error}'));
        }
        if (!mealSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: fitness.workouts(),
          builder: (context, workoutSnapshot) {
            if (workoutSnapshot.hasError) {
              return Center(child: Text('Workout history error: ${workoutSnapshot.error}'));
            }
            if (!workoutSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final today = DateTime.now();
            final meals = mealSnapshot.data!.docs.where((doc) {
              final stamp = doc.data()['loggedAt'];
              return stamp is Timestamp &&
                  DateUtils.isSameDay(stamp.toDate().toLocal(), today);
            }).toList();
            final workouts = workoutSnapshot.data!.docs.where((doc) {
              final stamp = doc.data()['completedAt'];
              return stamp is Timestamp &&
                  DateUtils.isSameDay(stamp.toDate().toLocal(), today);
            }).toList();
            var loggedCalories = 0.0;
            var activityCalories = 0.0;
            var minutes = 0;
            for (final meal in meals) {
              loggedCalories += FoodRecommendationEngine.amount(meal.data()['calories']);
            }
            for (final workout in workouts) {
              activityCalories += FoodRecommendationEngine.amount(
                  workout.data()['estimatedCalories']);
              final duration = workout.data()['minutes'];
              if (duration is int) minutes += duration;
            }
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _sectionTitle('Your day',
                    'Records for today only — not an estimate of your total daily intake or needs.'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _summary('Meal entries', '${meals.length}', Icons.restaurant),
                    _summary('Recorded food energy',
                        '${loggedCalories.toStringAsFixed(0)} kcal', Icons.fastfood),
                    _summary('Exercise minutes', '$minutes min', Icons.timer),
                    _summary('Estimated activity energy',
                        '${activityCalories.toStringAsFixed(0)} kcal', Icons.directions_run),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Meals recorded',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                if (meals.isEmpty)
                  const ListTile(title: Text('No meals logged today.'))
                else
                  for (final doc in meals.take(15))
                    ListTile(
                      leading: const Icon(Icons.restaurant, color: Colors.red),
                      title: Text(doc.data()['foodName']?.toString() ?? 'Meal'),
                      subtitle: Text('${doc.data()['quantity']} serving(s)'),
                      trailing: Text('${FoodRecommendationEngine.amount(
                        doc.data()['calories']).toStringAsFixed(0)} kcal'),
                    ),
                const SizedBox(height: 15),
                const Text('Workouts recorded',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                if (workouts.isEmpty)
                  const ListTile(title: Text('No workouts logged today.'))
                else
                  for (final doc in workouts.take(15))
                    ListTile(
                      leading: const Icon(Icons.fitness_center, color: Colors.red),
                      title: Text(doc.data()['activityName']?.toString() ?? 'Activity'),
                      subtitle: Text('${doc.data()['minutes']} minutes'),
                      trailing: Text('~${FoodRecommendationEngine.amount(
                        doc.data()['estimatedCalories']).toStringAsFixed(0)} kcal'),
                    ),
                const SizedBox(height: 14),
                const Text(
                  'Food energy and activity estimates are shown separately. '
                  'Subtracting one from the other would not represent your body’s full energy balance.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _summary(String title, String value, IconData icon) {
    return SizedBox(
      width: 185,
      child: Card(
        color: const Color(0xFFFFF0F0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.red),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataBody(
    Map<String, dynamic> profile,
    Map<String, dynamic> settings,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> foodDocuments,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> restaurantDocuments,
  ) {
    final restaurants = <String, String>{
      for (final doc in restaurantDocuments)
        doc.id: doc.data()['name']?.toString() ?? 'Restaurant',
    };
    final foods = <String, Map<String, dynamic>>{
      for (final doc in foodDocuments) doc.id: doc.data(),
    };
    final goal = profile['fitnessGoal']?.toString() ??
        settings['goal']?.toString() ?? 'maintain weight';
    final weightSource = profile['weight'] ?? settings['weightKg'];
    final weight = weightSource is num && weightSource > 0
        ? weightSource.toDouble()
        : 0.0;
    final storedLevel = settings['fitnessLevel']?.toString() ?? 'beginner';
    final level = ['beginner', 'intermediate', 'advanced'].contains(storedLevel)
        ? storedLevel : 'beginner';
    final ranked = FoodRecommendationEngine.rank(
      foods: foods,
      restaurantNames: restaurants,
      fitnessGoal: goal,
    );

    return TabBarView(
      controller: tabs,
      children: [
        _foodRecommendations(ranked, goal),
        _exerciseTab(ranked, weight, level),
        _weeklyPlan(level, weight),
        _todayPanel(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FastFit Smart Recommendations'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Food Picks'),
            Tab(icon: Icon(Icons.directions_run), text: 'Exercise'),
            Tab(icon: Icon(Icons.calendar_view_week), text: '7-Day Plan'),
            Tab(icon: Icon(Icons.today), text: 'My Day'),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: profileStream,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.hasError) {
            return Center(child: Text('Profile error: ${profileSnapshot.error}'));
          }
          if (!profileSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: fitnessStream,
            builder: (context, fitnessSnapshot) {
              if (fitnessSnapshot.hasError) {
                return Center(child: Text('Fitness error: ${fitnessSnapshot.error}'));
              }
              if (!fitnessSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: foodsStream,
                builder: (context, foodsSnapshot) {
                  if (foodsSnapshot.hasError) {
                    return Center(child: Text('Food error: ${foodsSnapshot.error}'));
                  }
                  if (!foodsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: restaurantsStream,
                    builder: (context, restaurantsSnapshot) {
                      if (restaurantsSnapshot.hasError) {
                        return Center(child: Text('Restaurant error: ${restaurantsSnapshot.error}'));
                      }
                      if (!restaurantsSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _dataBody(
                        profileSnapshot.data!.data() ?? {},
                        fitnessSnapshot.data!.data() ?? {},
                        foodsSnapshot.data!.docs,
                        restaurantsSnapshot.data!.docs,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
