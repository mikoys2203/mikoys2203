import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/fitness_service.dart';
import '../../widgets/fastfit_motion.dart';

/// The profile fields and Firestore write path are unchanged from V29.
class FitnessOnboardingScreen extends StatefulWidget {
  final Map<String, dynamic>? existingProfile;
  const FitnessOnboardingScreen({super.key, this.existingProfile});

  @override
  State<FitnessOnboardingScreen> createState() => _FitnessOnboardingScreenState();
}

class _FitnessOnboardingScreenState extends State<FitnessOnboardingScreen> {
  static const titles = [
    'What is your goal?',
    'Choose your gender',
    'When were you born?',
    'How tall are you?',
    'What is your current weight?',
    'What is your target weight?',
  ];
  static const labels = [
    'Goal', 'Gender', 'Birth date', 'Height', 'Current weight', 'Weight goal',
  ];
  static const subtitles = [
    'Your goal helps us tailor food picks and activity suggestions.',
    'Choose the option you feel comfortable sharing.',
    'Your birth date helps us tailor age-aware suggestions.',
    'Enter your height in centimeters.',
    'Enter your current body weight in kilograms.',
    'Pick a goal that feels right for you. You can change it later.',
  ];

  final height = TextEditingController();
  final weight = TextEditingController();
  final target = TextEditingController();
  int step = 0;
  bool saving = false;
  String? goal;
  String? gender;
  String fitnessLevel = 'beginner';
  DateTime? birthDate;

  @override
  void initState() {
    super.initState();
    final data = widget.existingProfile;
    if (data != null) {
      goal = data['goal']?.toString();
      gender = data['gender']?.toString();
      fitnessLevel = data['fitnessLevel']?.toString() ?? fitnessLevel;
      final date = data['birthDate'];
      if (date is Timestamp) birthDate = date.toDate();
      height.text = data['heightCm']?.toString() ?? '';
      weight.text = data['weightKg']?.toString() ?? '';
      target.text = data['targetWeightKg']?.toString() ?? '';
    }
    for (final controller in [height, weight, target]) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    height.removeListener(_refresh);
    weight.removeListener(_refresh);
    target.removeListener(_refresh);
    height.dispose();
    weight.dispose();
    target.dispose();
    super.dispose();
  }

