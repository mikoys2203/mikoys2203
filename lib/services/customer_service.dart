
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get userRef {
    return db.collection('users').doc(uid);
  }

  // USER PROFILE

  Stream<DocumentSnapshot<Map<String, dynamic>>> profile() {
    return userRef.snapshots();
  }

  Future<void> saveProfile({
    required String name,
    required String fitnessGoal,
    required double? weight,
  }) async {
    await userRef.update({
      'name': name.trim(),
      'fitnessGoal': fitnessGoal,
      'weight': weight,
    });
  }

  // FAVORITES

  CollectionReference<Map<String, dynamic>> get favoritesRef {
    return userRef.collection('favorites');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> favorites() {
    return favoritesRef.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> isFavorite(
    String foodId,
  ) {
    return favoritesRef.doc(foodId).snapshots();
  }

  Future<void> toggleFavorite(
    String foodId,
    bool currentlySaved,
  ) async {
    if (currentlySaved) {
      await favoritesRef.doc(foodId).delete();
    } else {
      await favoritesRef.doc(foodId).set({
        'foodId': foodId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // MEAL HISTORY

  CollectionReference<Map<String, dynamic>> get mealLogsRef {
    return userRef.collection('meal_logs');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> mealHistory() {
    return mealLogsRef
        .orderBy('loggedAt', descending: true)
        .snapshots();
  }

  Future<void> logMeal({
    required String foodId,
    required String foodName,
    required String restaurantName,
    required double calories,
    required int quantity,
  }) async {
    await mealLogsRef.add({
      'foodId': foodId,
      'foodName': foodName,
      'restaurantName': restaurantName,
      'calories': calories * quantity,
      'quantity': quantity,
      'loggedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMeal(String logId) async {
    await mealLogsRef.doc(logId).delete();
  }
}
