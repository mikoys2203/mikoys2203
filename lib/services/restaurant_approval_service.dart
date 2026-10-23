
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantApprovalService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // Get registered restaurant accounts
  Stream<QuerySnapshot<Map<String, dynamic>>>
      getRestaurants() {
    return firestore
        .collection('users')
        .where('role', isEqualTo: 'restaurant')
        .snapshots();
  }

  // Approve or reject a restaurant account
  Future<void> updateStatus(
    String userId,
    String status,
  ) async {
    if (status != 'approved' && status != 'rejected') {
      throw ArgumentError('Invalid approval status');
    }

    await firestore.collection('users').doc(userId).update({
      'approvalStatus': status,
    });
  }
}
