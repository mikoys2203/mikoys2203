import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/fitness_service.dart';
import '../../widgets/fastfit_motion.dart';
import 'fitness_hub_screen.dart';

class _HomeRoutine {
  final String title;
  final String description;
  final String activityId;
  final String category;
  final int minutes;
  final String level;
  final IconData icon;
  final List<String> steps;

  const _HomeRoutine({
    required this.title,
    required this.description,
    required this.activityId,
    required this.category,
    required this.minutes,
    required this.level,
    required this.icon,
    required this.steps,
  });
}

class HomeWorkoutsScreen extends StatefulWidget {
  const HomeWorkoutsScreen({super.key});

  @override
  State<HomeWorkoutsScreen> createState() => _HomeWorkoutsScreenState();
}

class _HomeWorkoutsScreenState extends State<HomeWorkoutsScreen> {
  final FitnessService _service = FitnessService();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _fitnessStream;
  String _levelFilter = 'All';
  String _categoryFilter = 'All';
  bool _saving = false;

  static const List<_HomeRoutine> _routines = [
    _HomeRoutine(
      title: 'Beginner Full Body',
      category: 'Full Body',
      description: 'Build consistency with low-impact movements.',
      activityId: 'home_beginner',
      minutes: 15,
      level: 'Beginner',
      icon: Icons.home_rounded,
      steps: [
        '2 min — gentle marching warm-up',
        '2 sets — 8 chair squats',
        '2 sets — 8 wall push-ups',
        '4 min — alternating side steps',
        '3 min — gentle cooldown and stretching',
      ],
    ),
    _HomeRoutine(
      title: 'Core & Balance',
      category: 'Core',
      description: 'Focus on stability with controlled exercises.',
      activityId: 'core',
      minutes: 20,
      level: 'Intermediate',
      icon: Icons.accessibility_new_rounded,
      steps: [
        '3 min — warm up and breathing',
        '3 sets — 10 dead bugs (each side)',
        '3 sets — 20 sec plank holds',
        '3 sets — 10 bird-dogs (each side)',
        '4 min — stretching and cooldown',
      ],
    ),
    _HomeRoutine(
      title: 'Upper Body Strength',
      category: 'Upper Body',
      description: 'A no-gym routine for arms, shoulders and back.',
      activityId: 'home_strength',
      minutes: 20,
      level: 'Intermediate',
      icon: Icons.fitness_center_rounded,
      steps: [
        '3 min — shoulder and arm warm-up',
        '3 sets — 8 modified push-ups',
        '3 sets — 12 slow arm raises',
        '3 sets — 10 prone back extensions',
        '4 min — shoulder stretch and cooldown',
      ],
    ),
    _HomeRoutine(
      title: '10-minute Mobility',
      category: 'Mobility',
      description: 'An easy reset between studying or working.',
      activityId: 'stretch',
      minutes: 10,
      level: 'Beginner',
      icon: Icons.self_improvement_rounded,
      steps: [
        '2 min — slow shoulder circles',
        '2 min — neck and upper back mobility',
        '2 min — seated hip mobility',
        '2 min — calf and hamstring stretch',
        '2 min — relaxed breathing',
      ],
    ),
    _HomeRoutine(
      title: 'Dance Cardio',
      category: 'Cardio',
      description: 'Light, enjoyable movement in your own space.',
      activityId: 'dance',
      minutes: 20,
      level: 'Beginner',
      icon: Icons.music_note_rounded,
      steps: [
        '3 min — step-touch warm-up',
        '5 min — side steps and arm swings',
        '5 min — easy dance combinations',
        '4 min — comfortable freestyle movement',
        '3 min — slow cooldown',
      ],
    ),
    _HomeRoutine(
      title: 'Yoga & Relaxation',
      category: 'Recovery',
      description: 'Gentle stretching and calm movement.',
      activityId: 'yoga',
      minutes: 20,
      level: 'Beginner',
      icon: Icons.spa_rounded,
      steps: [
        '3 min — diaphragmatic breathing',
        '4 min — cat-cow and back mobility',
        '5 min — gentle standing poses',
        '4 min — seated stretches',
        '4 min — relaxation',
      ],
    ),
    _HomeRoutine(
      title: 'Lower Body Basics',
      category: 'Lower Body',
      description: 'Strengthen legs and glutes with simple home movements.',
      activityId: 'home_strength',
      minutes: 20,
      level: 'Intermediate',
      icon: Icons.directions_walk_rounded,
      steps: [
        '3 min — gentle march and leg swings',
        '3 sets — 10 controlled squats',
        '2 sets — 10 reverse lunges each side',
        '3 sets — 12 glute bridges',
        '3 min — easy stretch and cooldown',
      ],
    ),
    _HomeRoutine(
      title: 'Quick Cardio Starter',
      category: 'Cardio',
      description: 'A joint-friendly boost of movement in 15 minutes.',
      activityId: 'home_beginner',
      minutes: 15,
      level: 'Beginner',
      icon: Icons.directions_run_rounded,
      steps: [
        '3 min — slow marching warm-up',
        '3 min — gentle step-touch',
        '3 min — alternating knee lifts',
        '3 min — march and arm swings',
        '3 min — easy cooldown',
      ],
    ),
    _HomeRoutine(
      title: 'Full Body Circuit',
      category: 'Full Body',
      description: 'A stronger bodyweight circuit with time to rest.',
      activityId: 'bodyweight',
      minutes: 25,
      level: 'Intermediate',
      icon: Icons.sports_gymnastics_rounded,
      steps: [
        '4 min — whole-body warm-up',
        '3 rounds — 10 squats and 8 push-ups',
        '3 rounds — 10 hip hinges and 20 sec plank',
        '5 min — light cardio with recovery breaks',
        '4 min — cooldown stretching',
      ],
    ),
    _HomeRoutine(
      title: 'Desk Break Stretch',
      category: 'Mobility',
      description: 'A quick, calm reset after sitting or studying.',
      activityId: 'stretch',
      minutes: 10,
      level: 'Beginner',
      icon: Icons.accessibility_new_rounded,
      steps: [
        '2 min — slow shoulder rolls',
        '2 min — neck and back mobility',
        '2 min — hip flexor stretch',
        '2 min — easy hamstring stretch',
        '2 min — relaxed breathing',
      ],
    ),
  ];

