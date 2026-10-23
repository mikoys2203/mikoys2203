
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/food_service.dart';

class FoodCompareScreen extends StatefulWidget {
  const FoodCompareScreen({super.key});

  @override
  State<FoodCompareScreen> createState() =>
      _FoodCompareScreenState();
}

class _FoodCompareScreenState extends State<FoodCompareScreen> {
  final FoodService service = FoodService();

  String? firstFoodId;
  String? secondFoodId;

  int firstQuantity = 1;
  int secondQuantity = 1;

  double number(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  Widget foodSelector({
    required String title,
    required String selectedId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        foods,
    required ValueChanged<String?> onChanged,
    required int quantity,
    required ValueChanged<int?> onQuantityChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            DropdownButton<String>(
              value: selectedId,
              isExpanded: true,
              items: foods.map((doc) {
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(
                    doc.data()['name']?.toString() ?? 'Food',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Text('Servings: '),

                const SizedBox(width: 10),

                DropdownButton<int>(
                  value: quantity,
                  items: List.generate(5, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}'),
                    );
                  }),
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget nutrientRow(
    String title,
    double first,
    double second,
    String unit,
  ) {
    String value(double amount) {
      return '${amount.toStringAsFixed(1)} $unit';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              value(first),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              value(second),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget comparisonContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> foods,
    Map<String, String> restaurantNames,
  ) {
    if (foods.isEmpty) {
      return const Center(
        child: Text(
          'No approved food items are available yet.',
        ),
      );
    }

    final foodMap = {
      for (final doc in foods) doc.id: doc.data(),
    };

    final firstId =
        foodMap.containsKey(firstFoodId)
            ? firstFoodId!
            : foods.first.id;

    final secondId =
        foodMap.containsKey(secondFoodId)
            ? secondFoodId!
            : foods.length > 1
                ? foods[1].id
                : foods.first.id;

    final first = foodMap[firstId]!;
    final second = foodMap[secondId]!;

    final firstName =
        first['name']?.toString() ?? 'Food A';

    final secondName =
        second['name']?.toString() ?? 'Food B';

    final firstRestaurant = restaurantNames[
            first['restaurantId']?.toString() ?? ''] ??
        'Restaurant';

    final secondRestaurant = restaurantNames[
            second['restaurantId']?.toString() ?? ''] ??
        'Restaurant';

    final firstCalories =
        number(first['calories']) * firstQuantity;

    final secondCalories =
        number(second['calories']) * secondQuantity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compare Fast-Food Meals',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Select two menu items to compare '
                'their nutritional information.',
              ),

              const SizedBox(height: 25),

              LayoutBuilder(
                builder: (context, constraints) {
                  final firstSelector = foodSelector(
                    title: 'Food A',
                    selectedId: firstId,
                    foods: foods,
                    quantity: firstQuantity,
                    onChanged: (value) {
                      setState(() => firstFoodId = value);
                    },
                    onQuantityChanged: (value) {
                      if (value != null) {
                        setState(() => firstQuantity = value);
                      }
                    },
                  );

                  final secondSelector = foodSelector(
                    title: 'Food B',
                    selectedId: secondId,
                    foods: foods,
                    quantity: secondQuantity,
                    onChanged: (value) {
                      setState(() => secondFoodId = value);
                    },
                    onQuantityChanged: (value) {
                      if (value != null) {
                        setState(() => secondQuantity = value);
                      }
                    },
                  );

                  if (constraints.maxWidth < 650) {
                    return Column(
                      children: [
                        firstSelector,
                        secondSelector,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: firstSelector),
                      const SizedBox(width: 12),
                      Expanded(child: secondSelector),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Nutrition Comparison',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text('Nutrient'),
                          ),

                          Expanded(
                            flex: 2,
                            child: Text(
                              'Food A',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Text(
                              'Food B',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(),

                      nutrientRow(
                        'Calories',
                        firstCalories,
                        secondCalories,
                        'kcal',
                      ),

                      const Divider(),

                      nutrientRow(
                        'Protein',
                        number(first['protein']) * firstQuantity,
                        number(second['protein']) * secondQuantity,
                        'g',
                      ),

                      const Divider(),

                      nutrientRow(
                        'Carbs',
                        number(first['carbohydrates']) *
                            firstQuantity,
                        number(second['carbohydrates']) *
                            secondQuantity,
                        'g',
                      ),

                      const Divider(),

                      nutrientRow(
                        'Fats',
                        number(first['fats']) * firstQuantity,
                        number(second['fats']) * secondQuantity,
                        'g',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Meals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'A: $firstName ($firstRestaurant)',
                      ),

                      Text(
                        'Serving: ${first['servingSize']}',
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'B: $secondName ($secondRestaurant)',
                      ),

                      Text(
                        'Serving: ${second['servingSize']}',
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Energy difference: '
                        '${(firstCalories - secondCalories).abs().toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'A lower calorie value does not automatically '
                'mean a meal is healthier. Consider serving size, '
                'nutrition, variety, and your personal needs.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FastFit Food Comparison'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: service.approvedFoods(),
        builder: (context, foodSnapshot) {
          if (foodSnapshot.hasError) {
            return Center(
              child: Text(
                'Food error: ${foodSnapshot.error}',
              ),
            );
          }

          if (!foodSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: service.approvedRestaurants(),
            builder: (context, restaurantSnapshot) {
              if (restaurantSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Restaurant error: '
                    '${restaurantSnapshot.error}',
                  ),
                );
              }

              if (!restaurantSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final names = <String, String>{};

              for (final doc in restaurantSnapshot.data!.docs) {
                names[doc.id] =
                    doc.data()['name']?.toString() ??
                        'Restaurant';
              }

              return comparisonContent(
                foodSnapshot.data!.docs,
                names,
              );
            },
          );
        },
      ),
    );
  }
}
