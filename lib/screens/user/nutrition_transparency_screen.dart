import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/food_service.dart';
import '../../services/nutrition_review_service.dart';

class NutritionTransparencyScreen extends StatefulWidget {
  const NutritionTransparencyScreen({super.key});

  @override
  State<NutritionTransparencyScreen> createState() =>
      _NutritionTransparencyScreenState();
}

class _NutritionTransparencyScreenState
    extends State<NutritionTransparencyScreen> {
  String search = '';

  final NutritionReviewService nutrition = NutritionReviewService();

  Future<void> openSource(String text) async {
    final uri = Uri.tryParse(text);

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the source.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Link error: $e')));
    }
  }

  Widget foodCard(String foodId, Map<String, dynamic> food) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: nutrition.sourceForFood(foodId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              title: Text(food['name']?.toString() ?? 'Food'),
              subtitle: const Text('Source information is unavailable.'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: LinearProgressIndicator(),
            ),
          );
        }

        // The source may be null if no document exists.
        final Map<String, dynamic>? source = snapshot.data!.data();

        final bool reviewed = NutritionReviewService.isCurrentReviewedSource(
          food,
          source,
        );

        final bool stale =
            source != null && source['reviewStatus'] == 'approved' && !reviewed;

        final String sourceUrl = source?['sourceUrl']?.toString() ?? '';

        final String statusText = reviewed
            ? 'Source reviewed - current'
            : stale
            ? 'Previously reviewed - food data changed'
            : source == null
            ? 'No nutrition source submitted'
            : 'Source review not currently approved';

        final Color statusColor = reviewed ? Colors.green : Colors.orange;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name']?.toString() ?? 'Food',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text('Serving size: ${food['servingSize']}'),

                const SizedBox(height: 5),

                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text('${food['calories']} kcal'),
                    Text('Protein: ${food['protein']} g'),
                    Text('Carbs: ${food['carbohydrates']} g'),
                    Text('Fat: ${food['fats']} g'),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      reviewed ? Icons.verified_outlined : Icons.info_outline,
                      color: statusColor,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // FIX: Check that source is not null.
                if (reviewed && source != null) ...[
                  const SizedBox(height: 10),

                  Text('Source type: ${source['sourceType']}'),

                  if ((source['sourceNote'] ?? '').toString().isNotEmpty)
                    Text(
                      'Source details: '
                      '${source['sourceNote']}',
                    ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Nutrition Source'),
                    onPressed: sourceUrl.isEmpty
                        ? null
                        : () => openSource(sourceUrl),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Transparency'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FoodService().approvedFoods(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Food error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final foods = snapshot.data!.docs.where((doc) {
            final name = doc.data()['name']?.toString().toLowerCase() ?? '';

            return name.contains(search);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Where Does Your Food Data Come From?',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Explore the sources supporting '
                      'restaurant-submitted nutrition '
                      'information.',
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search approved food...',
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
                child: foods.isEmpty
                    ? const Center(child: Text('No matching food items.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: foods.length,
                        itemBuilder: (context, index) {
                          final food = foods[index];

                          return foodCard(food.id, food.data());
                        },
                      ),
              ),

              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Admin review is not a guarantee '
                  'of nutrition accuracy. Check the '
                  'original source and serving size '
                  'where possible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
