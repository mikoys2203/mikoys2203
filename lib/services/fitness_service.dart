
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Exercise information
class FitnessActivity {
  final String id;
  final String name;
  final String description;
  final double met;
  final IconData icon;
  final String minimumLevel;

  const FitnessActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.met,
    required this.icon,
    required this.minimumLevel,
  });
}

class FitnessService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get uid => auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get userRef {
    return db.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> get fitnessRef {
    return userRef.collection('fitness_settings').doc('profile');
  }

  CollectionReference<Map<String, dynamic>> get workoutRef {
    return userRef.collection('workout_logs');
  }

  // Available activities and approximate MET values.
  static const List<FitnessActivity> activities = [
    FitnessActivity(
      id: 'walk',
      name: 'Walking',
      description: 'Moderate walking at a comfortable pace',
      met: 3.5,
      icon: Icons.directions_walk,
      minimumLevel: 'beginner',
    ),
    FitnessActivity(
      id: 'cycle',
      name: 'Easy Cycling',
      description: 'Leisure cycling on level ground',
      met: 4.0,
      icon: Icons.directions_bike,
      minimumLevel: 'beginner',
    ),
    FitnessActivity(
      id: 'dance',
      name: 'Dancing',
      description: 'Recreational dancing',
      met: 4.5,
      icon: Icons.music_note,
      minimumLevel: 'beginner',
    ),
    FitnessActivity(
      id: 'bodyweight',
      name: 'Bodyweight Workout',
      description: 'Squats, modified push-ups and light exercises',
      met: 3.8,
      icon: Icons.fitness_center,
      minimumLevel: 'intermediate',
    ),
    FitnessActivity(
      id: 'stretch',
      name: 'Gentle Stretching',
      description: 'Easy mobility and relaxed stretching at home',
      met: 2.3,
      icon: Icons.self_improvement_rounded,
      minimumLevel: 'beginner',
    ),
    FitnessActivity(
      id: 'home_beginner',
      name: 'Beginner Home Workout',
      description: 'Easy squats, wall push-ups and guided movement',
      met: 3.0,
      icon: Icons.home_rounded,
      minimumLevel: 'beginner',
    ),
    FitnessActivity(
      id: 'yoga',
      name: 'Yoga & Mobility',
      description: 'Gentle yoga and mobility practice',
      met: 2.5,
      icon: Icons.spa_outlined,
      minimumLevel: 'beginner',
    ),
    FitnessActivity(
      id: 'core',
      name: 'Core Workout',
      description: 'Controlled planks, dead bugs and core stability',
      met: 3.5,
      icon: Icons.accessibility_new_rounded,
      minimumLevel: 'intermediate',
    ),
    FitnessActivity(
      id: 'home_strength',
      name: 'At-Home Strength',
      description: 'Full-body strength routine with no gym needed',
      met: 4.5,
      icon: Icons.fitness_center_rounded,
      minimumLevel: 'intermediate',
    ),
    FitnessActivity(
      id: 'jog',
      name: 'Jogging',
      description: 'Steady jogging at a comfortable pace',
      met: 7.0,
      icon: Icons.directions_run,
      minimumLevel: 'advanced',
    ),
  ];

  // Approximate calories expended.
  static double calculateCalories({
    required double met,
    required double weightKg,
    required int minutes,
  }) {
    if (met <= 0 || weightKg <= 0 || minutes <= 0) {
      return 0;
    }

    return (met * 3.5 * weightKg / 200) * minutes;
  }

  // Show activities suitable for the selected level.
  static List<FitnessActivity> recommendedActivities(
    String level,
  ) {
    if (level == 'beginner') {
      return activities.where((activity) {
        return activity.minimumLevel == 'beginner';
      }).toList();
    }

    if (level == 'intermediate') {
      return activities.where((activity) {
        return activity.minimumLevel != 'advanced';
      }).toList();
    }

    return activities;
  }

  // FITNESS PROFILE

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      fitnessProfile() {
    return fitnessRef.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      userProfile() {
    return userRef.snapshots();
  }

  Future<void> saveFitnessProfile({
    required String goal,
    required String gender,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String fitnessLevel,
  }) async {
    final previous = await fitnessRef.get();

    final oldCreatedAt = previous.data()?['createdAt'];

    final batch = db.batch();

    batch.set(fitnessRef, {
      'goal': goal,
      'gender': gender,
      'birthDate': Timestamp.fromDate(birthDate),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'fitnessLevel': fitnessLevel,
      'completed': true,
      'createdAt':
          oldCreatedAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Keep the existing customer profile synchronized.
    // Food Details uses users.weight for calorie estimates.
    batch.update(userRef, {
      'fitnessGoal': goal,
      'weight': weightKg,
    });

    await batch.commit();
  }

  // WORKOUT LOGGING

  Stream<QuerySnapshot<Map<String, dynamic>>> workouts() {
    return workoutRef
        .orderBy('completedAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> logWorkout({
    required FitnessActivity activity,
    required int minutes,
    required double weightKg,
    String? suggestedFromFood,
  }) async {
    if (minutes < 5 || minutes > 180 ||
        weightKg <= 0 || weightKg > 500) {
      throw ArgumentError('Invalid workout details');
    }

    final calories = calculateCalories(
      met: activity.met,
      weightKg: weightKg,
      minutes: minutes,
    );

    await workoutRef.add({
      'activityKey': activity.id,
      'activityName': activity.name,
      'minutes': minutes,
      'met': activity.met,
      'estimatedCalories': calories,
      if (suggestedFromFood != null && suggestedFromFood.trim().isNotEmpty)
        'suggestedFromFood': suggestedFromFood.trim(),
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteWorkout(String workoutId) async {
    await workoutRef.doc(workoutId).delete();
  }
}
