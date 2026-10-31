import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'widgets/fastfit_motion.dart';

import 'firebase_options.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/restaurant/restaurant_dashboard.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/user/fitness_onboarding_screen.dart';
import 'screens/user/fitness_hub_screen.dart';
import 'screens/user/home_workouts_screen.dart';
import 'screens/user/nutrition_insights_screen.dart';
import 'screens/user/food_compare_screen.dart';
import 'screens/user/meal_builder_screen.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: FastFitStyle.red),
        scaffoldBackgroundColor: FastFitStyle.surface,
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: FastFitStyle.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(90, 44))),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: FastFitStyle.red,
          foregroundColor: Colors.white),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: FastFitStyle.ink,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12))),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: FastFitStyle.ink,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: FastFitStyle.line),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: FastFitStyle.softRed,
          backgroundColor: Colors.white,
        ),
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
          return const AccountIssueScreen(message: 'Unable to check your sign-in status. Please check your connection.');
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
                message: 'We couldn\'t load your profile right now. Please try again later or contact FastFit support.',
              );
            }
            if (!snapshot.hasData) return const LoadingScreen();
            final profile = snapshot.data!.data();
            if (profile == null) {
              return const CompleteProfileScreen();
            }
            final role = profile['role']?.toString() ?? '';
            final name = profile['name']?.toString() ?? 'User';
            final status = profile['approvalStatus']?.toString() ?? '';
            if (role == 'admin') {
              return AdminDashboard(name: name);
            }
            if (role == 'restaurant') {
              final restaurantDashboard = RestaurantDashboard(
                name: name,
                approvalStatus: status,
              );
              return restaurantDashboard;
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

/// Adaptive tools launcher: an appropriately sized dialog on desktop
/// and a content-sized bottom sheet on phones. No oversized empty panel.
class FastFitToolsButton extends StatelessWidget {
  const FastFitToolsButton({super.key});

  void _openPage(BuildContext parent, BuildContext overlay, Widget page) {
    final navigator = Navigator.of(parent);
    Navigator.of(overlay).pop();
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _tool(BuildContext parent, BuildContext overlay,
      IconData icon, String title, String subtitle, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _openPage(parent, overlay, page),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: FastFitStyle.line),
              borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Container(height: 45, width: 45,
                decoration: BoxDecoration(
                  color: FastFitStyle.softRed,
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: FastFitStyle.red, size: 23)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(
                  color: FastFitStyle.ink, fontSize: 14.5,
                  fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(
                  fontSize: 12.1, height: 1.4,
                  color: FastFitStyle.muted)),
              ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                color: FastFitStyle.muted, size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sheet(BuildContext parent, BuildContext overlay,
      {required bool desktop}) {
    return SafeArea(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 575),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!desktop) Center(child: Container(
            height: 4, width: 38,
            decoration: BoxDecoration(color: const Color(0xFFD8CECB),
              borderRadius: BorderRadius.circular(8)))),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FastFit Tools', style: TextStyle(
                color: FastFitStyle.ink, fontWeight: FontWeight.w900,
                fontSize: 25, letterSpacing: -.6)),
              SizedBox(height: 5),
              Text('Everything you need for better food and fitness choices.',
                style: TextStyle(color: FastFitStyle.muted,
                  fontSize: 12.5, height: 1.4)),
            ])),
            IconButton(tooltip: 'Close tools',
              onPressed: () => Navigator.of(overlay).pop(),
              icon: const Icon(Icons.close_rounded)),
          ]),
          const SizedBox(height: 19),
          _tool(parent, overlay, Icons.auto_awesome_outlined,
            'Smart Food + Exercise',
            'Food picks, activity suggestions and your 7-day plan',
            const SmartRecommendationScreen()),
          _tool(parent, overlay, Icons.query_stats_outlined,
            'Nutrition Insights',
            'See trends in your logged meals',
            const NutritionInsightsScreen()),
          _tool(parent, overlay, Icons.compare_arrows_rounded,
            'Food Comparison',
            'Compare nutrition across approved menu items',
            const FoodCompareScreen()),
          _tool(parent, overlay, Icons.lunch_dining_outlined,
            'Meal Builder',
            'Build a food combination and log your meal',
            const MealBuilderScreen()),
          _tool(parent, overlay, Icons.fitness_center_outlined,
            'Fitness Hub',
            'Workout history, activity and progress',
            const FitnessHubScreen()),
          _tool(parent, overlay, Icons.home_outlined,
            'Home Workouts',
            'Short routines you can do without a gym',
            const HomeWorkoutsScreen()),
        ]),
      ),
    ));
  }

  void showTools(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 730;
    if (desktop) {
      showDialog<void>(
        context: context,
        builder: (overlay) => Dialog(
          backgroundColor: FastFitStyle.surface,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23)),
          child: _sheet(context, overlay, desktop: true)),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: FastFitStyle.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (overlay) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(overlay).height * .85),
          child: _sheet(context, overlay, desktop: false)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    heroTag: 'fastfit_tools_v31',
    tooltip: 'Open FastFit tools',
    icon: const Icon(Icons.apps_rounded, size: 21),
    label: const Text('Tools', style: TextStyle(fontWeight: FontWeight.w800)),
    backgroundColor: FastFitStyle.red,
    foregroundColor: Colors.white,
    onPressed: () => showTools(context),
  );
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
