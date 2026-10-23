
import 'package:flutter/material.dart';
import '../../services/fitness_service.dart';
import 'fitness_hub_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final String foodName;
  final double mealCalories;
  final double weightKg;

  const ExerciseScreen({
    super.key,
    required this.foodName,
    required this.mealCalories,
    required this.weightKg,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final FitnessService service = FitnessService();

  int minutes = 20;
  String? savingId;

  Future<void> recordActivity(
    FitnessActivity activity,
  ) async {
    if (savingId != null) return;

    setState(() => savingId = activity.id);

    try {
      await service.logWorkout(
        activity: activity,
        minutes: minutes,
        weightKg: widget.weightKg,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${activity.name} saved to Workout History.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save workout: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => savingId = null);
      }
    }
  }

  Widget activityCard(FitnessActivity activity) {
    final calories = FitnessService.calculateCalories(
      met: activity.met,
      weightKg: widget.weightKg,
      minutes: minutes,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 15,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              activity.icon,
              color: Colors.red,
              size: 42,
            ),

            SizedBox(
              width: 235,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(activity.description),

                  const SizedBox(height: 8),

                  Text(
                    '$minutes minutes • '
                    '~${calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ElevatedButton.icon(
              onPressed: savingId != null
                  ? null
                  : () => recordActivity(activity),
              icon: const Icon(Icons.check),
              label: const Text('I Completed This'),
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
        title: const Text('Exercise Recommendations'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder(
        stream: service.fitnessProfile(),
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

          final fitness = snapshot.data!.data();
          final level =
              fitness?['fitnessLevel']?.toString() ??
                  'beginner';

          final recommended =
              FitnessService.recommendedActivities(level);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Selected Meal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const Icon(
                          Icons.restaurant,
                          color: Colors.red,
                          size: 35,
                        ),
                        title: Text(widget.foodName),
                        subtitle: Text(
                          'Meal energy: '
                          '${widget.mealCalories.toStringAsFixed(0)} kcal',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Your Weight: '
                      '${widget.weightKg.toStringAsFixed(1)} kg',
                    ),

                    Text(
                      'Fitness Level: $level',
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Recommended Activities',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Choose an activity you enjoy. '
                      'The suggestions are not a requirement '
                      'to burn off the energy from your meal.',
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Text('Exercise Duration: '),

                        const SizedBox(width: 10),

                        DropdownButton<int>(
                          value: minutes,
                          items: const [
                            DropdownMenuItem(
                              value: 15,
                              child: Text('15 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 20,
                              child: Text('20 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text('30 minutes'),
                            ),
                            DropdownMenuItem(
                              value: 45,
                              child: Text('45 minutes'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => minutes = value);
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    for (final activity in recommended)
                      activityCard(activity),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.insights),
                        label: const Text(
                          'View My Fitness Progress',
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FitnessHubScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Calorie expenditure is estimated using '
                      'activity intensity, body weight, and duration. '
                      'Actual values vary. Record a workout only '
                      'after you have completed it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
