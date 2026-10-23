
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/fitness_service.dart';
import 'fitness_onboarding_screen.dart';

class FitnessHubScreen extends StatefulWidget {
  const FitnessHubScreen({super.key});

  @override
  State<FitnessHubScreen> createState() =>
      _FitnessHubScreenState();
}

class _FitnessHubScreenState extends State<FitnessHubScreen> {
  final FitnessService service = FitnessService();

  int selectedMinutes = 20;
  String? savingActivity;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> recordWorkout(
    FitnessActivity activity,
    double weight,
  ) async {
    if (savingActivity != null) return;

    setState(() => savingActivity = activity.id);

    try {
      await service.logWorkout(
        activity: activity,
        minutes: selectedMinutes,
        weightKg: weight,
      );

      showMessage('${activity.name} workout recorded!');
    } catch (e) {
      showMessage('Unable to save workout: $e');
    } finally {
      if (mounted) {
        setState(() => savingActivity = null);
      }
    }
  }

  Future<void> removeWorkout(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Workout?'),
          content: const Text(
            'Remove this record from your activity history?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await service.deleteWorkout(id);
      showMessage('Workout removed.');
    } catch (e) {
      showMessage('Unable to delete workout: $e');
    }
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return SizedBox(
      width: 185,
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget weeklyChart(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> logs,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final weekStart = today.subtract(
      Duration(days: now.weekday - 1),
    );

    final List<int> dailyMinutes = List.filled(7, 0);

    for (final log in logs) {
      final data = log.data();
      final timestamp = data['completedAt'];

      if (timestamp is! Timestamp) continue;

      final date = timestamp.toDate().toLocal();
      final minutes = data['minutes'];

      if (minutes is! int) continue;

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));

        if (DateUtils.isSameDay(date, day)) {
          dailyMinutes[i] += minutes;
          break;
        }
      }
    }

    int maxMinutes = 1;

    for (final minutes in dailyMinutes) {
      if (minutes > maxMinutes) {
        maxMinutes = minutes;
      }
    }

    final labels = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Activity',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Minutes of exercise recorded this week',
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 185,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final value = dailyMinutes[index];

