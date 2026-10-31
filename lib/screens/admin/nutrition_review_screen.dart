import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/nutrition_review_service.dart';

class NutritionReviewScreen extends StatefulWidget {
  const NutritionReviewScreen({super.key});

  @override
  State<NutritionReviewScreen> createState() => _NutritionReviewScreenState();
}

class _NutritionReviewScreenState extends State<NutritionReviewScreen> {
  final service = NutritionReviewService();

  String filter = 'pending';
  String search = '';

  Future<void> openSource(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null || uri.scheme != 'https') return;

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the source URL.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to open source: $e')));
    }
  }

  Future<void> showReviewDialog(String foodId, String decision) async {
    await showDialog(
      context: context,
      builder: (_) => _ReviewDecisionDialog(foodId: foodId, decision: decision),
    );
  }

  Future<void> showHistory(String foodId) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Source Review History'),
        content: SizedBox(
          width: 500,
          height: 330,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.reviewHistory(foodId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reviews = snapshot.data!.docs;

              if (reviews.isEmpty) {
                return const Center(child: Text('No previous reviews.'));
              }

              return ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final data = reviews[index].data();
                  final date = data['reviewedAt'];

                  final time = date is Timestamp
                      ? date.toDate().toLocal().toString()
                      : 'Pending timestamp';

                  return ListTile(
                    leading: Icon(
                      data['decision'] == 'approved'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: data['decision'] == 'approved'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(
                      data['decision']?.toString().toUpperCase() ?? 'REVIEW',
                    ),
                    subtitle: Text('${data['note'] ?? ''}\n$time'),
                    isThreeLine: true,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget sourceCard(String foodId, Map<String, dynamic> source) {
    final status = source['reviewStatus']?.toString() ?? 'pending';

    final sourceUrl = source['sourceUrl']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('food_items')
                  .doc(foodId)
                  .snapshots(),
              builder: (context, snapshot) {
                final food = snapshot.data?.data();

                return Text(
                  food?['name']?.toString() ?? 'Food ID: $foodId',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text('Status: $status'),
            Text('Source type: ${source['sourceType']}'),
            const SizedBox(height: 8),
            Text('URL: $sourceUrl'),
            const SizedBox(height: 10),
            if ((source['sourceNote'] ?? '').toString().isNotEmpty)
              Text('Restaurant note: ${source['sourceNote']}'),
            if ((source['reviewNote'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Review note: ${source['reviewNote']}'),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 9,
              children: [
                OutlinedButton.icon(
                  onPressed: sourceUrl.isEmpty
                      ? null
                      : () => openSource(sourceUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Source'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showHistory(foodId),
                  icon: const Icon(Icons.history),
                  label: const Text('Review History'),
                ),
                if (status == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () => showReviewDialog(foodId, 'approved'),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve Source'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showReviewDialog(foodId, 'rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject Source'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Source Reviews'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.allSources(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sources = snapshot.data!.docs.where((doc) {
            final data = doc.data();

            final matchesStatus =
                filter == 'all' || data['reviewStatus'] == filter;

            final searchable =
                '${doc.id} ${data['sourceUrl']} '
                        '${data['sourceType']} ${data['sourceNote']}'
                    .toLowerCase();

            return matchesStatus && searchable.contains(search);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nutrition Source Review Center',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Review supporting evidence before '
                      'marking a source as reviewed.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search source information...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          search = value.toLowerCase().trim();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final value in [
                          'pending',
                          'approved',
                          'rejected',
                          'all',
                        ])
                          ChoiceChip(
                            label: Text(value.toUpperCase()),
                            selected: filter == value,
                            onSelected: (_) {
                              setState(() => filter = value);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: sources.isEmpty
                    ? const Center(
                        child: Text('No matching source submissions.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: sources.length,
                        itemBuilder: (context, index) {
                          final doc = sources[index];

                          return sourceCard(doc.id, doc.data());
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewDecisionDialog extends StatefulWidget {
  final String foodId;
  final String decision;

  const _ReviewDecisionDialog({required this.foodId, required this.decision});

  @override
  State<_ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<_ReviewDecisionDialog> {
  final controller = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please explain your decision.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await NutritionReviewService().reviewSource(
        foodId: widget.foodId,
        decision: widget.decision,
        note: controller.text,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Review failed: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.decision == 'approved'
            ? 'Approve Nutrition Source'
            : 'Reject Nutrition Source',
      ),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Review Reason / Notes',
            border: OutlineInputBorder(),
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
          child: Text(saving ? 'Saving...' : 'Confirm Decision'),
        ),
      ],
    );
  }
}
