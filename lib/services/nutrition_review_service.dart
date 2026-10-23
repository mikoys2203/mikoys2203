
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionReviewService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  String get uid => auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get sources {
    return db.collection('food_sources');
  }

  // Restaurant's food items
  Stream<QuerySnapshot<Map<String, dynamic>>> myFoods() {
    return db
        .collection('food_items')
        .where('restaurantId', isEqualTo: uid)
        .snapshots();
  }

  // Restaurant's submitted sources
  Stream<QuerySnapshot<Map<String, dynamic>>> mySources() {
    return sources
        .where('restaurantId', isEqualTo: uid)
        .snapshots();
  }

  // Admin source monitoring
  Stream<QuerySnapshot<Map<String, dynamic>>> allSources() {
    return sources.snapshots();
  }

  // Single food's nutrition source
  Stream<DocumentSnapshot<Map<String, dynamic>>> sourceForFood(
    String foodId,
  ) {
    return sources.doc(foodId).snapshots();
  }

  // Historical reviews
  Stream<QuerySnapshot<Map<String, dynamic>>> reviewHistory(
    String foodId,
  ) {
    return sources
        .doc(foodId)
        .collection('reviews')
        .orderBy('reviewedAt', descending: true)
        .snapshots();
  }

  bool isValidUrl(String text) {
    final uri = Uri.tryParse(text.trim());

    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty;
  }

  // Restaurant submits or resubmits evidence
  Future<void> submitSource({
    required String foodId,
    required String sourceType,
    required String sourceUrl,
    required String sourceNote,
  }) async {
    final url = sourceUrl.trim();

    if (!isValidUrl(url)) {
      throw Exception('Enter a valid HTTPS source URL.');
    }

    if (!['official', 'packaging', 'other']
        .contains(sourceType)) {
      throw Exception('Invalid source type.');
    }

    if (url.length > 1000 || sourceNote.length > 600) {
      throw Exception('Source information is too long.');
    }

    final foodDocument = await db
        .collection('food_items')
        .doc(foodId)
        .get();

    if (!foodDocument.exists) {
      throw Exception('Food item does not exist.');
    }

    final food = foodDocument.data()!;

    if (food['restaurantId'] != uid) {
      throw Exception('You do not own this food item.');
    }

    final foodUpdatedAt = food['updatedAt'];

    if (foodUpdatedAt is! Timestamp) {
      throw Exception(
        'Food item needs a valid updatedAt timestamp.',
      );
    }

    await sources.doc(foodId).set({
      'foodId': foodId,
      'restaurantId': uid,
      'sourceType': sourceType,
      'sourceUrl': url,
      'sourceNote': sourceNote.trim(),
      'foodUpdatedAt': foodUpdatedAt,
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewStatus': 'pending',
      'reviewedBy': null,
      'reviewedAt': null,
      'reviewNote': '',
      'lastReviewId': null,
    }, SetOptions(merge: true));
  }

  // Admin review: atomic update + audit record
  Future<void> reviewSource({
    required String foodId,
    required String decision,
    required String note,
  }) async {
    if (!['approved', 'rejected'].contains(decision)) {
      throw Exception('Invalid review decision.');
    }

    if (note.trim().isEmpty || note.trim().length > 500) {
      throw Exception(
        'Please provide a review note (1-500 characters).',
      );
    }

    final sourceRef = sources.doc(foodId);
    final sourceSnapshot = await sourceRef.get();

    if (!sourceSnapshot.exists) {
      throw Exception('Source submission does not exist.');
    }

    final sourceData = sourceSnapshot.data()!;

    if (sourceData['reviewStatus'] != 'pending') {
      throw Exception('This submission is no longer pending.');
    }

    final foodSnapshot = await db
        .collection('food_items')
        .doc(foodId)
        .get();

    if (!foodSnapshot.exists) {
      throw Exception('Food item no longer exists.');
    }

    final foodUpdatedAt =
        foodSnapshot.data()?['updatedAt'];

    final sourceUpdatedAt =
        sourceData['foodUpdatedAt'];

    if (foodUpdatedAt is! Timestamp ||
        sourceUpdatedAt is! Timestamp ||
        foodUpdatedAt.seconds != sourceUpdatedAt.seconds ||
        foodUpdatedAt.nanoseconds !=
            sourceUpdatedAt.nanoseconds) {
      throw Exception(
        'Food information has changed. '
        'The restaurant must resubmit its source.',
      );
    }

    final reviewRef = sourceRef.collection('reviews').doc();
    final batch = db.batch();

    batch.update(sourceRef, {
      'reviewStatus': decision,
      'reviewNote': note.trim(),
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'lastReviewId': reviewRef.id,
    });

    batch.set(reviewRef, {
      'foodId': foodId,
      'decision': decision,
      'note': note.trim(),
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'sourceUrlSnapshot': sourceData['sourceUrl'],
      'foodUpdatedAt': sourceUpdatedAt,
    });

    await batch.commit();
  }

  // Check whether a review matches current food data
  static bool isCurrentReviewedSource(
    Map<String, dynamic> food,
    Map<String, dynamic>? source,
  ) {
    if (source == null ||
        source['reviewStatus'] != 'approved' ||
        food['approvalStatus'] != 'approved') {
      return false;
    }

    final foodDate = food['updatedAt'];
    final sourceDate = source['foodUpdatedAt'];

    if (foodDate is! Timestamp ||
        sourceDate is! Timestamp) {
      return false;
    }

    return foodDate.seconds == sourceDate.seconds &&
        foodDate.nanoseconds == sourceDate.nanoseconds;
  }
}
