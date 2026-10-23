
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/fitness_service.dart';

class FitnessOnboardingScreen extends StatefulWidget {
  final Map<String, dynamic>? existingProfile;

  const FitnessOnboardingScreen({
    super.key,
    this.existingProfile,
  });

  @override
  State<FitnessOnboardingScreen> createState() =>
      _FitnessOnboardingScreenState();
}

class _FitnessOnboardingScreenState
    extends State<FitnessOnboardingScreen> {
  int currentStep = 0;
  bool saving = false;

  String goal = 'maintain weight';
  String gender = 'prefer not to say';
  String fitnessLevel = 'beginner';

  DateTime? birthDate;

  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final targetController = TextEditingController();

  final List<String> stepTitles = [
    'What is your fitness goal?',
    'What is your gender?',
    'When is your birthday?',
    'What is your height?',
    'What is your current weight?',
    'What is your target weight?',
  ];

  @override
  void initState() {
    super.initState();

    final data = widget.existingProfile;

    if (data != null) {
      goal = data['goal'] ?? 'maintain weight';
      gender = data['gender'] ?? 'prefer not to say';
      fitnessLevel = data['fitnessLevel'] ?? 'beginner';

      final date = data['birthDate'];
      if (date is Timestamp) {
        birthDate = date.toDate();
      }

      heightController.text =
          data['heightCm']?.toString() ?? '';

      weightController.text =
          data['weightKg']?.toString() ?? '';

      targetController.text =
          data['targetWeightKg']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    targetController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> chooseBirthDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2004, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );

    if (selected != null) {
      setState(() => birthDate = selected);
    }
  }

  Widget optionButtons({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: options.map((option) {
        return ChoiceChip(
          label: Text(option),
          selected: selected == option,
          selectedColor: Colors.red.shade100,
          checkmarkColor: Colors.red,
          onSelected: (_) => onSelected(option),
        );
      }).toList(),
    );
  }

  Widget numberInput({
    required TextEditingController controller,
    required String label,
    required String unit,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget buildStep() {
    switch (currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the goal that best describes '
              'what you want to achieve.',
            ),
            const SizedBox(height: 18),
            optionButtons(
              options: const [
                'lose weight',
                'maintain weight',
                'gain weight',
              ],
              selected: goal,
              onSelected: (value) {
                setState(() => goal = value);
              },
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an option. This information '
              'is private and will not be shared '
              'with restaurants.',
            ),
            const SizedBox(height: 18),
            optionButtons(
              options: const [
                'male',
                'female',
                'prefer not to say',
              ],
              selected: gender,
              onSelected: (value) {
                setState(() => gender = value);
              },
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your birthday helps us understand '
              'your age group.',
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: chooseBirthDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                birthDate == null
                    ? 'Select Birth Date'
                    : '${birthDate!.month}/'
                        '${birthDate!.day}/'
                        '${birthDate!.year}',
              ),
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current height.',
            ),
            const SizedBox(height: 18),
            numberInput(
              controller: heightController,
              label: 'Height',
              unit: 'cm',
            ),
          ],
        );

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current body weight. '
              'We use this to estimate energy expenditure.',
            ),
            const SizedBox(height: 18),
            numberInput(
              controller: weightController,
              label: 'Current Weight',
              unit: 'kg',
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your target weight, then choose '
              'your current exercise experience level.',
            ),
            const SizedBox(height: 18),

            numberInput(
              controller: targetController,
              label: 'Target Weight',
              unit: 'kg',
            ),

            const SizedBox(height: 25),

            const Text(
              'Fitness Experience',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            optionButtons(
              options: const [
                'beginner',
                'intermediate',
                'advanced',
              ],
              selected: fitnessLevel,
              onSelected: (value) {
                setState(() => fitnessLevel = value);
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'You can edit these details later. '
              'Activity suggestions are estimates, '
              'not a medical fitness assessment.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );
    }
  }

  bool validateStep() {
    if (currentStep == 2 && birthDate == null) {
      showMessage('Please select your birth date.');
      return false;
    }

    if (currentStep == 3) {
      final height =
          double.tryParse(heightController.text.trim());

      if (height == null ||
          !height.isFinite ||
          height < 90 ||
          height > 250) {
        showMessage('Enter a valid height (90–250 cm).');
        return false;
      }
    }

    if (currentStep == 4) {
      final weight =
          double.tryParse(weightController.text.trim());

      if (weight == null ||
          !weight.isFinite ||
          weight < 20 ||
          weight > 500) {
        showMessage('Enter a valid weight (20–500 kg).');
        return false;
      }
    }

    if (currentStep == 5) {
      final target =
          double.tryParse(targetController.text.trim());

      if (target == null ||
          !target.isFinite ||
          target < 20 ||
          target > 500) {
        showMessage('Enter a valid target weight.');
        return false;
      }
    }

    return true;
  }

  Future<void> nextStep() async {
    if (!validateStep() || saving) return;

    if (currentStep < 5) {
      setState(() => currentStep++);
      return;
    }

    setState(() => saving = true);

    try {
      await FitnessService().saveFitnessProfile(
        goal: goal,
        gender: gender,
        birthDate: birthDate!,
        heightCm:
            double.parse(heightController.text.trim()),
        weightKg:
            double.parse(weightController.text.trim()),
        targetWeightKg:
            double.parse(targetController.text.trim()),
        fitnessLevel: fitnessLevel,
      );

      if (!mounted) return;

      if (widget.existingProfile != null) {
        Navigator.pop(context);
      }
      // First-time users automatically continue
      // to the dashboard through AuthGate.
    } catch (e) {
      if (mounted) {
        showMessage('Unable to save fitness profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existingProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Edit Fitness Profile' : 'FastFit Setup',
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: editing,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Step ${currentStep + 1} of 6',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value: (currentStep + 1) / 6,
                      color: Colors.red,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(10),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      stepTitles[currentStep],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 22),

                    buildStep(),

                    const SizedBox(height: 40),

                    Row(
                      children: [
                        if (currentStep > 0)
                          OutlinedButton(
                            onPressed: saving
                                ? null
                                : () {
                                    setState(() {
                                      currentStep--;
                                    });
                                  },
                            child: const Text('Back'),
                          ),

                        const Spacer(),

                        ElevatedButton(
                          onPressed: saving ? null : nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              saving
                                  ? 'Saving...'
                                  : currentStep == 5
                                      ? 'Finish Setup'
                                      : 'Continue',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
