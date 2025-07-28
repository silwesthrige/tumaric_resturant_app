import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a rating and feedback for a menus item
  Future<void> submitRating({
    required String foodId,
    required double rating,
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to submit rating');
      }

      // Check if user has already rated this item
      final existingRating = await getUserRating(foodId);
      
      if (existingRating != null) {
        // Update existing rating instead of creating new one
        await updateRating(
          foodId: foodId,
          ratingId: existingRating['id'],
          rating: rating,
          feedback: feedback,
        );
        return;
      }

      // Create rating data
      final ratingData = {
        'userId': user.uid,
        'userEmail': user.email,
        'rating': rating,
        'feedback': feedback ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'userName': user.displayName ?? 'Anonymous',
      };

      // Add rating to the nested collection
      await _firestore
          .collection('menus')
          .doc(foodId)
          .collection('ratings')
          .add(ratingData);

      // Update the menus item's average rating
      await _updatemenusAverageRating(foodId);
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  // Get all ratings for a specific menus item
  Future<List<Map<String, dynamic>>> getRatingsFormenusItem(
    String foodId,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('menus')
              .doc(foodId)
              .collection('ratings')
              .orderBy('timestamp', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get ratings: $e');
    }
  }

  // Get rating statistics for a menus item
  Future<Map<String, dynamic>> getRatingStats(String foodId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('menus')
              .doc(foodId)
              .collection('ratings')
              .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'ratingBreakdown': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      double totalRating = 0;
      Map<int, int> ratingBreakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num).toInt();
        totalRating += rating;
        ratingBreakdown[rating] = (ratingBreakdown[rating] ?? 0) + 1;
      }

      final averageRating = totalRating / querySnapshot.docs.length;

      return {
        'averageRating': double.parse(averageRating.toStringAsFixed(1)),
        'totalRatings': querySnapshot.docs.length,
        'ratingBreakdown': ratingBreakdown,
      };
    } catch (e) {
      throw Exception('Failed to get rating stats: $e');
    }
  }

  // Check if current user has already rated this item
  Future<Map<String, dynamic>?> getUserRating(String foodId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final querySnapshot =
          await _firestore
              .collection('menus')
              .doc(foodId)
              .collection('ratings')
              .where('userId', isEqualTo: user.uid)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) return null;

      final data = querySnapshot.docs.first.data();
      data['id'] = querySnapshot.docs.first.id;
      return data;
    } catch (e) {
      throw Exception('Failed to get user rating: $e');
    }
  }

  // Update existing rating
  Future<void> updateRating({
    required String foodId,
    required String ratingId,
    required double rating,
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to update rating');
      }

      final updateData = {
        'rating': rating,
        'feedback': feedback ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('menus')
          .doc(foodId)
          .collection('ratings')
          .doc(ratingId)
          .update(updateData);

      // Update the menus item's average rating
      await _updatemenusAverageRating(foodId);
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  // Delete rating
  Future<void> deleteRating(String foodId, String ratingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to delete rating');
      }

      await _firestore
          .collection('menus')
          .doc(foodId)
          .collection('ratings')
          .doc(ratingId)
          .delete();

      // Update the menus item's average rating
      await _updatemenusAverageRating(foodId);
    } catch (e) {
      throw Exception('Failed to delete rating: $e');
    }
  }

  // Private method to update menus item's average rating
  Future<void> _updatemenusAverageRating(String foodId) async {
    try {
      final stats = await getRatingStats(foodId);

      await _firestore.collection('menus').doc(foodId).update({
        'averageRating': stats['averageRating'],
        'totalRatings': stats['totalRatings'],
        'lastRatingUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error here as it's a background update
      print('Failed to update menus average rating: $e');
    }
  }

  // Get recent ratings across all menus items (for admin dashboard)
  Future<List<Map<String, dynamic>>> getRecentRatings({int limit = 20}) async {
    try {
      // This requires a composite index in Firestore
      final querySnapshot =
          await _firestore
              .collectionGroup('ratings')
              .orderBy('timestamp', descending: true)
              .limit(limit)
              .get();

      List<Map<String, dynamic>> ratings = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data['foodId'] = doc.reference.parent.parent?.id;
        ratings.add(data);
      }

      return ratings;
    } catch (e) {
      throw Exception('Failed to get recent ratings: $e');
    }
  }

  // Get top rated menus items
  Future<List<Map<String, dynamic>>> getTopRatedmenusItems({
    int limit = 10,
  }) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('menus')
              .where('totalRatings', isGreaterThan: 0)
              .orderBy('averageRating', descending: true)
              .orderBy('totalRatings', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get top rated items: $e');
    }
  }

  // Stream ratings for real-time updates
  Stream<List<Map<String, dynamic>>> streamRatingsFormenusItem(String foodId) {
    return _firestore
        .collection('menus')
        .doc(foodId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Stream rating stats for real-time updates
  Stream<Map<String, dynamic>> streamRatingStats(String foodId) {
    return _firestore
        .collection('menus')
        .doc(foodId)
        .collection('ratings')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return {
              'averageRating': 0.0,
              'totalRatings': 0,
              'ratingBreakdown': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            };
          }

          double totalRating = 0;
          Map<int, int> ratingBreakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final rating = (data['rating'] as num).toInt();
            totalRating += rating;
            ratingBreakdown[rating] = (ratingBreakdown[rating] ?? 0) + 1;
          }

          final averageRating = totalRating / snapshot.docs.length;

          return {
            'averageRating': double.parse(averageRating.toStringAsFixed(1)),
            'totalRatings': snapshot.docs.length,
            'ratingBreakdown': ratingBreakdown,
          };
        });
  }

  // Get ratings with pagination for better performance
  Future<List<Map<String, dynamic>>> getRatingsWithPagination({
    required String foodId,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection('menus')
          .doc(foodId)
          .collection('ratings')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['documentSnapshot'] = doc; // For pagination
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get paginated ratings: $e');
    }
  }

  // Get summary statistics for multiple food items (useful for home page)
  Future<Map<String, Map<String, dynamic>>> getMultipleFoodRatings(
    List<String> foodIds,
  ) async {
    try {
      Map<String, Map<String, dynamic>> results = {};
      
      // Process in batches to avoid Firestore limitations
      const batchSize = 10;
      for (int i = 0; i < foodIds.length; i += batchSize) {
        final batch = foodIds.skip(i).take(batchSize).toList();
        
        final futures = batch.map((foodId) async {
          try {
            final stats = await getRatingStats(foodId);
            return MapEntry(foodId, stats);
          } catch (e) {
            // Return default stats if error
            return MapEntry(foodId, {
              'averageRating': 0.0,
              'totalRatings': 0,
              'ratingBreakdown': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            });
          }
        });
        
        final batchResults = await Future.wait(futures);
        for (final entry in batchResults) {
          results[entry.key] = entry.value;
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to get multiple food ratings: $e');
    }
  }

  // Check if user can rate (useful for UI logic)
  Future<bool> canUserRate(String foodId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // You can add additional logic here like:
      // - Check if user has ordered this item
      // - Check if enough time has passed since last rating
      // - Check if user has any restrictions
      
      return true; // For now, any logged-in user can rate
    } catch (e) {
      return false;
    }
  }

  // Get rating trends (useful for analytics)
  Future<Map<String, dynamic>> getRatingTrends(
    String foodId, {
    int days = 30,
  }) async {
    try {
      final DateTime startDate = DateTime.now().subtract(Duration(days: days));
      final Timestamp startTimestamp = Timestamp.fromDate(startDate);

      final querySnapshot = await _firestore
          .collection('menus')
          .doc(foodId)
          .collection('ratings')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .orderBy('timestamp', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalRatings': 0,
          'averageRating': 0.0,
          'trend': 'no_data',
          'dailyBreakdown': <String, int>{},
        };
      }

      // Calculate daily breakdown
      Map<String, List<double>> dailyRatings = {};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final rating = (data['rating'] as num).toDouble();
        
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          
          if (!dailyRatings.containsKey(dateKey)) {
            dailyRatings[dateKey] = [];
          }
          dailyRatings[dateKey]!.add(rating);
        }
      }

      // Calculate averages for each day
      Map<String, double> dailyAverages = {};
      for (var entry in dailyRatings.entries) {
        final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
        dailyAverages[entry.key] = double.parse(average.toStringAsFixed(1));
      }

      // Calculate overall trend
      final allRatings = querySnapshot.docs
          .map((doc) => (doc.data()['rating'] as num).toDouble())
          .toList();
      
      final overallAverage = allRatings.reduce((a, b) => a + b) / allRatings.length;

      // Simple trend calculation (compare first half vs second half)
      String trend = 'stable';
      if (allRatings.length >= 4) {
        final firstHalf = allRatings.sublist(allRatings.length ~/ 2);
        final secondHalf = allRatings.sublist(0, allRatings.length ~/ 2);
        
        final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
        
        if (firstAvg > secondAvg + 0.2) {
          trend = 'improving';
        } else if (firstAvg < secondAvg - 0.2) {
          trend = 'declining';
        }
      }

      return {
        'totalRatings': allRatings.length,
        'averageRating': double.parse(overallAverage.toStringAsFixed(1)),
        'trend': trend,
        'dailyAverages': dailyAverages,
      };
    } catch (e) {
      throw Exception('Failed to get rating trends: $e');
    }
  }
}