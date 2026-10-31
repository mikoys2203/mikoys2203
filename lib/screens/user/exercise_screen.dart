import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/fitness_service.dart';
import '../../services/meal_activity_planner.dart';
import '../../widgets/fastfit_motion.dart';
import 'fitness_hub_screen.dart';
import 'home_workouts_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final String foodName;
  /// Total energy for the servings selected in Food Details.
  final double mealCalories;
  final double weightKg;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;
  final int servings;

  const ExerciseScreen({
    super.key,
    required this.foodName,
    required this.mealCalories,
    required this.weightKg,
    this.proteinGrams = 0,
    this.carbohydrateGrams = 0,
    this.fatGrams = 0,
    this.servings = 1,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final FitnessService _service = FitnessService();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream;
  int _minutes = 20;
  String? _savingId;

  @override
  void initState() {
    super.initState();
    _profileStream = _service.fitnessProfile();
  }

  Future<void> _recordActivity(FitnessActivity activity) async {
    if (_savingId != null) return;
    setState(() => _savingId = activity.id);
    try {
      await _service.logWorkout(
        activity: activity,
        minutes: _minutes,
        weightKg: widget.weightKg,
        suggestedFromFood: widget.foodName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${activity.name} added to Workout History.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save your workout. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FastFitStyle.line),
      ),
      child: child,
    );
  }

  Widget _mealOverview() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FastFitStyle.softRed,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF4DDDC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('YOUR SELECTED FOOD', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: FastFitStyle.deepRed, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(widget.foodName, style: const TextStyle(
          color: FastFitStyle.ink, fontWeight: FontWeight.w900,
          fontSize: 21)),
        const SizedBox(height: 8),
        Text('${widget.servings} serving${widget.servings == 1 ? '' : 's'}  •  '
            '${widget.mealCalories.toStringAsFixed(0)} kcal',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: FastFitStyle.deepRed)),
        const SizedBox(height: 10),
        Text('${widget.proteinGrams.toStringAsFixed(1)}g protein   •   '
            '${widget.carbohydrateGrams.toStringAsFixed(1)}g carbs   •   '
            '${widget.fatGrams.toStringAsFixed(1)}g fats',
          style: const TextStyle(fontSize: 12, color: FastFitStyle.muted)),
        const SizedBox(height: 14),
        Text(MealActivityPlanner.mealDescription(
            calories: widget.mealCalories,
            protein: widget.proteinGrams,
            carbohydrates: widget.carbohydrateGrams,
            fats: widget.fatGrams),
          style: const TextStyle(color: FastFitStyle.ink, height: 1.45)),
      ]),
    );
  }

  Widget _durationSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Session duration', style: TextStyle(
        color: FastFitStyle.ink, fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 10),
      Wrap(spacing: 9, runSpacing: 9, children: [10, 20, 30, 45].map((duration) {
        final selected = _minutes == duration;
        return ChoiceChip(
          label: Text('$duration min'),
          selected: selected,
          onSelected: (_) => setState(() => _minutes = duration),
          selectedColor: FastFitStyle.red,
          backgroundColor: Colors.white,
          side: BorderSide(color: selected ? FastFitStyle.red : FastFitStyle.line),
          labelStyle: TextStyle(color: selected ? Colors.white : FastFitStyle.ink,
            fontWeight: FontWeight.w700),
          showCheckmark: false,
        );
      }).toList()),
    ]);
  }

  Widget _activityCard(MealActivityPick pick) {
    final activity = pick.activity;
    final energy = FitnessService.calculateCalories(
      met: activity.met,
      weightKg: widget.weightKg,
      minutes: _minutes,
    );
    final saving = _savingId == activity.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FastFitStyle.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 510;
        final detail = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 49, width: 49,
            decoration: BoxDecoration(color: FastFitStyle.softRed,
              borderRadius: BorderRadius.circular(13)),
            child: Icon(activity.icon, color: FastFitStyle.red, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity.name, style: const TextStyle(fontSize: 17,
                fontWeight: FontWeight.w900, color: FastFitStyle.ink)),
              const SizedBox(height: 4),
              Text(pick.reason, style: const TextStyle(
                fontSize: 12.5, height: 1.4, color: FastFitStyle.muted)),
              const SizedBox(height: 9),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _tag(pick.tag, Icons.auto_awesome_outlined),
                _tag('$_minutes min', Icons.schedule_rounded),
                _tag('~${energy.toStringAsFixed(0)} kcal', Icons.local_fire_department_outlined),
              ]),
            ],
          )),
        ]);
        final action = FastFitButton(
          label: saving ? 'Saving...' : 'I completed this',
          icon: Icons.check_circle_outline_rounded,
          loading: saving,
          onPressed: _savingId != null ? null : () => _recordActivity(activity),
        );
        if (narrow) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            detail,
            const SizedBox(height: 14),
            action,
          ]);
        }
        return Row(children: [
          Expanded(child: detail),
          const SizedBox(width: 16),
          action,
        ]);
      }),
    );
  }

  Widget _tag(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: FastFitStyle.surface,
      borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: FastFitStyle.deepRed),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11,
        color: FastFitStyle.deepRed, fontWeight: FontWeight.w600)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastFitStyle.surface,
      appBar: AppBar(
        title: const Text('Activity suggestions',
          style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: FastFitStyle.ink,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profileStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final level = data?['fitnessLevel']?.toString() ?? 'beginner';
          final goal = data?['goal']?.toString() ?? '';
          final picks = MealActivityPlanner.suggestions(
            calories: widget.mealCalories,
            protein: widget.proteinGrams,
            carbohydrates: widget.carbohydrateGrams,
            fats: widget.fatGrams,
            fitnessLevel: level,
            goal: goal,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1030),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Find movement that fits your day',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                    color: FastFitStyle.ink)),
                const SizedBox(height: 7),
                const Text('These ideas consider your selected food, portion size and fitness level. You choose what feels right.',
                  style: TextStyle(color: FastFitStyle.muted, height: 1.5)),
                const SizedBox(height: 18),
                _mealOverview(),
                const SizedBox(height: 18),
                _section(child: _durationSelector()),
                const SizedBox(height: 24),
                Text('Top matches for ${widget.foodName}',
                  style: const TextStyle(fontSize: 21,
                    color: FastFitStyle.ink, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Estimates use your saved weight and the duration you choose.',
                  style: TextStyle(fontSize: 13, color: FastFitStyle.muted)),
                const SizedBox(height: 16),
                for (final pick in picks) _activityCard(pick),
                const SizedBox(height: 12),
                _section(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Prefer to exercise at home?',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: FastFitStyle.ink)),
                  const SizedBox(height: 7),
                  const Text('Explore bodyweight, mobility and beginner-friendly routines without gym equipment.',
                    style: TextStyle(color: FastFitStyle.muted, height: 1.5)),
                  const SizedBox(height: 13),
                  FastFitButton(label: 'Browse home workouts',
                    icon: Icons.arrow_forward_rounded, fillWidth: true, outlined: true,
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HomeWorkoutsScreen())),
                  ),
                ])),
                const SizedBox(height: 13),
                FastFitButton(label: 'View workout history',
                  icon: Icons.insights_rounded, fillWidth: true, outlined: true,
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FitnessHubScreen())),
                ),
                const SizedBox(height: 18),
                const Text('You do not need to exercise to compensate for eating. Calorie estimates are approximate and activity should suit your comfort and ability. Only record completed workouts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FastFitStyle.muted, fontSize: 11.5, height: 1.45)),
              ]),
            )),
          );
        },
      ),
    );
  }
}
