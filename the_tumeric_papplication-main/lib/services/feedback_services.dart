import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for better performance
  static const String _collectionName = 'feedbacks';
  static const Duration _timeout = Duration(seconds: 30);

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is authenticated
  bool get isAuthenticated => currentUserId != null;

  // Submit new feedback with improved validation
  Future<void> submitFeedback({
    required double rating,
    required String comment,
    List<String>? categories,
    bool isAnonymous = false,
  }) async {
    // Validate authentication
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    // Validate input
    _validateFeedbackInput(rating, comment);

    try {
      final feedbackData = {
        'userId': currentUserId,
        'rating': rating,
        'comment': comment.trim(),
        'categories': categories ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isAnonymous': isAnonymous,
        'version': 1, // For future schema migrations
      };

      await _firestore
          .collection(_collectionName)
          .add(feedbackData)
          .timeout(_timeout);

      debugPrint('Feedback submitted successfully');
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please check your connection and try again.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error submitting feedback: ${e.code} - ${e.message}',
      );
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Unexpected error submitting feedback: $e');
      throw Exception('Failed to submit feedback. Please try again.');
    }
  }

  // Get user's feedbacks with improved error handling and caching
  Future<List<Map<String, dynamic>>> getUserFeedbacks({int limit = 50}) async {
    try {
      if (!isAuthenticated) {
        return [];
      }

      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get()
          .timeout(_timeout);

      final feedbacks = _processSnapshots(snapshot);
      debugPrint('Retrieved ${feedbacks.length} user feedbacks');
      return feedbacks;
    } on TimeoutException {
      debugPrint('Timeout getting user feedbacks');
      return [];
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error getting user feedbacks: ${e.code} - ${e.message}',
      );

      // Handle specific Firebase errors
      if (e.code == 'permission-denied') {
        return [];
      } else if (e.code == 'failed-precondition' &&
          e.message?.contains('index') == true) {
        // Try fallback query without orderBy
        return _getFeedbacksFallback(userId: currentUserId, limit: limit);
      }
      return [];
    } catch (e) {
      debugPrint('Unexpected error getting user feedbacks: $e');
      return [];
    }
  }

  // Get all restaurant feedbacks with fallback strategies
  Future<List<Map<String, dynamic>>> getRestaurantFeedbacks({
    int limit = 100,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get()
          .timeout(_timeout);

      final feedbacks = _processSnapshots(snapshot);
      debugPrint('Retrieved ${feedbacks.length} restaurant feedbacks');
      return feedbacks;
    } on TimeoutException {
      debugPrint('Timeout getting restaurant feedbacks');
      return [];
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error getting restaurant feedbacks: ${e.code} - ${e.message}',
      );

      if (e.code == 'failed-precondition' &&
          e.message?.contains('index') == true) {
        return _getFeedbacksFallback(limit: limit);
      }
      return [];
    } catch (e) {
      debugPrint('Unexpected error getting restaurant feedbacks: $e');
      return [];
    }
  }

  // Fallback method when composite indexes are not available
  Future<List<Map<String, dynamic>>> _getFeedbacksFallback({
    String? userId,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName).limit(limit);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final QuerySnapshot snapshot = await query.get().timeout(_timeout);
      final feedbacks = _processSnapshots(snapshot);

      // Sort manually by createdAt
      feedbacks.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      debugPrint('Fallback query returned ${feedbacks.length} feedbacks');
      return feedbacks;
    } catch (e) {
      debugPrint('Fallback query failed: $e');
      return [];
    }
  }

  // Helper method to process QuerySnapshot consistently
  List<Map<String, dynamic>> _processSnapshots(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'rating': _extractDouble(data['rating']),
          'comment': data['comment']?.toString() ?? '',
          'categories': _extractStringList(data['categories']),
          'createdAt': data['createdAt'] ?? Timestamp.now(),
          'updatedAt': data['updatedAt'] ?? Timestamp.now(),
          'isAnonymous': data['isAnonymous'] == true,
          'version': data['version'] ?? 1,
        };
      } catch (e) {
        debugPrint('Error processing document ${doc.id}: $e');
        // Return a basic structure if processing fails
        return {
          'id': doc.id,
          'userId': '',
          'rating': 0.0,
          'comment': '',
          'categories': <String>[],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'isAnonymous': false,
          'version': 1,
        };
      }
    }).toList();
  }

  // Safe extraction methods
  double _extractDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  List<String> _extractStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  // Update feedback with enhanced validation
  Future<void> updateFeedback({
    required String feedbackId,
    required double rating,
    required String comment,
    List<String>? categories,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    // Validate input
    _validateFeedbackInput(rating, comment);
    _validateFeedbackId(feedbackId);

    try {
      // Verify ownership first
      final doc = await _firestore
          .collection(_collectionName)
          .doc(feedbackId)
          .get()
          .timeout(_timeout);

      if (!doc.exists) {
        throw Exception('Feedback not found');
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['userId'] != currentUserId) {
        throw Exception('You can only update your own feedback');
      }

      // Update the feedback
      await _firestore
          .collection(_collectionName)
          .doc(feedbackId)
          .update({
            'rating': rating,
            'comment': comment.trim(),
            'categories': categories ?? [],
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_timeout);

      debugPrint('Feedback updated successfully');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error updating feedback: ${e.code} - ${e.message}');
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('not found') ||
          e.toString().contains('only update your own')) {
        rethrow;
      }
      debugPrint('Unexpected error updating feedback: $e');
      throw Exception('Failed to update feedback. Please try again.');
    }
  }

  // Delete feedback with enhanced validation
  Future<void> deleteFeedback(String feedbackId) async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    _validateFeedbackId(feedbackId);

    try {
      // Verify ownership first
      final doc = await _firestore
          .collection(_collectionName)
          .doc(feedbackId)
          .get()
          .timeout(_timeout);

      if (!doc.exists) {
        throw Exception('Feedback not found');
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['userId'] != currentUserId) {
        throw Exception('You can only delete your own feedback');
      }

      await _firestore
          .collection(_collectionName)
          .doc(feedbackId)
          .delete()
          .timeout(_timeout);

      debugPrint('Feedback deleted successfully');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error deleting feedback: ${e.code} - ${e.message}');
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('not found') ||
          e.toString().contains('only delete your own')) {
        rethrow;
      }
      debugPrint('Unexpected error deleting feedback: $e');
      throw Exception('Failed to delete feedback. Please try again.');
    }
  }

  // Get average rating with better error handling
  Future<double> getAverageRating() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get()
          .timeout(_timeout);

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalRating = 0.0;
      int validRatings = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final rating = _extractDouble(data['rating']);

        if (rating > 0) {
          totalRating += rating;
          validRatings++;
        }
      }

      final average = validRatings > 0 ? totalRating / validRatings : 0.0;
      debugPrint(
        'Calculated average rating: $average from $validRatings ratings',
      );
      return average;
    } catch (e) {
      debugPrint('Error getting average rating: $e');
      return 0.0;
    }
  }

  // Get rating distribution with better error handling
  Future<Map<int, int>> getRatingDistribution() async {
    final Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get()
          .timeout(_timeout);

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final rating = _extractDouble(data['rating']);

        if (rating > 0) {
          final roundedRating = rating.round().clamp(1, 5);
          distribution[roundedRating] = (distribution[roundedRating] ?? 0) + 1;
        }
      }

      debugPrint('Rating distribution: $distribution');
    } catch (e) {
      debugPrint('Error getting rating distribution: $e');
    }

    return distribution;
  }

  // Stream feedbacks for real-time updates with error handling
  Stream<List<Map<String, dynamic>>> getFeedbacksStream({int limit = 50}) {
    try {
      return _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => _processSnapshots(snapshot))
          .handleError((error) {
            debugPrint('Feedbacks stream error: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('Error creating feedbacks stream: $e');
      return Stream.value([]);
    }
  }

  // Get user feedbacks stream
  Stream<List<Map<String, dynamic>>> getUserFeedbacksStream({int limit = 50}) {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => _processSnapshots(snapshot))
          .handleError((error) {
            debugPrint('User feedbacks stream error: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('Error creating user feedbacks stream: $e');
      return Stream.value([]);
    }
  }

  // Check if user can modify feedback
  Future<bool> canUserModifyFeedback(String feedbackId) async {
    if (!isAuthenticated) return false;

    try {
      _validateFeedbackId(feedbackId);

      final doc = await _firestore
          .collection(_collectionName)
          .doc(feedbackId)
          .get()
          .timeout(_timeout);

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      return data['userId'] == currentUserId;
    } catch (e) {
      debugPrint('Error checking modify permissions: $e');
      return false;
    }
  }

  // Test connection to Firestore
  Future<bool> testConnection() async {
    try {
      await _firestore
          .collection(_collectionName)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      debugPrint('Firestore connection test successful');
      return true;
    } catch (e) {
      debugPrint('Firestore connection test failed: $e');
      return false;
    }
  }

  // Input validation methods
  void _validateFeedbackInput(double rating, String comment) {
    if (rating < 1.0 || rating > 5.0) {
      throw Exception('Rating must be between 1.0 and 5.0');
    }

    if (comment.trim().length > 500) {
      throw Exception('Comment must be 500 characters or less');
    }
  }

  void _validateFeedbackId(String feedbackId) {
    if (feedbackId.isEmpty) {
      throw Exception('Invalid feedback ID');
    }
  }

  // Firebase error message helper
  String _getFirebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Access denied. Please check your permissions.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'not-found':
        return 'Requested data not found.';
      case 'already-exists':
        return 'Data already exists.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed. Please try again.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid data range.';
      case 'unimplemented':
        return 'Operation not supported.';
      case 'internal':
        return 'Internal server error. Please try again.';
      case 'data-loss':
        return 'Data corruption detected. Please try again.';
      case 'unauthenticated':
        return 'Authentication required. Please log in.';
      default:
        return 'An error occurred: ${e.message ?? 'Unknown error'}';
    }
  }
}
