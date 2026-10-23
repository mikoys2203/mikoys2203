
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsPanel extends StatelessWidget {
  const AdminAnalyticsPanel({super.key});

  Widget statCard(
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 180,
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 27),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 29,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 27,
        bottom: 12,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget progressRow(
    String label,
    int value,
    int total,
    Color color,
  ) {
    final progress = total == 0 ? 0.0 : value / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$value / $total'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            color: color,
            backgroundColor: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }

  Widget dashboard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> restaurants,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> foods,
  ) {
    int normalUsers = 0;
    int admins = 0;
    int restaurantAccounts = 0;
    int pendingAccounts = 0;

    for (final doc in users) {
      final data = doc.data();
      final role = data['role'];

      if (role == 'user') {
        normalUsers++;
      } else if (role == 'admin') {
        admins++;
      } else if (role == 'restaurant') {
        restaurantAccounts++;

        if (data['approvalStatus'] == 'pending') {
          pendingAccounts++;
        }
      }
    }

    final unknownAccounts = users.length -
        normalUsers -
        admins -
        restaurantAccounts;

    int approvedFoods = 0;
    int pendingFoods = 0;
    int rejectedFoods = 0;

    final foodCounts = <String, int>{};

    for (final doc in foods) {
      final data = doc.data();
      final status = data['approvalStatus'];

      if (status == 'approved') {
        approvedFoods++;

        final id = data['restaurantId']?.toString() ?? '';

        foodCounts[id] = (foodCounts[id] ?? 0) + 1;
      } else if (status == 'pending') {
        pendingFoods++;
      } else if (status == 'rejected') {
        rejectedFoods++;
      }
    }

    final unknownFoods = foods.length -
        approvedFoods -
        pendingFoods -
        rejectedFoods;

    final names = <String, String>{};

    for (final doc in restaurants) {
      names[doc.id] =
          doc.data()['name']?.toString() ?? 'Restaurant';
    }

    final topRestaurants = foodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maximum = topRestaurants.isEmpty
        ? 1
        : topRestaurants.first.value;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'FastFit System Analytics',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Live statistics from Cloud Firestore.',
        ),

        sectionTitle('Account Statistics'),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            statCard(
              'Total Accounts',
              users.length,
              Icons.people,
              Colors.blue,
            ),
            statCard(
              'Normal Users',
              normalUsers,
              Icons.person,
              Colors.green,
            ),
            statCard(
              'Restaurant Accounts',
              restaurantAccounts,
              Icons.store,
              Colors.orange,
            ),
            statCard(
              'Administrators',
              admins,
              Icons.shield,
              Colors.purple,
            ),
            statCard(
              'Unclassified Accounts',
              unknownAccounts,
              Icons.warning_amber,
              Colors.red,
            ),
          ],
        ),

        sectionTitle('Restaurant Statistics'),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            statCard(
              'Restaurant Profiles',
              restaurants.length,
              Icons.business,
              Colors.blue,
            ),
            statCard(
              'Pending Registrations',
              pendingAccounts,
              Icons.schedule,
              Colors.orange,
            ),
          ],
        ),

        sectionTitle('Food Menu Statistics'),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            statCard(
              'Total Foods',
              foods.length,
              Icons.fastfood,
              Colors.blue,
            ),
            statCard(
              'Approved Foods',
              approvedFoods,
              Icons.check_circle,
              Colors.green,
            ),
            statCard(
              'Pending Foods',
              pendingFoods,
              Icons.schedule,
              Colors.orange,
            ),
            statCard(
              'Rejected Foods',
              rejectedFoods,
              Icons.cancel,
              Colors.red,
            ),
            statCard(
              'Unclassified Foods',
              unknownFoods,
              Icons.warning_amber,
              Colors.deepOrange,
            ),
          ],
        ),

        const SizedBox(height: 25),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Food Approval Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                progressRow(
                  'Approved',
                  approvedFoods,
                  foods.length,
                  Colors.green,
                ),
                progressRow(
                  'Pending',
                  pendingFoods,
                  foods.length,
                  Colors.orange,
                ),
                progressRow(
                  'Rejected',
                  rejectedFoods,
                  foods.length,
                  Colors.red,
                ),
                progressRow(
                  'Unclassified',
                  unknownFoods,
                  foods.length,
                  Colors.deepOrange,
                ),
              ],
            ),
          ),
        ),

        sectionTitle('Restaurants by Approved Foods'),

        if (topRestaurants.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No approved food items yet.'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: topRestaurants.take(10).map((entry) {
                  final restaurantName =
                      names[entry.key] ?? 'Unknown Restaurant';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(restaurantName),
                            ),
                            Text('${entry.value} foods'),
                          ],
                        ),
                        const SizedBox(height: 9),
                        LinearProgressIndicator(
                          value: entry.value / maximum,
                          color: Colors.red,
                          backgroundColor:
                              Colors.grey.shade200,
                          minHeight: 10,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        if (unknownAccounts > 0 || unknownFoods > 0) ...[
          const SizedBox(height: 20),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Data check recommended:\n'
                '$unknownAccounts account(s) have '
                'an unrecognized or missing role.\n'
                '$unknownFoods food item(s) have '
                'an unrecognized or missing approval status.\n\n'
                'Open the Data Audit tab to inspect them.',
              ),
            ),
          ),
        ],

        const SizedBox(height: 30),
        const Text(
          'Counts include all documents in each collection, '
          'including incomplete records. These are database '
          'statistics, not the number of people currently online.',
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
    final db = FirebaseFirestore.instance;

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Center(
            child: Text('User error: ${userSnapshot.error}'),
          );
        }

        if (!userSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('restaurants').snapshots(),
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
              stream: db.collection('food_items').snapshots(),
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
                  userSnapshot.data!.docs,
                  restaurantSnapshot.data!.docs,
                  foodSnapshot.data!.docs,
                );
              },
            );
          },
        );
      },
    );
  }
}
