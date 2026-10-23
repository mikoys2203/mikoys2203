
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/nutrition_review_service.dart';

class NutritionEvidenceScreen extends StatelessWidget {
  const NutritionEvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NutritionReviewService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Evidence'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: service.myFoods(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final foods = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Food Nutrition Sources',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Provide the source of each food item\'s '
                'calorie and nutritional information.',
              ),
              const SizedBox(height: 20),

              if (foods.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Create a food item in Manage Menu first.',
                    ),
                  ),
                ),

              for (final doc in foods)
                _EvidenceFoodCard(
                  foodId: doc.id,
                  food: doc.data(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EvidenceFoodCard extends StatelessWidget {
  final String foodId;
  final Map<String, dynamic> food;

  const _EvidenceFoodCard({
    required this.foodId,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    final service = NutritionReviewService();

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.sourceForFood(foodId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: ListTile(
              title: Text(food['name']?.toString() ?? 'Food'),
              subtitle: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final source = snapshot.data?.data();
        final status =
            source?['reviewStatus']?.toString() ?? 'not submitted';

        final current =
            NutritionReviewService.isCurrentReviewedSource(
          food,
          source,
        );

        Color statusColor = Colors.orange;

        if (current) {
          statusColor = Colors.green;
        } else if (status == 'rejected') {
          statusColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name']?.toString() ?? 'Food',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Serving: ${food['servingSize']}',
                ),
                Text(
                  'Calories: ${food['calories']} kcal',
                ),
                const SizedBox(height: 10),
                Text(
                  current
                      ? 'Source reviewed â€” current'
                      : status == 'approved'
                          ? 'Source review is outdated'
                          : 'Source status: $status',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (source != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${source['sourceUrl']}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((source['reviewNote'] ?? '')
                      .toString().isNotEmpty)
                    Text(
                      'Admin note: ${source['reviewNote']}',
                    ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.description),
                  label: Text(
                    source == null
                        ? 'Submit Nutrition Source'
                        : 'Resubmit / Update Source',
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => _EvidenceFormDialog(
                        foodId: foodId,
                        foodName: food['name']?.toString() ??
                            'Food',
                        existing: source,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EvidenceFormDialog extends StatefulWidget {
  final String foodId;
  final String foodName;
  final Map<String, dynamic>? existing;

  const _EvidenceFormDialog({
    required this.foodId,
    required this.foodName,
    required this.existing,
  });

  @override
  State<_EvidenceFormDialog> createState() =>
      _EvidenceFormDialogState();
}

class _EvidenceFormDialogState
    extends State<_EvidenceFormDialog> {
  final formKey = GlobalKey<FormState>();
  final service = NutritionReviewService();

  late final TextEditingController url;
  late final TextEditingController note;

  late String sourceType;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    url = TextEditingController(
      text: widget.existing?['sourceUrl']?.toString() ?? '',
    );

    note = TextEditingController(
      text: widget.existing?['sourceNote']?.toString() ?? '',
    );

    sourceType =
        widget.existing?['sourceType']?.toString() ?? 'official';

    if (!['official', 'packaging', 'other']
        .contains(sourceType)) {
      sourceType = 'other';
    }
  }

  @override
  void dispose() {
    url.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await service.submitSource(
        foodId: widget.foodId,
        sourceType: sourceType,
        sourceUrl: url.text,
        sourceNote: note.text,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Source for ${widget.foodName}'),
      content: SizedBox(
        width: 470,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: sourceType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Source Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'official',
                      child: Text('Official Restaurant Website'),
                    ),
                    DropdownMenuItem(
                      value: 'packaging',
                      child: Text('Packaging / Nutrition Label'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other Source'),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => sourceType = value);
                          }
                        },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: url,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Source URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!service.isValidUrl(value ?? '')) {
                      return 'Enter a valid HTTPS URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: note,
                  maxLines: 3,
                  maxLength: 600,
                  decoration: const InputDecoration(
                    labelText: 'Source Explanation',
                    hintText:
                        'Explain where the nutrition values came from.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Text(
                  'Provide a source relevant to the food '
                  'item and serving size. Resubmitting '
                  'will require another admin review.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saving ? null : submit,
          child: Text(saving ? 'Submitting...' : 'Submit Source'),
        ),
      ],
    );
  }
}

