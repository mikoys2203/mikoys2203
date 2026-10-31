import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/customer_service.dart';
import '../../services/fitness_service.dart';
import '../../services/meal_activity_planner.dart';
import '../../widgets/fastfit_motion.dart';
import 'exercise_screen.dart';

class FoodDetailsScreen extends StatefulWidget {
  final String foodId;
  final Map<String, dynamic> food;
  final String restaurantName;

  const FoodDetailsScreen({
    super.key,
    required this.foodId,
    required this.food,
    required this.restaurantName,
  });

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  final CustomerService _customer = CustomerService();
  final FitnessService _fitness = FitnessService();
  late final Future<String> _restaurantFuture;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _fitnessStream;
  int _quantity = 1;
  bool _savingMeal = false;
  bool _savingFavorite = false;

  static const Color _red = FastFitStyle.red;
  static const Color _ink = FastFitStyle.ink;
  static const Color _muted = FastFitStyle.muted;

  @override
  void initState() {
    super.initState();
    _restaurantFuture = _restaurantName();
    _fitnessStream = _fitness.fitnessProfile();
  }

  double _amount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double get _calories => _amount(widget.food['calories']);
  double get _protein => _amount(widget.food['protein']);
  double get _carbs => _amount(widget.food['carbohydrates']);
  double get _fats => _amount(widget.food['fats']);
  double get _mealCalories => _calories * _quantity;
  double get _mealProtein => _protein * _quantity;
  double get _mealCarbs => _carbs * _quantity;
  double get _mealFats => _fats * _quantity;
  String get _foodName => widget.food['name']?.toString() ?? 'Food item';

