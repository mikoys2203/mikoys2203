
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/customer_service.dart';
import 'exercise_screen.dart';

class FoodDetailsScreen extends StatefulWidget {
  final String foodId;
  final Map<String, dynamic> food;
  final String restaurantName;

  const FoodDetailsScreen({
    super.key,
    required this.foodId,
    required this.food,
    required this.restaurantName,
  });

  @override
  State<FoodDetailsScreen> createState() =>
      _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  final CustomerService customer = CustomerService();

  int quantity = 1;
  bool savingMeal = false;

  late final Future<String> restaurantNameFuture;

  @override
  void initState() {
    super.initState();
    restaurantNameFuture = getRestaurantName();
  }

  Future<String> getRestaurantName() async {
    if (widget.restaurantName.isNotEmpty) {
      return widget.restaurantName;
    }

    final restaurantId =
        widget.food['restaurantId']?.toString() ?? '';

    if (restaurantId.isEmpty) {
      return 'Restaurant';
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      return doc.data()?['name']?.toString() ?? 'Restaurant';
    } catch (_) {
      return 'Restaurant';
    }
  }

  double get calories {
    return (widget.food['calories'] as num?)?.toDouble() ?? 0;
  }

  String get foodName {
    return widget.food['name']?.toString() ?? 'Food';
  }

  Future<void> saveMeal(String restaurantName) async {
    if (savingMeal) return;

    setState(() => savingMeal = true);

    try {
      await customer.logMeal(
        foodId: widget.foodId,
        foodName: foodName,
        restaurantName: restaurantName,
        calories: calories,
        quantity: quantity,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal added to your history!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to log meal: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => savingMeal = false);
      }
    }
  }

  Widget nutritionCard(
    String label,
    dynamic value,
    String unit,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 7),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        widget.food['imageUrl']?.toString() ?? '';

    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Details'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            stream: customer.isFavorite(widget.foodId),
            builder: (context, snapshot) {
              final favorite = snapshot.data?.exists ?? false;

              return IconButton(
                tooltip: favorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  favorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                onPressed: !snapshot.hasData
                    ? null
                    : () async {
                        try {
                          await customer.toggleFavorite(
                            widget.foodId,
                            favorite,
                          );
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Unable to update favorite: $e',
                              ),
                            ),
                          );
                        }
                      },
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<String>(
        future: restaurantNameFuture,
        builder: (context, restaurantSnapshot) {
          if (!restaurantSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final restaurantName = restaurantSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 230,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl.isEmpty
                          ? const Icon(
                              Icons.fastfood,
                              size: 100,
                              color: Colors.red,
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return const Icon(
                                  Icons.fastfood,
                                  size: 100,
                                  color: Colors.red,
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      foodName,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      restaurantName,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Serving Size: '
                      '${widget.food['servingSize']}',
                    ),

                    const SizedBox(height: 7),

                    Text(
                      widget.food['description']?.toString() ??
                          '',
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Nutrition Facts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Values per serving',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        nutritionCard(
                          'Calories',
                          calories,
                          'kcal',
                          Colors.red,
                        ),
                        nutritionCard(
                          'Protein',
                          widget.food['protein'],
                          'g',
                          Colors.blue,
                        ),
                        nutritionCard(
                          'Carbohydrates',
                          widget.food['carbohydrates'],
                          'g',
                          Colors.orange,
                        ),
                        nutritionCard(
                          'Fats',
                          widget.food['fats'],
                          'g',
                          Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Record Your Meal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Text('Quantity: '),
                        const SizedBox(width: 12),

                        DropdownButton<int>(
                          value: quantity,
                          items: [1, 2, 3, 4, 5].map((number) {
                            return DropdownMenuItem(
                              value: number,
                              child: Text('$number'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => quantity = value);
                            }
                          },
                        ),

                        const SizedBox(width: 20),

                        Text(
                          '${(calories * quantity).toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(
                          savingMeal
                              ? 'Saving...'
                              : 'Add to Meal History',
                        ),
                        onPressed: savingMeal
                            ? null
                            : () => saveMeal(restaurantName),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Exercise Recommendations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Explore physical activities and estimated '
                      'energy expenditure based on your weight.',
                    ),

                    const SizedBox(height: 15),

                    StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Unable to load weight: '
                            '${snapshot.error}',
                          );
                        }

                        final value =
                            snapshot.data?.data()?['weight'];

                        final weight = value is num
                            ? value.toDouble()
                            : null;

                        if (weight == null || weight <= 0) {
                          return const Text(
                            'Please set your weight in '
                            'Profile before viewing estimates.',
                            style: TextStyle(
                              color: Colors.orange,
                            ),
                          );
                        }

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.fitness_center,
                            ),
                            label: const Text(
                              'View Exercise Recommendations',
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExerciseScreen(
                                    foodName: foodName,
                                    mealCalories: calories,
                                    weightKg: weight,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Nutrition values should be verified '
                      'against a reliable source. Exercise '
                      'estimates are approximate and are not '
                      'a requirement to compensate for eating.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
