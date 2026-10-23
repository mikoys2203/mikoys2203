
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditRecord {
  final String type;
  final String title;
  final String path;
  final String status;
  final List<String> issues;

  const AuditRecord({
    required this.type,
    required this.title,
    required this.path,
    required this.status,
    required this.issues,
  });
}

class AdminDataAuditPanel extends StatefulWidget {
  const AdminDataAuditPanel({super.key});

  @override
  State<AdminDataAuditPanel> createState() =>
      _AdminDataAuditPanelState();
}

class _AdminDataAuditPanelState
    extends State<AdminDataAuditPanel> {
  final db = FirebaseFirestore.instance;

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      usersStream;

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      restaurantsStream;

  late final Stream<QuerySnapshot<Map<String, dynamic>>>
      foodsStream;

  String search = '';
  String selectedFilter = 'Issues only';

  @override
  void initState() {
    super.initState();

    usersStream = db.collection('users').snapshots();
    restaurantsStream =
        db.collection('restaurants').snapshots();
    foodsStream = db.collection('food_items').snapshots();
  }

  String value(dynamic data) {
    return data?.toString().trim() ?? '';
  }

  String normalized(dynamic data) {
    return value(data).toLowerCase();
  }

  // ====================================
  // CHECK DATABASE RECORDS
  // ====================================

  List<AuditRecord> inspectDatabase(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> restaurants,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> foods,
  ) {
    final records = <AuditRecord>[];

    final userMap = {
      for (final doc in users) doc.id: doc.data(),
    };

    final restaurantMap = {
      for (final doc in restaurants) doc.id: doc.data(),
    };

    final emailCounts = <String, int>{};
    final foodNameCounts = <String, int>{};

    for (final doc in users) {
      final email = normalized(doc.data()['email']);

      if (email.isNotEmpty) {
        emailCounts[email] = (emailCounts[email] ?? 0) + 1;
      }
    }

    for (final doc in foods) {
      final food = doc.data();

      final key =
          '${normalized(food['restaurantId'])}|'
          '${normalized(food['name'])}';

      if (normalized(food['name']).isNotEmpty) {
        foodNameCounts[key] =
            (foodNameCounts[key] ?? 0) + 1;
      }
    }

    // ====================================
    // AUDIT USER ACCOUNTS
    // ====================================

    for (final doc in users) {
      final data = doc.data();

      final role = value(data['role']);
      final status = value(data['approvalStatus']);
      final name = value(data['name']);
      final email = normalized(data['email']);

      final issues = <String>[];

      if (!['user', 'restaurant', 'admin'].contains(role)) {
        issues.add(
          'Missing or unrecognized account role.',
        );
      }

      if (name.isEmpty) {
        issues.add('Account name is missing.');
      }

      if (email.isEmpty) {
        issues.add('Email address is missing.');
      }

      if (email.isNotEmpty &&
          (emailCounts[email] ?? 0) > 1) {
        issues.add(
          'The same email appears in multiple '
          'Firestore user profiles.',
        );
      }

      if (role == 'user' && status != 'active') {
        issues.add(
          'Normal user has an unexpected approval status.',
        );
      }

      if (role == 'restaurant') {
        if (!['pending', 'approved', 'rejected']
            .contains(status)) {
          issues.add(
            'Restaurant account has an invalid status.',
          );
        }

        if (status == 'approved' &&
            !restaurantMap.containsKey(doc.id)) {
          issues.add(
            'Approved restaurant account has not '
            'created its restaurant profile yet.',
          );
        }
      }

      records.add(
        AuditRecord(
          type: 'Account',
          title: name.isEmpty ? 'Unnamed Account' : name,
          path: 'users/${doc.id}',
          status: role.isEmpty ? 'UNCLASSIFIED' : role,
          issues: issues,
        ),
      );
    }

    // ====================================
    // AUDIT RESTAURANT PROFILES
    // ====================================

    for (final doc in restaurants) {
      final data = doc.data();

      final name = value(data['name']);
      final ownerId = value(data['ownerId']);
      final status = value(data['approvalStatus']);

      final issues = <String>[];

      if (name.isEmpty) {
        issues.add('Restaurant name is missing.');
      }

      if (ownerId.isEmpty) {
        issues.add('Restaurant owner ID is missing.');
      } else {
        if (ownerId != doc.id) {
          issues.add(
            'Restaurant document ID does not '
            'match its owner ID.',
          );
        }

        if (!userMap.containsKey(ownerId)) {
          issues.add(
            'Restaurant owner does not have '
            'a matching Firestore user profile.',
          );
        } else if (
          userMap[ownerId]?['role'] != 'restaurant'
        ) {
          issues.add(
            'Restaurant owner has an unexpected role.',
          );
        }
      }

      if (status != 'approved') {
        issues.add(
          'Restaurant profile has an unexpected status.',
        );
      }

      records.add(
        AuditRecord(
          type: 'Restaurant',
          title: name.isEmpty ? 'Unnamed Restaurant' : name,
          path: 'restaurants/${doc.id}',
          status: status.isEmpty ? 'UNCLASSIFIED' : status,
          issues: issues,
        ),
      );
    }

    // ====================================
    // AUDIT FOOD ITEMS
    // ====================================

    for (final doc in foods) {
      final data = doc.data();

      final name = value(data['name']);
      final restaurantId = value(data['restaurantId']);
      final status = value(data['approvalStatus']);

      final issues = <String>[];

      if (!['approved', 'pending', 'rejected']
          .contains(status)) {
        issues.add(
          'Missing or unrecognized food approval status.',
        );
      }

      if (name.isEmpty) {
        issues.add('Food name is missing.');
      }

      if (value(data['servingSize']).isEmpty) {
        issues.add('Serving size is missing.');
      }

      if (restaurantId.isEmpty) {
        issues.add('Restaurant ID is missing.');
      } else if (!restaurantMap.containsKey(restaurantId)) {
        issues.add(
          'Food item has no matching restaurant profile.',
        );
      }

      for (final field in [
        'calories',
        'protein',
        'carbohydrates',
        'fats',
      ]) {
        final amount = data[field];

        if (amount is! num || !amount.isFinite ||
            amount < 0) {
          issues.add(
            '$field has a missing or invalid value.',
          );
        }
      }

      final foodKey =
          '${normalized(restaurantId)}|${normalized(name)}';

      if (name.isNotEmpty &&
          (foodNameCounts[foodKey] ?? 0) > 1) {
        issues.add(
          'Possible duplicate food name '
          'within the same restaurant.',
        );
      }

      // Approximate energy consistency check.
      // This is only a flag for review.
      final calories = data['calories'];
      final protein = data['protein'];
      final carbs = data['carbohydrates'];
      final fats = data['fats'];

      if (calories is num &&
          protein is num &&
          carbs is num &&
          fats is num &&
          calories > 0 &&
          protein >= 0 &&
          carbs >= 0 &&
          fats >= 0) {
        final estimatedEnergy =
            protein * 4 + carbs * 4 + fats * 9;

        final difference =
            (estimatedEnergy - calories).abs();

        final threshold = calories * 0.40 > 120
            ? calories * 0.40
            : 120.0;

        if (difference > threshold) {
          issues.add(
            'Large difference between entered calories '
            'and estimated energy from macros. '
            'Verify the source and serving size.',
          );
        }
      }

      records.add(
        AuditRecord(
          type: 'Food',
          title: name.isEmpty ? 'Unnamed Food' : name,
          path: 'food_items/${doc.id}',
          status: status.isEmpty ? 'UNCLASSIFIED' : status,
          issues: issues,
        ),
      );
    }

    records.sort((a, b) {
      final aProblem = a.issues.isNotEmpty ? 0 : 1;
      final bProblem = b.issues.isNotEmpty ? 0 : 1;

      final comparison = aProblem.compareTo(bProblem);

      if (comparison != 0) return comparison;

      return a.title.toLowerCase()
          .compareTo(b.title.toLowerCase());
    });

    return records;
  }

  // ====================================
  // COPY AUDIT REPORT
  // ====================================

  String csvValue(String text) {
    final cleaned = text.replaceAll('\n', ' ');
    return '"${cleaned.replaceAll('"', '""')}"';
  }

  Future<void> copyReport(
    List<AuditRecord> records,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('FastFit Data Audit Report');
    buffer.writeln(
      'Generated,${DateTime.now().toIso8601String()}',
    );

    buffer.writeln(
      'Type,Name,Firestore Path,Status,Findings',
    );

    for (final record in records) {
      buffer.writeln([
        csvValue(record.type),
        csvValue(record.title),
        csvValue(record.path),
        csvValue(record.status),
        csvValue(
          record.issues.isEmpty
              ? 'No issues found'
              : record.issues.join('; '),
        ),
      ].join(','));
    }

    await Clipboard.setData(
      ClipboardData(text: buffer.toString()),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Audit report copied. Paste it into a file '
          'or spreadsheet.',
        ),
      ),
    );
  }

  // ====================================
  // AUDIT CARD
  // ====================================

  Widget recordCard(AuditRecord record) {
    final hasIssues = record.issues.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  hasIssues
                      ? Icons.warning_amber
                      : Icons.check_circle,
                  color: hasIssues
                      ? Colors.orange
                      : Colors.green,
                ),
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(record.type),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 8),

            SelectableText(
              record.path,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 7),

            Text('Role / Status: ${record.status}'),

            const SizedBox(height: 10),

            if (hasIssues)
              for (final issue in record.issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.orange,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(issue),
                      ),
                    ],
                  ),
                )
            else
              const Text(
                'No issues detected by this audit.',
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // AUDIT DASHBOARD
  // ====================================

  Widget auditDashboard(List<AuditRecord> records) {
    final issues = records.where(
      (record) => record.issues.isNotEmpty,
    ).toList();

    final accounts = records.where(
      (record) => record.type == 'Account',
    ).length;

    final foods = records.where(
      (record) => record.type == 'Food',
    ).length;

    final restaurants = records.where(
      (record) => record.type == 'Restaurant',
    ).length;

    final filtered = records.where((record) {
      bool matchesFilter = true;

      if (selectedFilter == 'Issues only') {
        matchesFilter = record.issues.isNotEmpty;
      } else if (selectedFilter == 'Accounts') {
        matchesFilter = record.type == 'Account';
      } else if (selectedFilter == 'Food items') {
        matchesFilter = record.type == 'Food';
      } else if (selectedFilter == 'Restaurants') {
        matchesFilter = record.type == 'Restaurant';
      }

      final text =
          '${record.title} ${record.path} '
          '${record.type} ${record.status} '
          '${record.issues.join(' ')}'
              .toLowerCase();

      return matchesFilter && text.contains(search);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'FastFit Data Audit Center',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Inspect accounts, restaurants and food '
          'records without changing their data.',
        ),

        const SizedBox(height: 22),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Chip(
              avatar: const Icon(Icons.people),
              label: Text('$accounts Accounts'),
            ),
            Chip(
              avatar: const Icon(Icons.store),
              label: Text('$restaurants Restaurants'),
            ),
            Chip(
              avatar: const Icon(Icons.fastfood),
              label: Text('$foods Foods'),
            ),
            Chip(
              avatar: const Icon(Icons.warning_amber),
              label: Text(
                '${issues.length} Records to Review',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        TextField(
          decoration: const InputDecoration(
            labelText: 'Search records',
            hintText: 'Name, status, document ID...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (text) {
            setState(() {
              search = text.trim().toLowerCase();
            });
          },
        ),

        const SizedBox(height: 15),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedFilter,
              items: const [
                DropdownMenuItem(
                  value: 'Issues only',
                  child: Text('Issues only'),
                ),
                DropdownMenuItem(
                  value: 'All records',
                  child: Text('All records'),
                ),
                DropdownMenuItem(
                  value: 'Accounts',
                  child: Text('Accounts'),
                ),
                DropdownMenuItem(
                  value: 'Restaurants',
                  child: Text('Restaurants'),
                ),
                DropdownMenuItem(
                  value: 'Food items',
                  child: Text('Food items'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedFilter = value);
                }
              },
            ),

            OutlinedButton.icon(
              onPressed: () => copyReport(records),
              icon: const Icon(Icons.copy),
              label: const Text('Copy Audit Report'),
            ),
          ],
        ),

        const SizedBox(height: 15),

        Text(
          '${filtered.length} matching record(s)',
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 12),

        if (filtered.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Text(
                'No records match your current filter.',
              ),
            ),
          )
        else
          for (final record in filtered)
            recordCard(record),

        const SizedBox(height: 20),

        const Text(
          'This is a read-only audit. A flag is a request '
          'for review, not proof that the data is wrong. '
          'Nutrition energy estimates can differ because '
          'of rounding, fiber, and other factors. '
          'The audit inspects Firestore documents, '
          'not the complete Firebase Authentication user list.',
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
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Center(
            child: Text(
              'Unable to read users: ${userSnapshot.error}',
            ),
          );
        }

        if (!userSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: restaurantsStream,
          builder: (context, restaurantSnapshot) {
            if (restaurantSnapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to read restaurants: '
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
              stream: foodsStream,
              builder: (context, foodSnapshot) {
                if (foodSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to read foods: '
                      '${foodSnapshot.error}',
                    ),
                  );
                }

                if (!foodSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final records = inspectDatabase(
                  userSnapshot.data!.docs,
                  restaurantSnapshot.data!.docs,
                  foodSnapshot.data!.docs,
                );

                return auditDashboard(records);
              },
            );
          },
        );
      },
    );
  }
}

