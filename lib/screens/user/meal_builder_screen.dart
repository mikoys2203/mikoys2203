
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/food_service.dart';

class MealBuilderScreen extends StatefulWidget {
  const MealBuilderScreen({super.key});

  @override
  State<MealBuilderScreen> createState() =>
      _MealBuilderScreenState();
}

class _MealBuilderScreenState extends State<MealBuilderScreen> {
  final FoodService service = FoodService();

  final Map<String, int> selectedFoods = {};

  String search = '';
  bool saving = false;

  double number(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void changeQuantity(String foodId, int change) {
    if (saving) return;

    final current = selectedFoods[foodId] ?? 0;
    final next = current + change;

    if (next > 5) {
      showMessage('Maximum of 5 servings per item.');
      return;
    }

    if (current == 0 &&
        change > 0 &&
        selectedFoods.length >= 3) {
      showMessage(
        'You can select up to 3 different foods.',
      );
      return;
    }

    setState(() {
      if (next <= 0) {
        selectedFoods.remove(foodId);
      } else {
        selectedFoods[foodId] = next;
      }
    });
  }

  Future<void> saveMealCombination(
    Map<String, Map<String, dynamic>> foodMap,
    Map<String, String> restaurantNames,
  ) async {
    if (saving) return;

    final entries = selectedFoods.entries.where(
      (entry) => foodMap.containsKey(entry.key),
    ).toList();

    if (entries.isEmpty) {
      showMessage('Please select a food item.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Record This Meal?'),
          content: const Text(
            'This will add your selected items '
            'to Meal History as food you have eaten.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Record Meal'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please log in again.');
      }

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final mealCollection = db
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs');

      for (final entry in entries) {
        final food = foodMap[entry.key]!;
        final quantity = entry.value;

        final restaurantId =
            food['restaurantId']?.toString() ?? '';

        final restaurantName =
            restaurantNames[restaurantId] ?? 'Restaurant';

        final calories = food['calories'] as num? ?? 0;

        final newDocument = mealCollection.doc();

        batch.set(newDocument, {
          'foodId': entry.key,
          'foodName': food['name']?.toString() ?? 'Food',
          'restaurantName': restaurantName,
          'calories': calories * quantity,
          'protein': number(food['protein']) * quantity,
          'carbohydrates': number(food['carbohydrates']) * quantity,
          'fats': number(food['fats']) * quantity,
          'quantity': quantity,
          'loggedAtClient': Timestamp.fromDate(DateTime.now().toUtc()),
          'loggedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      setState(() => selectedFoods.clear());

      showMessage(
        'Meal combination saved to your history!',
      );
    } catch (e) {
      showMessage('Unable to record meal: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget foodCard(
    String foodId,
    Map<String, dynamic> food,
  ) {
    final quantity = selectedFoods[foodId] ?? 0;
    final imageUrl = food['imageUrl']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  height: 65,
                  width: 65,
                  child: imageUrl.isEmpty
                      ? const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Colors.red,
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(
                                Icons.fastfood,
                                color: Colors.red,
                              ),
                        ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        food['name']?.toString() ?? 'Food',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${food['calories']} kcal per serving',
                      ),

                      Text(
                        'Serving: ${food['servingSize']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Quantity: '),

                IconButton(
                  onPressed: quantity == 0 || saving
                      ? null
                      : () => changeQuantity(foodId, -1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),

                Text(
                  '$quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                IconButton(
                  onPressed: saving
                      ? null
                      : () => changeQuantity(foodId, 1),
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget builderContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> foods,
    Map<String, String> restaurantNames,
  ) {
    final foodMap = <String, Map<String, dynamic>>{
      for (final doc in foods) doc.id: doc.data(),
    };

    final filtered = foods.where((doc) {
      final food = doc.data();

      final name =
          food['name']?.toString().toLowerCase() ?? '';

      final category =
          food['category']?.toString().toLowerCase() ?? '';

      return name.contains(search) ||
          category.contains(search);
    }).toList();

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fats = 0;

    int servings = 0;

    for (final entry in selectedFoods.entries) {
      final food = foodMap[entry.key];

      if (food == null) continue;

      final quantity = entry.value;

      servings += quantity;

      calories += number(food['calories']) * quantity;
      protein += number(food['protein']) * quantity;
      carbs += number(food['carbohydrates']) * quantity;
      fats += number(food['fats']) * quantity;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Build Your Meal',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Combine up to 3 approved fast-food '
                'items and view their nutritional totals.',
              ),

              const SizedBox(height: 20),

              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search food or category...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    search = value.toLowerCase().trim();
                  });
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('No matching foods found.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];

                    return foodCard(
                      doc.id,
                      doc.data(),
                    );
                  },
                ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border(
              top: BorderSide(
                color: Colors.red.shade100,
              ),
            ),
          ),

          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meal Combination Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$servings servings • '
                  '${calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Protein: ${protein.toStringAsFixed(1)}g  •  '
                  'Carbs: ${carbs.toStringAsFixed(1)}g  •  '
                  'Fat: ${fats.toStringAsFixed(1)}g',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saving || servings == 0
                        ? null
                        : () => saveMealCombination(
                              foodMap,
                              restaurantNames,
                            ),
                    icon: const Icon(Icons.save),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : 'Log This Meal Combination',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FastFit Meal Builder'),
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

              return builderContent(
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
