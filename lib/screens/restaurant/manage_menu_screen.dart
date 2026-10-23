
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/food_service.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() =>
      _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final FoodService service = FoodService();

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> editRestaurant(Map<String, dynamic>? data) async {
    final name = TextEditingController(text: data?['name'] ?? '');
    final logo = TextEditingController(text: data?['logoUrl'] ?? '');
    final key = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurant Profile'),
        content: SizedBox(
          width: 450,
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant Name',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Required'
                      : null,
                ),
                TextFormField(
                  controller: logo,
                  decoration: const InputDecoration(
                    labelText: 'Logo Image URL (Optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              try {
                await service.saveRestaurant(
                  name.text,
                  logo.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                message('Restaurant profile saved.');
              } catch (e) {
                message('Error saving restaurant: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    name.dispose();
    logo.dispose();
  }

  Future<void> editFood(
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final key = GlobalKey<FormState>();

    TextEditingController field(String name) {
      return TextEditingController(
        text: data[name]?.toString() ?? '',
      );
    }

    final name = field('name');
    final category = field('category');
    final description = field('description');
    final imageUrl = field('imageUrl');
    final serving = field('servingSize');
    final calories = field('calories');
    final protein = field('protein');
    final carbs = field('carbohydrates');
    final fats = field('fats');

    final controllers = [
      name, category, description, imageUrl,
      serving, calories, protein, carbs, fats,
    ];

    Widget input(
      String label,
      TextEditingController controller, {
      bool numeric = false,
      bool required = false,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
                  decimal: true,
                )
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) {
              return '$label is required';
            }
            if (numeric) {
              final number = double.tryParse(text);
              if (number == null ||
                  !number.isFinite ||
                  number < 0) {
                return 'Enter a valid number (0 or higher)';
              }
            }
            return null;
          },
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(doc == null ? 'Add Food Item' : 'Edit Food Item'),
        content: SizedBox(
          width: 500,
          height: 460,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  input('Food Name', name, required: true),
                  input('Category', category, required: true),
                  input('Description', description),
                  input('Image URL (Optional)', imageUrl),
                  input('Serving Size (e.g. 1 meal)',
                      serving, required: true),
                  input('Calories (kcal)', calories,
                      numeric: true),
                  input('Protein (g)', protein,
                      numeric: true),
                  input('Carbohydrates (g)', carbs,
                      numeric: true),
                  input('Fats (g)', fats,
                      numeric: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;

              final food = <String, dynamic>{
                'name': name.text.trim(),
                'category': category.text.trim(),
                'description': description.text.trim(),
                'imageUrl': imageUrl.text.trim(),
                'servingSize': serving.text.trim(),
                'calories': double.parse(calories.text),
                'protein': double.parse(protein.text),
                'carbohydrates': double.parse(carbs.text),
                'fats': double.parse(fats.text),
              };

              try {
                await service.saveFood(
                  food,
                  foodId: doc?.id,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                message('Food submitted for admin approval.');
              } catch (e) {
                message('Unable to save food: $e');
              }
            },
            child: const Text('Save Food'),
          ),
        ],
      ),
    );

    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> removeFood(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food'),
        content: const Text(
          'Are you sure you want to delete this food item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await service.deleteFood(id);
      message('Food item deleted.');
    } catch (e) {
      message('Unable to delete food: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Restaurant Menu'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: service.getMyRestaurant(),
        builder: (context, restaurantSnapshot) {
          if (restaurantSnapshot.hasError) {
            return Center(
              child: Text('Error: ${restaurantSnapshot.error}'),
            );
          }

          if (!restaurantSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final restaurantData =
              restaurantSnapshot.data!.data();

          if (restaurantData == null) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () => editRestaurant(null),
                icon: const Icon(Icons.store),
                label: const Text('Create Restaurant Profile'),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantData['name'] ?? 'Restaurant',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          editRestaurant(restaurantData),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Restaurant'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => editFood(null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Food'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'My Food Items',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder(
                    stream: service.myFoods(),
                    builder: (context, foodSnapshot) {
                      if (foodSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${foodSnapshot.error}',
                          ),
                        );
                      }

                      if (!foodSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final foods = foodSnapshot.data!.docs;

                      if (foods.isEmpty) {
                        return const Center(
                          child: Text('No food items yet.'),
                        );
                      }

                      return ListView.builder(
                        itemCount: foods.length,
                        itemBuilder: (context, index) {
                          final doc = foods[index];
                          final food = doc.data();
                          final status =
                              food['approvalStatus'] ?? 'pending';

                          return Card(
                            child: ListTile(
                              title: Text(food['name'] ?? ''),
                              subtitle: Text(
                                '${food['calories']} kcal\n'
                                'Status: $status',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => editFood(doc),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () =>
                                        removeFood(doc.id),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
