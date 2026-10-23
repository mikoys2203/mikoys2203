
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/restaurant_approval_service.dart';
import '../../services/food_service.dart';

import 'admin_analytics_screen.dart';
import 'admin_data_audit_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String name;

  const AdminDashboard({
    super.key,
    required this.name,
  });

  @override
  State<AdminDashboard> createState() =>
      _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final restaurantService = RestaurantApprovalService();
  final foodService = FoodService();

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      restaurantRequests;

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      foodRequests;

  String? processingId;

  @override
  void initState() {
    super.initState();

    restaurantRequests =
        restaurantService.getRestaurants();

    foodRequests = foodService.pendingFoods();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ====================================
  // APPROVE OR REJECT
  // ====================================

  Future<void> reviewRequest({
    required String documentId,
    required String name,
    required String status,
    required bool isFood,
  }) async {
    if (processingId != null) return;

    final action =
        status == 'approved' ? 'Approve' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action Request'),
          content: Text(
            'Are you sure you want to '
            '${action.toLowerCase()} "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => processingId = documentId);

    try {
      if (isFood) {
        await foodService.reviewFood(
          documentId,
          status,
        );
      } else {
        await restaurantService.updateStatus(
          documentId,
          status,
        );
      }

      showMessage('$name has been $status.');
    } on FirebaseException catch (e) {
      showMessage(
        e.message ?? 'Firebase permission error',
      );
    } catch (e) {
      showMessage('Unable to update request: $e');
    } finally {
      if (mounted) {
        setState(() => processingId = null);
      }
    }
  }

  Widget approvalButtons({
    required String id,
    required String name,
    required bool isFood,
  }) {
    final disabled = processingId != null;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: disabled
              ? null
              : () {
                  reviewRequest(
                    documentId: id,
                    name: name,
                    status: 'approved',
                    isFood: isFood,
                  );
                },
          icon: const Icon(Icons.check),
          label: const Text('Approve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),

        OutlinedButton.icon(
          onPressed: disabled
              ? null
              : () {
                  reviewRequest(
                    documentId: id,
                    name: name,
                    status: 'rejected',
                    isFood: isFood,
                  );
                },
          icon: const Icon(Icons.close),
          label: const Text('Reject'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  // ====================================
  // RESTAURANT REQUEST CARDS
  // ====================================

  Widget restaurantCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final name = data['name']?.toString() ?? 'Restaurant';
    final email = data['email']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(
                    Icons.store,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(email),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Pending Registration',
              style: TextStyle(color: Colors.orange),
            ),

            const SizedBox(height: 14),

            approvalButtons(
              id: doc.id,
              name: name,
              isFood: false,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // FOOD REQUEST CARDS
  // ====================================

  Widget foodCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final food = doc.data();

    final name = food['name']?.toString() ?? 'Food';
    final imageUrl = food['imageUrl']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 85,
                  height: 85,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isEmpty
                        ? Container(
                            color: Colors.red.shade50,
                            child: const Icon(
                              Icons.fastfood,
                              color: Colors.red,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Icon(
                                Icons.fastfood,
                                color: Colors.red,
                              );
                            },
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
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Category: ${food['category']}',
                      ),

                      Text(
                        'Serving: ${food['servingSize']}',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Divider(),

            const Text(
              'Nutrition Facts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 15,
              runSpacing: 8,
              children: [
                Text('Calories: ${food['calories']} kcal'),
                Text('Protein: ${food['protein']} g'),
                Text('Carbs: ${food['carbohydrates']} g'),
                Text('Fat: ${food['fats']} g'),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              food['description']?.toString() ?? '',
            ),

            const SizedBox(height: 12),

            approvalButtons(
              id: doc.id,
              name: name,
              isFood: true,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // RESTAURANT APPROVAL TAB
  // ====================================

  Widget restaurantApprovals() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: restaurantRequests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load restaurants: '
              '${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final pending = snapshot.data!.docs.where((doc) {
          return doc.data()['approvalStatus'] == 'pending';
        }).toList();

        if (pending.isEmpty) {
          return const Center(
            child: Text(
              'No pending restaurant registrations.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            return restaurantCard(pending[index]);
          },
        );
      },
    );
  }

  // ====================================
  // FOOD APPROVAL TAB
  // ====================================

  Widget foodApprovals() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: foodRequests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load foods: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final foods = snapshot.data!.docs;

        if (foods.isEmpty) {
          return const Center(
            child: Text(
              'No pending food submissions.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: foods.length,
          itemBuilder: (context, index) {
            return foodCard(foods[index]);
          },
        );
      },
    );
  }

  // ====================================
  // MAIN ADMIN DASHBOARD
  // ====================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FastFit Admin Center'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,

          actions: [
            IconButton(
              tooltip: 'Log out',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
            ),
          ],

          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.store),
                text: 'Restaurant Approvals',
              ),
              Tab(
                icon: Icon(Icons.fastfood),
                text: 'Food Approvals',
              ),
              Tab(
                icon: Icon(Icons.bar_chart),
                text: 'Analytics',
              ),
              Tab(
                icon: Icon(Icons.fact_check),
                text: 'Data Audit',
              ),
            ],
          ),
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome, ${widget.name}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  restaurantApprovals(),
                  foodApprovals(),
                  const AdminAnalyticsPanel(),
                  const AdminDataAuditPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