                  final height = value == 0
                      ? 4.0
                      : 125.0 * value / maxMinutes;

                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            labels[index],
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget activityCard(
    FitnessActivity activity,
    double weight,
  ) {
    final estimate = FitnessService.calculateCalories(
      met: activity.met,
      weightKg: weight,
      minutes: selectedMinutes,
    );

    final busy = savingActivity == activity.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 15,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              activity.icon,
              color: Colors.red,
              size: 35,
            ),

            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(activity.description),
                  const SizedBox(height: 5),
                  Text(
                    '~${estimate.toStringAsFixed(0)} kcal '
                    'for $selectedMinutes min',
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(
                busy ? 'Saving...' : 'I Completed This',
              ),
              onPressed: savingActivity != null
                  ? null
                  : () => recordWorkout(activity, weight),
            ),
          ],
        ),
      ),
    );
  }

  Widget historyList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> logs,
  ) {
    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: Text(
            'No workouts recorded yet. '
            'Complete an activity to begin your history.',
          ),
        ),
      );
    }

    return Column(
      children: logs.take(12).map((doc) {
        final data = doc.data();

        final timestamp = data['completedAt'];

        final date = timestamp is Timestamp
            ? timestamp.toDate().toLocal()
            : null;

        final dateLabel = date == null
            ? 'Recently added'
            : '${date.month}/${date.day}/${date.year}';

        final calories = data['estimatedCalories'];

        final calorieText = calories is num
            ? calories.toStringAsFixed(0)
            : '0';

        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(
                Icons.fitness_center,
                color: Colors.white,
              ),
            ),

            title: Text(
              data['activityName']?.toString() ??
                  'Exercise',
            ),

            subtitle: Text(
              '$dateLabel • ${data['minutes']} minutes',
            ),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('~$calorieText kcal'),

                IconButton(
                  tooltip: 'Delete workout',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => removeWorkout(doc.id),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget dashboardContent(
    Map<String, dynamic> fitness,
    Map<String, dynamic> user,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> logs,
  ) {
    final weightValue = user['weight'] ?? fitness['weightKg'];

    final double weight = weightValue is num
        ? weightValue.toDouble()
        : 0;

    final String goal =
        user['fitnessGoal']?.toString() ??
            fitness['goal']?.toString() ??
            'maintain weight';

    final String level =
        fitness['fitnessLevel']?.toString() ?? 'beginner';

    final targetWeight = fitness['targetWeightKg'];

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    int weeklySessions = 0;
    int weeklyMinutes = 0;
    double weeklyEnergy = 0;

    for (final doc in logs) {
      final data = doc.data();
      final timestamp = data['completedAt'];

      if (timestamp is! Timestamp) continue;

      final date = timestamp.toDate().toLocal();

      if (!date.isBefore(start) &&
          date.isBefore(start.add(const Duration(days: 7)))) {
        weeklySessions++;
        weeklyMinutes +=
            (data['minutes'] as num?)?.toInt() ?? 0;
        weeklyEnergy +=
            (data['estimatedCalories'] as num?)
                ?.toDouble() ?? 0;
      }
    }

    final recommended =
        FitnessService.recommendedActivities(level);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Fitness Hub',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Build healthy activity habits at your own pace.',
              ),

              const SizedBox(height: 22),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Fitness Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text('Fitness goal: $goal'),
                      Text('Fitness level: $level'),
                      Text(
                        'Current weight: '
                        '${weight.toStringAsFixed(1)} kg',
                      ),
                      Text(
                        'Target weight: $targetWeight kg',
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton.icon(
                        onPressed: () {
                          final editData = {
                            ...fitness,
                            'weightKg': weight,
                            'goal': goal,
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FitnessOnboardingScreen(
                                existingProfile: editData,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text(
                          'Edit Onboarding Details',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Your Progress This Week',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  statCard(
                    'Workout Sessions',
                    '$weeklySessions',
                    Icons.check_circle,
                  ),
                  statCard(
                    'Exercise Minutes',
                    '$weeklyMinutes',
                    Icons.timer,
                  ),
                  statCard(
                    'Estimated Energy',
                    '~${weeklyEnergy.toStringAsFixed(0)} kcal',
                    Icons.local_fire_department,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              weeklyChart(logs),

              const SizedBox(height: 25),

              const Text(
                'Suggested Activities',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Activities for your $level experience level',
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  const Text('Session length: '),
                  const SizedBox(width: 10),

                  DropdownButton<int>(
                    value: selectedMinutes,
                    items: const [
                      DropdownMenuItem(
                        value: 15,
                        child: Text('15 min'),
                      ),
                      DropdownMenuItem(
                        value: 20,
                        child: Text('20 min'),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text('30 min'),
                      ),
                      DropdownMenuItem(
                        value: 45,
                        child: Text('45 min'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMinutes = value;
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (weight > 0)
                for (final activity in recommended)
                  activityCard(activity, weight)
              else
                const Text(
                  'Please set your weight in your profile.',
                ),

              const SizedBox(height: 24),

              const Text(
                'Workout History',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              historyList(logs),

              const SizedBox(height: 20),

              const Text(
                'Workout calories are estimates. Exercise '
                'should support your health and enjoyment, '
                'not serve as a requirement to offset meals. '
                'Choose activities suitable for your abilities.',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FastFit Fitness Hub'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.fitnessProfile(),
        builder: (context, fitnessSnapshot) {
          if (fitnessSnapshot.hasError) {
            return Center(
              child: Text(
                'Fitness profile error: '
                '${fitnessSnapshot.error}',
              ),
            );
          }

          if (!fitnessSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final fitness = fitnessSnapshot.data!.data();

          if (fitness == null) {
            return const Center(
              child: Text('Fitness setup is not completed.'),
            );
          }

          return StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            stream: service.userProfile(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return Center(
                  child: Text(
                    'User profile error: '
                    '${userSnapshot.error}',
                  ),
                );
              }

              if (!userSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final user = userSnapshot.data!.data() ??
                  <String, dynamic>{};

              return StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: service.workouts(),
                builder: (context, workoutSnapshot) {
                  if (workoutSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Workout error: '
                        '${workoutSnapshot.error}',
                      ),
                    );
                  }

                  if (!workoutSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return dashboardContent(
                    fitness,
                    user,
                    workoutSnapshot.data!.docs,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
