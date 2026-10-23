
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/food_service.dart';
import 'manage_menu_screen.dart';

class RestaurantDashboard extends StatelessWidget {
  final String name;
  final String approvalStatus;

  const RestaurantDashboard({
    super.key,
    required this.name,
    required this.approvalStatus,
  });

  void openMenu(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageMenuScreen(),
      ),
    );
  }

  Widget statCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),

            const SizedBox(height: 10),

            Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget statusBadge(String status) {
    Color color = Colors.orange;

    if (status == 'approved') {
      color = Colors.green;
    } else if (status == 'rejected') {
      color = Colors.red;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }

  Widget waitingScreen() {
    final rejected = approvalStatus == 'rejected';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              rejected ? Icons.cancel : Icons.access_time,
              color: rejected ? Colors.red : Colors.orange,
              size: 70,
            ),

            const SizedBox(height: 20),

            Text(
              rejected
                  ? 'Restaurant Registration Rejected'
                  : 'Waiting for Admin Approval',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              rejected
                  ? 'Your restaurant account was not approved.'
                  : 'Your restaurant registration is being reviewed.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget dashboard(
    BuildContext context,
    Map<String, dynamic>? restaurant,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> foods,
  ) {
    final total = foods.length;

    final approved = foods.where((doc) {
      return doc.data()['approvalStatus'] == 'approved';
    }).length;

    final pending = foods.where((doc) {
      return doc.data()['approvalStatus'] == 'pending';
    }).length;

    final rejected = foods.where((doc) {
      return doc.data()['approvalStatus'] == 'rejected';
    }).length;

    final restaurantName =
        restaurant?['name']?.toString() ?? 'My Restaurant';

    final logoUrl =
        restaurant?['logoUrl']?.toString() ?? '';

    final recentFoods = [...foods];

    recentFoods.sort((a, b) {
      final aDate = a.data()['createdAt'] as Timestamp?;
      final bDate = b.data()['createdAt'] as Timestamp?;

      return (bDate?.millisecondsSinceEpoch ?? 0)
          .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Welcome, $name!',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your restaurant and monitor '
              'your food submissions.',
            ),

            const SizedBox(height: 25),

            // RESTAURANT PROFILE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,

                  leading: SizedBox(
                    width: 65,
                    height: 65,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: logoUrl.isEmpty
                          ? Container(
                              color: Colors.red.shade50,
                              child: const Icon(
                                Icons.store,
                                color: Colors.red,
                                size: 35,
                              ),
                            )
                          : Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return const Icon(
                                  Icons.store,
                                  color: Colors.red,
                                );
                              },
                            ),
                    ),
                  ),

                  title: Text(
                    restaurantName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    restaurant == null
                        ? 'Create your restaurant profile'
                        : 'Verified Restaurant Account\n'
                            'Profile active',
                    maxLines: 3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // MENU OVERVIEW
            const Text(
              'Menu Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >= 700 ? 4 : 2;

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 150,

                  children: [
                    statCard(
                      'Total Foods',
                      total,
                      Icons.fastfood,
                      Colors.blue,
                    ),

                    statCard(
                      'Approved',
                      approved,
                      Icons.check_circle,
                      Colors.green,
                    ),

                    statCard(
                      'Pending',
                      pending,
                      Icons.schedule,
                      Colors.orange,
                    ),

                    statCard(
                      'Rejected',
                      rejected,
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // QUICK ACTIONS
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => openMenu(context),
                  icon: const Icon(Icons.restaurant_menu),
                  label: Text(
                    restaurant == null
                        ? 'Create Restaurant Profile'
                        : 'Manage Menu and Profile',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Text(
              'To add food pictures, use a public '
              'Image URL in Manage Menu. '
              'Firebase Storage uploads are disabled.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // RECENT FOOD SUBMISSIONS
            const Text(
              'Recent Food Submissions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (recentFoods.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Text(
                    'No food items yet. '
                    'Click Manage Menu to add products.',
                  ),
                ),
              )
            else
              ...recentFoods.take(6).map((doc) {
                final food = doc.data();

                final foodName =
                    food['name']?.toString() ?? 'Food';

                final status =
                    food['approvalStatus']?.toString() ??
                        'pending';

                final calories =
                    food['calories']?.toString() ?? '0';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,

                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.fastfood,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 10),

                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 210,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    foodName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Text('$calories kcal'),
                                ],
                              ),
                            ),
                          ],
                        ),

                        statusBadge(status),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 25),

            Card(
              color: Colors.red.shade50,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Reminder: Food items must be approved '
                  'by the FastFit Admin before customers '
                  'can view them. Always provide accurate '
                  'nutritional information.',
                ),
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FastFit Restaurant Center',
          overflow: TextOverflow.ellipsis,
        ),
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
      ),

      body: approvalStatus != 'approved'
          ? waitingScreen()
          : StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
              stream: FoodService().getMyRestaurant(),
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

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: FoodService().myFoods(),
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

                    return dashboard(
                      context,
                      restaurantSnapshot.data!.data(),
                      foodSnapshot.data!.docs,
                    );
                  },
                );
              },
            ),
    );
  }
}
  