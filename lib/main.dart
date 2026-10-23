import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/nutrition_review_screen.dart';
import 'screens/restaurant/restaurant_dashboard.dart';
import 'screens/restaurant/nutrition_evidence_screen.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/user/fitness_onboarding_screen.dart';
import 'screens/user/fitness_hub_screen.dart';
import 'screens/user/nutrition_insights_screen.dart';
import 'screens/user/food_compare_screen.dart';
import 'screens/user/meal_builder_screen.dart';
import 'screens/user/nutrition_transparency_screen.dart';
import 'screens/user/smart_recommendation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FastFitApp());
}

class FastFitApp extends StatelessWidget {
  const FastFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return const AccountIssueScreen(message: 'Authentication error.');
        }
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        final user = authSnapshot.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const AccountIssueScreen(
                message: 'Unable to load account profile. Check Firestore Rules.',
              );
            }
            if (!snapshot.hasData) return const LoadingScreen();
            final profile = snapshot.data!.data();
            if (profile == null) {
              return const AccountIssueScreen(
                message: 'Account profile not found.',
              );
            }
            final role = profile['role']?.toString() ?? '';
            final name = profile['name']?.toString() ?? 'User';
            final status = profile['approvalStatus']?.toString() ?? '';
            if (role == 'admin') {
              return RolePortal(
                title: 'Nutrition Review',
                icon: Icons.fact_check,
                page: const NutritionReviewScreen(),
                child: AdminDashboard(name: name),
              );
            }
            if (role == 'restaurant') {
              final restaurantDashboard = RestaurantDashboard(
                name: name,
                approvalStatus: status,
              );
              if (status != 'approved') return restaurantDashboard;
              return RolePortal(
                title: 'Nutrition Sources',
                icon: Icons.description,
                page: const NutritionEvidenceScreen(),
                child: restaurantDashboard,
              );
            }
            if (role == 'user') {
              return CustomerFitnessGate(name: name, userId: user.uid);
            }
            return const AccountIssueScreen(message: 'Invalid account role.');
          },
        );
      },
    );
  }
}

class RolePortal extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget page;

  const RolePortal({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 18,
          bottom: 18,
          child: SafeArea(
            child: FloatingActionButton.extended(
              heroTag: 'fastfit_role_portal',
              icon: Icon(icon),
              label: Text(title),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => page),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomerFitnessGate extends StatelessWidget {
  final String name;
  final String userId;

  const CustomerFitnessGate({
    super.key,
    required this.name,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fitness_settings')
          .doc('profile')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const AccountIssueScreen(
            message: 'Unable to load fitness information.',
          );
        }
        if (!snapshot.hasData) return const LoadingScreen();
        if (snapshot.data!.data()?['completed'] != true) {
          return const FitnessOnboardingScreen();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 800;
            return Stack(
              children: [
                UserDashboard(name: name),
                Positioned(
                  right: 16,
                  bottom: mobile ? 95 : 18,
                  child: const FastFitToolsButton(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class FastFitToolsButton extends StatelessWidget {
  const FastFitToolsButton({super.key});

  void openPage(
    BuildContext parentContext,
    BuildContext sheetContext,
    Widget page,
  ) {
    final navigator = Navigator.of(parentContext);
    Navigator.pop(sheetContext);
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _option(
    BuildContext parentContext,
    BuildContext sheetContext,
    IconData icon,
    String name,
    String details,
    Widget destination,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(name),
      subtitle: Text(details),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openPage(parentContext, sheetContext, destination),
    );
  }

  void showTools(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const Text(
                'FastFit Tools',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 9),
              _option(
                context, sheetContext, Icons.auto_awesome,
                'Smart Food + Exercise',
                'Food picks, activity suggestions, 7-day plan and today’s logs',
                const SmartRecommendationScreen(),
              ),
              const Divider(),
              _option(
                context, sheetContext, Icons.insights,
                'Nutrition Insights', 'Logged meal trends',
                const NutritionInsightsScreen(),
              ),
              _option(
                context, sheetContext, Icons.compare_arrows,
                'Food Comparison', 'Compare two approved menu items',
                const FoodCompareScreen(),
              ),
              _option(
                context, sheetContext, Icons.restaurant_menu,
                'Meal Builder', 'Make a combination and log your meal',
                const MealBuilderScreen(),
              ),
              _option(
                context, sheetContext, Icons.fitness_center,
                'Fitness Hub', 'Workout history and progress',
                const FitnessHubScreen(),
              ),
              _option(
                context, sheetContext, Icons.fact_check,
                'Nutrition Sources', 'Check nutrition evidence',
                const NutritionTransparencyScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'fastfit_tools_v19',
      icon: const Icon(Icons.apps),
      label: const Text('FastFit Tools'),
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
      onPressed: () => showTools(context),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.red)),
    );
  }
}

class AccountIssueScreen extends StatelessWidget {
  final String message;

  const AccountIssueScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