  void notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4)));
  }

  Future<void> selectDate() async {
    if (saving) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2004, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendar,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: FastFitStyle.red)),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => birthDate = picked);
  }

  bool numberValid(TextEditingController controller, double lower, double upper) {
    final v = double.tryParse(controller.text.trim());
    return v != null && v.isFinite && v >= lower && v <= upper;
  }

  bool get validNow {
    switch (step) {
      case 0: return goal != null;
      case 1: return gender != null;
      case 2: return birthDate != null;
      case 3: return numberValid(height, 90, 250);
      case 4: return numberValid(weight, 20, 500);
      default: return numberValid(target, 20, 500);
    }
  }

  String get invalidHint {
    switch (step) {
      case 0: return 'Choose a fitness goal to continue.';
      case 1: return 'Choose a gender option to continue.';
      case 2: return 'Select your birth date to continue.';
      case 3: return 'Enter a height between 90 and 250 cm.';
      case 4: return 'Enter a weight between 20 and 500 kg.';
      default: return 'Enter a target weight between 20 and 500 kg.';
    }
  }

  Future<void> next() async {
    if (saving) return;
    if (!validNow) { notice(invalidHint); return; }
    if (step < 5) {
      FocusScope.of(context).unfocus();
      setState(() => step++);
      return;
    }
    setState(() => saving = true);
    try {
      await FitnessService().saveFitnessProfile(
        goal: goal!,
        gender: gender!,
        birthDate: birthDate!,
        heightCm: double.parse(height.text.trim()),
        weightKg: double.parse(weight.text.trim()),
        targetWeightKg: double.parse(target.text.trim()),
        fitnessLevel: fitnessLevel,
      );
      if (!mounted) return;
      if (widget.existingProfile != null) Navigator.of(context).pop();
      // The existing AuthGate takes new users to the dashboard automatically.
    } catch (error) {
      notice(AuthErrorMessages.from(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _choices(List<_Choice> choices, String? selected, ValueChanged<String> change) {
    return LayoutBuilder(builder: (context, c) {
      // Consistent vertical selection rows are easier to scan and tap.
      const gap = 12.0;
      final width = c.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: 12,
        children: [
          for (final option in choices)
            SizedBox(
              width: width,
              child: FastFitChoiceCard(
                key: ValueKey(option.value),
                label: option.label,
                subtitle: option.subtitle,
                icon: option.icon,
                selected: selected == option.value,
                onTap: saving ? null : () {
                  HapticFeedback.selectionClick();
                  setState(() => change(option.value));
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _numberInput(TextEditingController controller, String label, String unit,
    String example, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        decoration: BoxDecoration(
          color: FastFitStyle.surface,
          border: Border.all(color: FastFitStyle.line),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(children: [
          Container(
            height: 58, width: 58, alignment: Alignment.center,
            decoration: BoxDecoration(color: FastFitStyle.softRed,
              borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: FastFitStyle.red, size: 29),
          ),
          const SizedBox(width: 16),
          Expanded(child: TextField(
            controller: controller,
            enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: FastFitStyle.field(label, icon,
              hint: example, suffix: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(widthFactor: 1, child: Text(unit,
                  style: const TextStyle(color: FastFitStyle.muted,
                    fontWeight: FontWeight.w800))),
              )),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      Text('You can update this later in your profile.',
        style: TextStyle(color: FastFitStyle.muted.withValues(alpha: 0.9), fontSize: 13)),
    ]);
  }

  Widget stepContents() {
    switch (step) {
      case 0:
        return _choices(const [
          _Choice('lose weight', 'Lose weight', Icons.trending_down_rounded,
            'Find meals and movement that support your goal'),
          _Choice('gain weight', 'Gain weight', Icons.fitness_center_rounded,
            'Discover energy-rich and protein-rich choices'),
          _Choice('maintain weight', 'Maintain weight', Icons.balance_rounded,
            'Build a balanced daily routine'),
        ], goal, (value) => goal = value);
      case 1:
        return _choices(const [
          _Choice('male', 'Male', Icons.male_rounded, null),
          _Choice('female', 'Female', Icons.female_rounded, null),
          _Choice('other', 'Other', Icons.diversity_3_rounded, null),
          _Choice('prefer not to say', 'Prefer not to say', Icons.shield_outlined, null),
        ], gender, (value) => gender = value);
      case 2:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(color: birthDate == null ? Colors.white : FastFitStyle.softRed,
            border: Border.all(color: birthDate == null ? FastFitStyle.line : FastFitStyle.red,
              width: birthDate == null ? 1 : 1.7),
            borderRadius: BorderRadius.circular(17)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: selectDate,
              borderRadius: BorderRadius.circular(17),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 24),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, color: FastFitStyle.red, size: 31),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Your birth date', style: TextStyle(
                      fontSize: 12, color: FastFitStyle.muted)),
                    const SizedBox(height: 4),
                    Text(birthDate == null ? 'Choose a date' :
                      '${birthDate!.day.toString().padLeft(2, '0')} / '
                      '${birthDate!.month.toString().padLeft(2, '0')} / ${birthDate!.year}',
                      style: const TextStyle(color: FastFitStyle.ink,
                        fontSize: 18, fontWeight: FontWeight.w800)),
                  ])),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: FastFitStyle.muted),
                ]),
              ),
            ),
          ),
        );
      case 3:
        return _numberInput(height, 'Height', 'cm', 'Example: 170', Icons.height_rounded);
      case 4:
        return _numberInput(weight, 'Current weight', 'kg', 'Example: 65', Icons.monitor_weight_outlined);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _numberInput(target, 'Target weight', 'kg', 'Example: 60', Icons.flag_outlined),
          const SizedBox(height: 28),
          const Text('Your activity experience', style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800, color: FastFitStyle.ink)),
          const SizedBox(height: 6),
          const Text('Choose the level that feels comfortable for you.',
            style: TextStyle(color: FastFitStyle.muted, fontSize: 13)),
          const SizedBox(height: 14),
          _choices(const [
            _Choice('beginner', 'Beginner', Icons.directions_walk_rounded, null),
            _Choice('intermediate', 'Intermediate', Icons.directions_run_rounded, null),
            _Choice('advanced', 'Advanced', Icons.fitness_center_rounded, null),
          ], fitnessLevel, (value) => fitnessLevel = value),
          const SizedBox(height: 12),
          const Text('Workout and calorie suggestions are general estimates, not medical advice.',
            style: TextStyle(color: FastFitStyle.muted, fontSize: 12)),
        ]);
    }
  }

  Widget _stepBubble(int index) {
    final done = index < step;
    final current = index == step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      height: 32, width: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? const Color(0xFF199C71) :
          current ? FastFitStyle.red : const Color(0xFFF0EFF0),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: done ? Icon(Icons.check_rounded, key: ValueKey('done$index'),
            color: Colors.white, size: 19)
          : Text('${index + 1}', key: ValueKey('num$index'),
              style: TextStyle(fontWeight: FontWeight.w800,
                color: current ? Colors.white : FastFitStyle.muted)),
      ),
    );
  }

  Widget _stepper() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: FastFitStyle.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('YOUR JOURNEY', style: TextStyle(
          fontSize: 12, color: FastFitStyle.red,
          fontWeight: FontWeight.w900, letterSpacing: 1.25)),
        const SizedBox(height: 11),
        const Text('A healthier routine\nstarts here.', style: TextStyle(
          fontSize: 19, color: FastFitStyle.ink,
          fontWeight: FontWeight.w900, height: 1.3)),
        const SizedBox(height: 29),
        for (int index = 0; index < labels.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
              decoration: BoxDecoration(
                color: index == step ? FastFitStyle.softRed : Colors.transparent,
                borderRadius: BorderRadius.circular(13)),
              child: Row(children: [
                _stepBubble(index),
                const SizedBox(width: 11),
                Expanded(child: Text(labels[index],
                  style: TextStyle(fontWeight: index == step ? FontWeight.w800 : FontWeight.w600,
                    color: index == step ? FastFitStyle.red : FastFitStyle.ink,
                    fontSize: 13))),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        const Text('Your choices stay part of your FastFit profile, and you can update them later.',
          style: TextStyle(fontSize: 12, height: 1.55, color: FastFitStyle.muted)),
      ]),
    );
  }

  Widget _compactProgress() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('YOUR FITNESS PROFILE', style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w800,
          color: FastFitStyle.red, letterSpacing: 1)),
        Text('${step + 1} of 6', style: const TextStyle(
          color: FastFitStyle.muted, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 13),
      ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 330),
          tween: Tween<double>(begin: 0, end: (step + 1) / 6),
          builder: (_, value, __) => LinearProgressIndicator(value: value,
            minHeight: 7, color: FastFitStyle.red,
            backgroundColor: FastFitStyle.softRed),
        ),
      ),
    ]);
  }

  Widget _mainCard(bool desktop) {
    return Container(
      padding: EdgeInsets.all(desktop ? 36 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FastFitStyle.line),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 22, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!desktop) _compactProgress() else Row(children: [
          const Icon(Icons.tune_rounded, color: FastFitStyle.red, size: 20),
          const SizedBox(width: 8),
          const Text('PERSONALIZE YOUR EXPERIENCE', style: TextStyle(
            color: FastFitStyle.red, fontWeight: FontWeight.w900,
            fontSize: 12, letterSpacing: 1)),
          const Spacer(),
          Text('Step ${step + 1} / 6', style: const TextStyle(color: FastFitStyle.muted)),
        ]),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          reverseDuration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.09, 0.025), end: Offset.zero,
            ).animate(animation);
            return FadeTransition(opacity: animation,
              child: SlideTransition(position: offset, child: child));
          },
          child: Column(
            key: ValueKey('step-$step'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titles[step], style: TextStyle(
                color: FastFitStyle.ink,
                fontSize: desktop ? 30 : 25,
                letterSpacing: -0.8,
                fontWeight: FontWeight.w900,
              )),
              const SizedBox(height: 9),
              Text(subtitles[step], style: const TextStyle(
                color: FastFitStyle.muted, fontSize: 14, height: 1.5)),
              const SizedBox(height: 28),
              stepContents(),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(children: [
          if (step > 0) FastFitButton(
            outlined: true, label: 'Back', icon: Icons.arrow_back_rounded,
            onPressed: saving ? null : () {
              FocusScope.of(context).unfocus();
              setState(() => step--);
            },
          ) else const SizedBox.shrink(),
          const Spacer(),
          Flexible(child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 148, maxWidth: 230),
            child: FastFitButton(
              label: step == 5 ? 'Finish setup' : 'Continue',
              icon: step == 5 ? Icons.check_rounded : Icons.arrow_forward_rounded,
              loading: saving,
              onPressed: saving || !validNow ? null : next,
              fillWidth: true,
            ),
          )),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existingProfile != null;
    return Scaffold(
      backgroundColor: FastFitStyle.surface,
      appBar: AppBar(
        title: Text(editing ? 'Edit fitness profile' : 'Welcome to FastFit',
          style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: FastFitStyle.ink,
        automaticallyImplyLeading: editing,
        elevation: 0,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 870;
        return Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 500 ? 14 : 24,
              vertical: 25,
            ),
            child: desktop
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 276, child: _stepper()),
                    const SizedBox(width: 23),
                    Expanded(child: _mainCard(true)),
                  ])
                : _mainCard(false),
          ),
        ));
      }),
    );
  }
}

class _Choice {
  final String value;
  final String label;
  final IconData icon;
  final String? subtitle;
  const _Choice(this.value, this.label, this.icon, this.subtitle);
}