  Future<String> _restaurantName() async {
    if (widget.restaurantName.trim().isNotEmpty) {
      return widget.restaurantName.trim();
    }
    final id = widget.food['restaurantId']?.toString() ?? '';
    if (id.isEmpty) return 'Restaurant';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants').doc(id).get();
      return doc.data()?['name']?.toString() ?? 'Restaurant';
    } catch (_) {
      return 'Restaurant';
    }
  }

  void _notify(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFF8F2631) : _ink,
      ),
    );
  }

  Future<void> _saveMeal(String restaurant) async {
    if (_savingMeal) return;
    setState(() => _savingMeal = true);
    try {
      await _customer.logMeal(
        foodId: widget.foodId,
        foodName: _foodName,
        restaurantName: restaurant,
        calories: _calories,
        protein: _protein,
        carbohydrates: _carbs,
        fats: _fats,
        quantity: _quantity,
      );
      _notify('$_quantity serving${_quantity == 1 ? '' : 's'} saved. See Nutrition Insights for your updated totals.');
    } catch (_) {
      _notify('Your meal could not be saved. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _savingMeal = false);
    }
  }

  Widget _surface({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FastFitStyle.line),
        boxShadow: [BoxShadow(
          color: const Color(0xFF24121B).withValues(alpha: 0.035),
          blurRadius: 22,
          offset: const Offset(0, 7),
        )],
      ),
      child: child,
    );
  }

  Widget _foodPhoto(String url, {required bool mobile}) {
    return Container(
      height: mobile ? 240 : 380,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF2F1), Color(0xFFFFFAF7)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -85,
            right: -55,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (url.isEmpty)
            const Icon(Icons.restaurant_menu_rounded, color: _red, size: 96)
          else
            Padding(
              padding: const EdgeInsets.all(18),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                frameBuilder: (context, child, frame, sync) =>
                    sync ? child : AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 350),
                      child: child,
                    ),
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator(color: _red)),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.restaurant_menu_rounded, color: _red, size: 88),
              ),
            ),
          Positioned(
            top: 15,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10)],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_outlined, color: _red, size: 16),
                SizedBox(width: 6),
                Text('Food details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroBox({
    required String label,
    required String value,
    required IconData icon,
    required Color tint,
    required Color foreground,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: foreground.withValues(alpha: .13)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 21),
          const SizedBox(height: 12),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: foreground))),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: _ink)),
        ],
      ),
    );
  }

  Widget _nutritionFacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nutrition facts', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink)),
        const SizedBox(height: 3),
        const Text('Estimated values per serving', style: TextStyle(color: _muted, fontSize: 12.5)),
        const SizedBox(height: 15),
        LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth >= 580 ? 4 : 2;
          final cellWidth = (constraints.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(width: cellWidth, child: _macroBox(
              label: 'Calories', value: '${_calories.toStringAsFixed(0)} kcal',
              icon: Icons.local_fire_department_rounded,
              tint: const Color(0xFFFFECEC), foreground: _red)),
            SizedBox(width: cellWidth, child: _macroBox(
              label: 'Protein', value: '${_protein.toStringAsFixed(1)} g',
              icon: Icons.fitness_center_rounded,
              tint: const Color(0xFFEBF5FF), foreground: const Color(0xFF2476BE))),
            SizedBox(width: cellWidth, child: _macroBox(
              label: 'Carbs', value: '${_carbs.toStringAsFixed(1)} g',
              icon: Icons.grain_rounded,
              tint: const Color(0xFFFFF3E3), foreground: const Color(0xFFC87B16))),
            SizedBox(width: cellWidth, child: _macroBox(
              label: 'Fats', value: '${_fats.toStringAsFixed(1)} g',
              icon: Icons.water_drop_outlined,
              tint: const Color(0xFFECF7F1), foreground: const Color(0xFF228B60))),
          ]);
        }),
      ],
    );
  }

  Widget _foodHeader(String restaurant, String imageUrl, bool mobile) {
    final description = widget.food['description']?.toString().trim() ?? '';
    final serving = widget.food['servingSize']?.toString() ?? '1 serving';
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(restaurant.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.6,
            fontSize: 12, color: _red)),
        const SizedBox(height: 10),
        Text(_foodName,
          style: TextStyle(fontSize: mobile ? 26 : 32,
            height: 1.13, fontWeight: FontWeight.w900, color: _ink)),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 11),
          Text(description, style: const TextStyle(color: _muted, height: 1.5)),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: FastFitStyle.surface,
            border: Border.all(color: FastFitStyle.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.restaurant_outlined, color: _red, size: 17),
            const SizedBox(width: 7),
            Text('Serving size: $serving', style: const TextStyle(fontSize: 12.5)),
          ]),
        ),
        const SizedBox(height: 26),
        _nutritionFacts(),
      ],
    );

    if (mobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _foodPhoto(imageUrl, mobile: true),
        const SizedBox(height: 22),
        details,
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: _foodPhoto(imageUrl, mobile: false)),
      const SizedBox(width: 28),
      Expanded(flex: 6, child: Padding(
        padding: const EdgeInsets.only(top: 14), child: details)),
    ]);
  }

  Widget _quantityControls() {
    return Container(
      decoration: BoxDecoration(
        color: FastFitStyle.surface,
        border: Border.all(color: FastFitStyle.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'Remove one serving',
          onPressed: _savingMeal || _quantity <= 1 ? null : () => setState(() => _quantity--),
          icon: const Icon(Icons.remove_rounded, size: 20),
          color: _red,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text('$_quantity', key: ValueKey(_quantity),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        IconButton(
          tooltip: 'Add one serving',
          onPressed: _savingMeal || _quantity >= 5 ? null : () => setState(() => _quantity++),
          icon: const Icon(Icons.add_rounded, size: 20),
          color: _red,
        ),
      ]),
    );
  }

  Widget _mealCard(String restaurant) {
    return _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.edit_note_rounded, color: _red, size: 26),
          SizedBox(width: 9),
          Expanded(child: Text('Record your meal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink))),
        ]),
        const SizedBox(height: 6),
        const Text('Only save a meal when you have eaten it.',
          style: TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 22),
        Row(children: [
          const Expanded(child: Text('Number of servings',
            style: TextStyle(fontWeight: FontWeight.w600))),
          _quantityControls(),
        ]),
        const SizedBox(height: 16),
        Divider(color: FastFitStyle.line.withValues(alpha: .8)),
        const SizedBox(height: 10),
        Row(children: [
          const Text('Meal total', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text('${_mealCalories.toStringAsFixed(0)} kcal',
              key: ValueKey(_mealCalories),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _red)),
          ),
        ]),
        const SizedBox(height: 5),
        Text('${_mealProtein.toStringAsFixed(1)}g protein  •  '
             '${_mealCarbs.toStringAsFixed(1)}g carbs  •  '
             '${_mealFats.toStringAsFixed(1)}g fats',
          style: const TextStyle(fontSize: 12, color: _muted)),
        const SizedBox(height: 20),
        FastFitButton(
          label: 'Add to meal history', icon: Icons.add_rounded,
          loading: _savingMeal, fillWidth: true,
          onPressed: _savingMeal ? null : () => _saveMeal(restaurant),
        ),
        const SizedBox(height: 12),
        const Row(children: [
          Icon(Icons.insights_outlined, size: 16, color: _muted),
          SizedBox(width: 7),
          Expanded(child: Text('Your weekly Nutrition Insights update after saving.',
            style: TextStyle(color: _muted, fontSize: 12))),
        ]),
      ],
    ));
  }

  Widget _activityPreview({
    required double? weightKg,
    required String level,
    required String goal,
  }) {
    final picks = MealActivityPlanner.suggestions(
      calories: _mealCalories,
      protein: _mealProtein,
      carbohydrates: _mealCarbs,
      fats: _mealFats,
      fitnessLevel: level,
      goal: goal,
    );
    final description = MealActivityPlanner.mealDescription(
      calories: _mealCalories,
      protein: _mealProtein,
      carbohydrates: _mealCarbs,
      fats: _mealFats,
    );

    return _surface(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.directions_run_rounded, color: _red, size: 25),
          SizedBox(width: 9),
          Expanded(child: Text('Activities for this meal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _ink))),
        ]),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(color: _muted, fontSize: 13, height: 1.45)),
        const SizedBox(height: 15),
        for (final suggestion in picks.take(3)) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: FastFitStyle.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: FastFitStyle.line),
            ),
            child: Row(children: [
              Container(
                height: 39, width: 39,
                decoration: BoxDecoration(color: FastFitStyle.softRed,
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(suggestion.activity.icon, color: _red, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(suggestion.activity.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  Text(suggestion.tag,
                    style: const TextStyle(fontSize: 11.5, color: _muted)),
                ],
              )),
              if (weightKg != null && weightKg > 0)
                Text('~${FitnessService.calculateCalories(
                  met: suggestion.activity.met, weightKg: weightKg, minutes: 20,
                ).toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 11.5, color: _red)),
            ]),
          ),
        ],
        const SizedBox(height: 7),
        if (weightKg == null || weightKg <= 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Add your current weight in your fitness profile to see activity estimates.',
              style: TextStyle(color: _muted, fontSize: 12)),
          ),
        FastFitButton(
          label: 'Explore matching exercises',
          icon: Icons.arrow_forward_rounded,
          fillWidth: true,
          outlined: true,
          onPressed: weightKg == null || weightKg <= 0 ? null : () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(
              foodName: _foodName,
              mealCalories: _mealCalories,
              weightKg: weightKg,
              proteinGrams: _mealProtein,
              carbohydrateGrams: _mealCarbs,
              fatGrams: _mealFats,
              servings: _quantity,
            )));
          },
        ),
        const SizedBox(height: 12),
        const Text('Exercise is optional. You do not need to work off meals. Estimates vary by individual.',
          style: TextStyle(fontSize: 11.5, color: _muted, height: 1.4)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please sign in to view food details.')));
    }
    final imageUrl = widget.food['imageUrl']?.toString().trim() ?? '';
    return Scaffold(
      backgroundColor: FastFitStyle.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        scrolledUnderElevation: 0,
        title: const Text('Food details', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _customer.isFavorite(widget.foodId),
            builder: (context, snapshot) {
              final favorite = snapshot.data?.exists ?? false;
              return IconButton(
                tooltip: favorite ? 'Remove from favorites' : 'Save to favorites',
                icon: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: favorite ? _red : _ink),
                onPressed: !snapshot.hasData || _savingFavorite ? null : () async {
                  setState(() => _savingFavorite = true);
                  try {
                    await _customer.toggleFavorite(widget.foodId, favorite);
                    _notify(favorite ? 'Removed from favorites.' : 'Saved to favorites.');
                  } catch (_) {
                    _notify('Favorites could not be updated.', error: true);
                  } finally {
                    if (mounted) setState(() => _savingFavorite = false);
                  }
                },
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<String>(
        future: _restaurantFuture,
        builder: (context, restaurantSnapshot) {
          final restaurant = restaurantSnapshot.data ?? widget.restaurantName;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 780;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _foodHeader(restaurant.isEmpty ? 'Restaurant' : restaurant,
                      imageUrl, compact),
                    const SizedBox(height: 24),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _fitnessStream,
                      builder: (context, profileSnapshot) {
                        final settings = profileSnapshot.data?.data();
                        final savedWeight = _amount(settings?['weightKg']);
                        final weight = savedWeight > 0 ? savedWeight : null;
                        final level = settings?['fitnessLevel']?.toString() ?? 'beginner';
                        final goal = settings?['goal']?.toString() ?? '';
                        if (compact) {
                          return Column(children: [
                            _mealCard(restaurant),
                            const SizedBox(height: 16),
                            _activityPreview(weightKg: weight, level: level, goal: goal),
                          ]);
                        }
                        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(flex: 5, child: _mealCard(restaurant)),
                          const SizedBox(width: 18),
                          Expanded(flex: 6, child: _activityPreview(
                            weightKg: weight, level: level, goal: goal)),
                        ]);
                      },
                    ),
                    const SizedBox(height: 21),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: Text('Nutrition values depend on restaurant data and may change. Activity estimates are approximate.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: _muted)),
                    ),
                  ],
                );
              }),
            )),
          );
        },
      ),
    );
  }
}