  static const List<String> _categories = [
    'All', 'Full Body', 'Core', 'Upper Body', 'Lower Body',
    'Cardio', 'Mobility', 'Recovery', 'Quick Sessions',
  ];

  IconData _categoryIcon(String category) => switch (category) {
    'Full Body' => Icons.fitness_center_rounded,
    'Core' => Icons.adjust_rounded,
    'Upper Body' => Icons.sports_martial_arts_rounded,
    'Lower Body' => Icons.directions_walk_rounded,
    'Cardio' => Icons.directions_run_rounded,
    'Mobility' => Icons.accessibility_new_rounded,
    'Recovery' => Icons.self_improvement_rounded,
    'Quick Sessions' => Icons.timer_outlined,
    _ => Icons.apps_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fitnessStream = _service.fitnessProfile();
  }

  Future<void> _showRoutine(_HomeRoutine routine, double? weight) async {
    var completed = false;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: .76,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(routine.title, style: const TextStyle(
                    fontSize: 24, color: FastFitStyle.ink, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Text('${routine.minutes} min  •  ${routine.level}  •  No gym required',
                    style: const TextStyle(color: FastFitStyle.muted)),
                  const SizedBox(height: 18),
                  const Text('Suggested routine', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  for (var i = 0; i < routine.steps.length; i++)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: FastFitStyle.softRed,
                        child: Text('${i + 1}', style: const TextStyle(
                          color: FastFitStyle.deepRed, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                      title: Text(routine.steps[i], style: const TextStyle(fontSize: 14)),
                    ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: FastFitStyle.red,
                    value: completed,
                    onChanged: weight == null || _saving
                        ? null : (value) => setSheetState(() => completed = value ?? false),
                    title: const Text('I have completed this workout',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Only save a workout after finishing it.'),
                  ),
                  if (weight == null)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Add your weight in your fitness profile to record workouts.',
                        style: TextStyle(color: FastFitStyle.deepRed)),
                    ),
                  FastFitButton(
                    label: 'Save completed workout', fillWidth: true,
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: completed && weight != null
                        ? () => Navigator.pop(sheetContext, true) : null,
                  ),
                  const SizedBox(height: 14),
                  const Text('Adjust or skip movements that are uncomfortable. Rest when needed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: FastFitStyle.muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm != true || !mounted || weight == null || _saving) return;
    final activity = FitnessService.activities.firstWhere(
      (value) => value.id == routine.activityId,
    );
    setState(() => _saving = true);
    try {
      await _service.logWorkout(
        activity: activity,
        minutes: routine.minutes,
        weightKg: weight,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your home workout was saved to Workout History.'),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save the workout. Please try again.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _routineCard(_HomeRoutine routine, double? weight) {
    final activity = FitnessService.activities.firstWhere(
      (value) => value.id == routine.activityId,
    );
    final estimatedCalories = weight == null ? null : FitnessService.calculateCalories(
      met: activity.met, weightKg: weight, minutes: routine.minutes,
    );
    final durationLabel = estimatedCalories == null
        ? '${routine.minutes} min'
        : '${routine.minutes} min  •  ~${estimatedCalories.toStringAsFixed(0)} kcal';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FastFitStyle.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            height: 51, width: 51,
            decoration: BoxDecoration(
              color: FastFitStyle.softRed, borderRadius: BorderRadius.circular(14)),
            child: Icon(routine.icon, color: FastFitStyle.red, size: 27),
          ),
          const Spacer(),
          Flexible(child: Text('${routine.category} · ${routine.level}',
            textAlign: TextAlign.right,
            style: const TextStyle(color: FastFitStyle.deepRed,
              fontWeight: FontWeight.w700, fontSize: 11.5))),
        ]),
        const SizedBox(height: 15),
        Text(routine.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18,
          fontWeight: FontWeight.w900, color: FastFitStyle.ink)),
        const SizedBox(height: 7),
        Text(routine.description, maxLines: 3, overflow: TextOverflow.ellipsis,
          style: const TextStyle(
          color: FastFitStyle.muted, height: 1.4, fontSize: 13)),
        const SizedBox(height: 12),
        Text(durationLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: FastFitStyle.deepRed)),
        const Spacer(),
        const SizedBox(height: 15),
        FastFitButton(
          label: 'View routine', fillWidth: true,
          icon: Icons.arrow_forward_rounded, outlined: true,
          onPressed: _saving ? null : () => _showRoutine(routine, weight),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FastFitStyle.surface,
      appBar: AppBar(
        title: const Text('Home workouts', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white, foregroundColor: FastFitStyle.ink,
        actions: [IconButton(
          tooltip: 'Workout History',
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FitnessHubScreen())),
          icon: const Icon(Icons.history_rounded),
        )],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _fitnessStream,
        builder: (context, snapshot) {
          final value = snapshot.data?.data()?['weightKg'];
          final weight = value is num && value > 0 ? value.toDouble() : null;
          final filtered = _routines.where((routine) {
            final matchesLevel = _levelFilter == 'All'
                || routine.level == _levelFilter;
            final matchesCategory = _categoryFilter == 'All'
                || routine.category == _categoryFilter
                || (_categoryFilter == 'Quick Sessions' && routine.minutes <= 15);
            return matchesLevel && matchesCategory;
          }).toList();
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [FastFitStyle.deepRed, FastFitStyle.red]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.home_rounded, color: Colors.white, size: 30),
                    SizedBox(height: 14),
                    Text('Move at home. Feel stronger.', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 25)),
                    SizedBox(height: 8),
                    Text('Short, equipment-free routines for your schedule. Take breaks and choose your own pace.',
                      style: TextStyle(color: Colors.white, height: 1.45)),
                  ]),
                ),
                const SizedBox(height: 23),
                const Text('Workout categories', style: TextStyle(fontSize: 22,
                  color: FastFitStyle.ink, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Choose the type of workout you enjoy.',
                  style: TextStyle(color: FastFitStyle.muted, fontSize: 13)),
                const SizedBox(height: 14),
                Wrap(spacing: 9, runSpacing: 9, children: [
                  for (final category in _categories)
                    ChoiceChip(
                      avatar: Icon(_categoryIcon(category), size: 18,
                        color: _categoryFilter == category
                          ? Colors.white : FastFitStyle.red),
                      label: Text(category),
                      selected: _categoryFilter == category,
                      selectedColor: FastFitStyle.red,
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: _categoryFilter == category
                          ? Colors.white : FastFitStyle.ink,
                        fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _categoryFilter = category),
                    ),
                ]),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(child: Text('Explore routines',
                    style: TextStyle(fontSize: 20,
                      color: FastFitStyle.ink, fontWeight: FontWeight.w900))),
                  Text('${filtered.length} available', style: const TextStyle(
                    color: FastFitStyle.muted, fontSize: 12)),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8,
                  children: ['All', 'Beginner', 'Intermediate'].map((value) {
                    final active = _levelFilter == value;
                    return ChoiceChip(
                      label: Text(value), selected: active,
                      selectedColor: FastFitStyle.red, backgroundColor: Colors.white,
                      showCheckmark: false,
                      labelStyle: TextStyle(color: active ? Colors.white : FastFitStyle.ink,
                        fontWeight: FontWeight.w700),
                      onSelected: (_) => setState(() => _levelFilter = value),
                    );
                  }).toList()),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center_outlined,
                          size: 38, color: FastFitStyle.red),
                        const SizedBox(height: 12),
                        const Text('No routines match these filters.',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                        TextButton(onPressed: () => setState(() {
                          _categoryFilter = 'All'; _levelFilter = 'All';
                        }), child: const Text('Clear filters')),
                      ]))),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 3 :
                    constraints.maxWidth >= 560 ? 2 : 1;
                  final width = (constraints.maxWidth - (columns - 1) * 15) / columns;
                  return Wrap(spacing: 15, runSpacing: 15, children: [
                    for (final routine in filtered)
                      SizedBox(width: width, height: 300,
                        child: _routineCard(routine, weight)),
                  ]);
                }),
                const SizedBox(height: 18),
                const Text('Energy estimates are approximate. Workout sessions are recorded only after you confirm completion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FastFitStyle.muted, fontSize: 11.5)),
              ]),
            )),
          );
        },
      ),
    );
  }
}
