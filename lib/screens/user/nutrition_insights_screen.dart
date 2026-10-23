
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/customer_service.dart';
import '../../services/food_service.dart';

class NutritionInsightsScreen extends StatefulWidget {
  const NutritionInsightsScreen({super.key});

  @override
  State<NutritionInsightsScreen> createState() =>
      _NutritionInsightsScreenState();
}

class _NutritionInsightsScreenState
    extends State<NutritionInsightsScreen> {
  final CustomerService customer = CustomerService();
  final FoodService foodService = FoodService();

  int selectedDays = 7;

  double number(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 190,
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget weeklyChart(
    List<double> dailyCalories,
    List<DateTime> dates,
  ) {
    double maximum = 1;

    for (final value in dailyCalories) {
      if (value > maximum) maximum = value;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 7 Days',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Energy from meals you recorded',
            ),
            const SizedBox(height: 22),

            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final calories = dailyCalories[index];
                  final barHeight = calories == 0
                      ? 3.0
                      : 115.0 * calories / maximum;

                  final date = dates[index];

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            calories.toStringAsFixed(0),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 5),

                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '${date.month}/${date.day}',
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget insightsContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> logs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> foods,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startDate = today.subtract(
      Duration(days: selectedDays - 1),
    );

    final tomorrow = today.add(const Duration(days: 1));

    final foodMap = <String, Map<String, dynamic>>{};

    for (final doc in foods) {
      foodMap[doc.id] = doc.data();
    }

    int logCount = 0;
    int servingCount = 0;
    int missingNutrition = 0;

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    final foodCounts = <String, int>{};

    final dates = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );

    final dailyCalories = List<double>.filled(7, 0);

    for (final doc in logs) {
      final log = doc.data();

      final timestamp = log['loggedAt'];

      if (timestamp is! Timestamp) continue;

      final date = timestamp.toDate().toLocal();

      final foodId = log['foodId']?.toString() ?? '';
      final foodName = log['foodName']?.toString() ?? 'Meal';

      final quantity = (log['quantity'] as num?)?.toInt() ?? 1;
      final calories = number(log['calories']);

      for (int i = 0; i < dates.length; i++) {
        if (DateUtils.isSameDay(date, dates[i])) {
          dailyCalories[i] += calories;
          break;
        }
      }

      if (date.isBefore(startDate) ||
          !date.isBefore(tomorrow)) {
        continue;
      }

      logCount++;
      servingCount += quantity;
      totalCalories += calories;

      foodCounts[foodName] =
          (foodCounts[foodName] ?? 0) + quantity;

      final food = foodMap[foodId];

      if (food == null) {
        missingNutrition++;
        continue;
      }

      totalProtein += number(food['protein']) * quantity;
      totalCarbs += number(food['carbohydrates']) * quantity;
      totalFats += number(food['fats']) * quantity;
    }

    final topFoods = foodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final averageCalories =
        totalCalories / selectedDays;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'My Nutrition Insights',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Understand your recorded meals and '
          'explore your eating patterns.',
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            const Text('Show data for: '),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: selectedDays,
              items: const [
                DropdownMenuItem(
                  value: 7,
                  child: Text('7 days'),
                ),
                DropdownMenuItem(
                  value: 14,
                  child: Text('14 days'),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text('30 days'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedDays = value);
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            summaryCard(
              'Logged Meal Entries',
              '$logCount',
              Icons.restaurant,
              Colors.blue,
            ),

            summaryCard(
              'Total Servings',
              '$servingCount',
              Icons.fastfood,
              Colors.orange,
            ),

            summaryCard(
              'Recorded Energy',
              '${totalCalories.toStringAsFixed(0)} kcal',
              Icons.local_fire_department,
              Colors.red,
            ),

            summaryCard(
              'Average Per Day',
              '${averageCalories.toStringAsFixed(0)} kcal',
              Icons.calendar_today,
              Colors.green,
            ),
          ],
        ),

        const SizedBox(height: 25),

        weeklyChart(dailyCalories, dates),

        const SizedBox(height: 25),

        const Text(
          'Estimated Macronutrients',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Calculated from the currently approved '
          'nutrition information for logged foods.',
        ),

        const SizedBox(height: 15),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            summaryCard(
              'Protein',
              '${totalProtein.toStringAsFixed(1)} g',
              Icons.fitness_center,
              Colors.blue,
            ),

            summaryCard(
              'Carbohydrates',
              '${totalCarbs.toStringAsFixed(1)} g',
              Icons.grain,
              Colors.orange,
            ),

            summaryCard(
              'Fats',
              '${totalFats.toStringAsFixed(1)} g',
              Icons.opacity,
              Colors.purple,
            ),
          ],
        ),

        if (missingNutrition > 0) ...[
          const SizedBox(height: 15),
          Text(
            '$missingNutrition meal log(s) could not be '
            'matched with currently approved food data. '
            'Their calories are included, but their '
            'macronutrients are not.',
            style: const TextStyle(
              color: Colors.orange,
            ),
          ),
        ],

        const SizedBox(height: 30),

        const Text(
          'Most Frequently Logged Foods',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (topFoods.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'No recorded meals in this period.',
              ),
            ),
          )
        else
          ...topFoods.take(5).map((entry) {
            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.red,
                ),
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value} servings',
                ),
              ),
            );
          }),

        const SizedBox(height: 25),

        const Text(
          'Important: These totals only include meals '
          'recorded in FastFit, not everything you may '
          'have eaten. They are not a complete dietary '
          'assessment. Nutritional values can also change '
          'when a restaurant updates its menu.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FastFit Nutrition Insights'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: customer.mealHistory(),
        builder: (context, mealSnapshot) {
          if (mealSnapshot.hasError) {
            return Center(
              child: Text(
                'Meal history error: ${mealSnapshot.error}',
              ),
            );
          }

          if (!mealSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: foodService.approvedFoods(),
            builder: (context, foodSnapshot) {
              if (foodSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Food data error: ${foodSnapshot.error}',
                  ),
                );
              }

              if (!foodSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return insightsContent(
                mealSnapshot.data!.docs,
                foodSnapshot.data!.docs,
              );
            },
          );
        },
      ),
    );
  }
}
