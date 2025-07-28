import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Submit new feedback
  Future<void> submitFeedback({
    required double rating,
    required String comment,
    List<String>? categories, // e.g., ['Food Quality', 'Service', 'Delivery']
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('feedbacks').add({
        'userId': currentUserId,
        'rating': rating,
        'comment': comment,
        'categories': categories ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isAnonymous': false,
      });
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // Get user's feedbacks
  Future<List<Map<String, dynamic>>> getUserFeedbacks() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('feedbacks')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'createdAt': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get feedbacks: $e');
    }
  }

  // Get all restaurant feedbacks (for restaurant owners)
  Future<List<Map<String, dynamic>>> getRestaurantFeedbacks() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('feedbacks')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'createdAt': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get restaurant feedbacks: $e');
    }
  }

  // Get feedbacks by rating
  Future<List<Map<String, dynamic>>> getFeedbacksByRating(double minRating) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('feedbacks')
          .where('rating', isGreaterThanOrEqualTo: minRating)
          .orderBy('rating', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'createdAt': data['createdAt'] ?? Timestamp.now(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get feedbacks by rating: $e');
    }
  }

  // Update feedback
  Future<void> updateFeedback({
    required String feedbackId,
    required double rating,
    required String comment,
    List<String>? categories,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('feedbacks').doc(feedbackId).update({
        'rating': rating,
        'comment': comment,
        'categories': categories ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update feedback: $e');
    }
  }

  // Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection('feedbacks').doc(feedbackId).delete();
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }

  // Get average rating
  Future<double> getAverageRating() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('feedbacks')
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] ?? 0.0).toDouble();
      }

      return totalRating / snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get average rating: $e');
    }
  }

  // Get rating distribution
  Future<Map<int, int>> getRatingDistribution() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('feedbacks')
          .get();

      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] ?? 0.0).toDouble().round();
        if (rating >= 1 && rating <= 5) {
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      throw Exception('Failed to get rating distribution: $e');
    }
  }
}