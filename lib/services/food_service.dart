
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // RESTAURANT PROFILE

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      getMyRestaurant() {
    return db.collection('restaurants').doc(uid).snapshots();
  }

  Future<void> saveRestaurant(
    String name,
    String logoUrl,
  ) async {
    final ref = db.collection('restaurants').doc(uid);
    final existing = await ref.get();

    if (existing.exists) {
      await ref.update({
        'name': name.trim(),
        'logoUrl': logoUrl.trim(),
      });
    } else {
      await ref.set({
        'name': name.trim(),
        'logoUrl': logoUrl.trim(),
        'ownerId': uid,
        'approvalStatus': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // FOOD MANAGEMENT

  Stream<QuerySnapshot<Map<String, dynamic>>> myFoods() {
    return db
        .collection('food_items')
        .where('restaurantId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> saveFood(
    Map<String, dynamic> food, {
    String? foodId,
  }) async {
    final collection = db.collection('food_items');

    if (foodId == null) {
      await collection.add({
        ...food,
        'restaurantId': uid,
        'approvalStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await collection.doc(foodId).update({
        ...food,
        'approvalStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteFood(String foodId) async {
    await db.collection('food_items').doc(foodId).delete();
  }

  // ADMIN FOOD APPROVAL

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingFoods() {
    return db
        .collection('food_items')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> reviewFood(
    String foodId,
    String status,
  ) async {
    if (status != 'approved' && status != 'rejected') {
      throw ArgumentError('Invalid status');
    }

    await db.collection('food_items').doc(foodId).update({
      'approvalStatus': status,
    });
  }

  // CUSTOMER CATALOG

  Stream<QuerySnapshot<Map<String, dynamic>>>
      approvedRestaurants() {
    return db
        .collection('restaurants')
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      approvedFoods() {
    return db
        .collection('food_items')
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots();
  }
}
