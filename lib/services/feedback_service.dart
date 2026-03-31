import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'feedback';

  static const String statusPending = 'pending';
  static const String statusNoted = 'noted';

  Future<void> submitFeedback({
    required String email,
    required String text,
  }) async {
    await _firestore.collection(_collectionName).add({
      'email': email,
      'text': text,
      'status': statusPending,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getPendingFeedback() {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: statusPending)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getNotedFeedback() {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: statusNoted)
        .orderBy('notedAt', descending: true)
        .snapshots();
  }

  Future<void> markAsNoted(String feedbackId) async {
    await _firestore.collection(_collectionName).doc(feedbackId).update({
      'status': statusNoted,
      'notedAt': FieldValue.serverTimestamp(),
    });
  }
}
