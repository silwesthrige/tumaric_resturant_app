import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/promotion_model.dart';

class PromotionServices {
  final CollectionReference _promoCollection = FirebaseFirestore.instance
      .collection("promotions");
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection("users");
  final CollectionReference _claimedOffersCollection = FirebaseFirestore
      .instance
      .collection("claimed_offers");

  // Get all promotions
  Stream<List<PromotionModel>> getPromo() {
    try {
      return _promoCollection
          .orderBy('startDate', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map(
                      (docs) => PromotionModel.fromJson(
                        docs.data() as Map<String, dynamic>,
                        docs.id,
                      ),
                    )
                    .toList(),
          );
    } catch (e) {
      print('Error in getPromo: $e');
      return Stream.value([]);
    }
  }

  // EMERGENCY SIMPLE VERSION - Just get all promotions
  Stream<List<PromotionModel>> getActivePromo() {
    try {
      return _promoCollection
          .limit(5) // Limit to 5 for testing
          .snapshots()
          .map((snapshot) {
            print('Raw Firestore docs: ${snapshot.docs.length}');
            final promotions = <PromotionModel>[];

            for (var doc in snapshot.docs) {
              try {
                print('Processing doc: ${doc.id}');
                final data = doc.data() as Map<String, dynamic>;
                print('Doc data keys: ${data.keys.toList()}');

                final promotion = PromotionModel.fromJson(data, doc.id);
                promotions.add(promotion);
                print('Successfully added promotion: ${promotion.title}');
              } catch (e) {
                print('Failed to parse doc ${doc.id}: $e');
              }
            }

            return promotions;
          });
    } catch (e) {
      print('Critical error in getActivePromo: $e');
      return Stream.value([]);
    }
  }

  // Alternative method if you want to keep Firestore filtering
  Stream<List<PromotionModel>> getActivePromoWithFirestoreFilter() {
    try {
      return _promoCollection
          .where('status', isEqualTo: 'active')
          .where('startDate', isLessThanOrEqualTo: Timestamp.now())
          .snapshots()
          .map((snapshot) {
            final now = DateTime.now();
            return snapshot.docs
                .map((docs) {
                  try {
                    return PromotionModel.fromJson(
                      docs.data() as Map<String, dynamic>,
                      docs.id,
                    );
                  } catch (e) {
                    print('Error parsing promotion ${docs.id}: $e');
                    return null;
                  }
                })
                .whereType<PromotionModel>()
                .where((promo) {
                  // Additional filter for end date in Dart
                  return promo.endDate == null || promo.endDate!.isAfter(now);
                })
                .toList();
          });
    } catch (e) {
      print('Error in getActivePromoWithFirestoreFilter: $e');
      return Stream.value([]);
    }
  }

  // Get user's claimed offers
  Stream<List<ClaimedOffer>> getUserClaimedOffers(String userId) {
    try {
      return _claimedOffersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('claimedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) {
                      try {
                        return ClaimedOffer.fromJson(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                      } catch (e) {
                        print('Error parsing claimed offer ${doc.id}: $e');
                        return null;
                      }
                    })
                    .whereType<ClaimedOffer>()
                    .toList(),
          );
    } catch (e) {
      print('Error in getUserClaimedOffers: $e');
      return Stream.value([]);
    }
  }

  // Check if user has already claimed a specific offer
  Future<bool> hasUserClaimedOffer(String userId, String promoId) async {
    try {
      final querySnapshot =
          await _claimedOffersCollection
              .where('userId', isEqualTo: userId)
              .where('promoId', isEqualTo: promoId)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking claimed offer: $e');
      return false;
    }
  }

  // Get specific promotion by ID
  Future<PromotionModel?> getPromotionById(String promoId) async {
    try {
      final doc = await _promoCollection.doc(promoId).get();
      if (doc.exists) {
        return PromotionModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting promotion: $e');
      return null;
    }
  }

  // Claim an offer with enhanced validation
  Future<ClaimedOffer?> claimOffer(PromotionModel promotion) async {
    try {
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please login to claim offers');
      }

      print(
        'Attempting to claim offer: ${promotion.promoId} for user: ${user.uid}',
      );

      // Check if user already claimed this offer (strict check)
      bool alreadyClaimed = await hasUserClaimedOffer(
        user.uid,
        promotion.promoId,
      );
      if (alreadyClaimed) {
        throw Exception('You have already claimed this offer');
      }

      // Get fresh promotion data to ensure accuracy
      final freshPromotion = await getPromotionById(promotion.promoId);
      if (freshPromotion == null) {
        throw Exception('Offer not found');
      }

      // Validate promotion status
      if (freshPromotion.status.toLowerCase() != 'active') {
        throw Exception('This offer is no longer active');
      }

      // Check if promotion has started
      if (!freshPromotion.hasStarted) {
        throw Exception('This offer hasn\'t started yet');
      }

      // Check if promotion has expired
      if (freshPromotion.isExpired) {
        throw Exception('This offer has expired');
      }

      // Check usage limit
      if (freshPromotion.usageCount >= freshPromotion.usageLimit) {
        throw Exception('This offer has reached its usage limit');
      }

      print('All validations passed, starting transaction...');

      // Run transaction to ensure atomicity
      return await FirebaseFirestore.instance.runTransaction<ClaimedOffer?>((
        transaction,
      ) async {
        print('Inside transaction...');

        // Double-check if user already claimed within transaction
        final existingClaimsQuery =
            await _claimedOffersCollection
                .where('userId', isEqualTo: user.uid)
                .where('promoId', isEqualTo: promotion.promoId)
                .limit(1)
                .get();

        if (existingClaimsQuery.docs.isNotEmpty) {
          throw Exception('You have already claimed this offer');
        }

        // Get fresh promotion data within transaction
        final promoRef = _promoCollection.doc(promotion.promoId);
        final promoSnapshot = await transaction.get(promoRef);

        if (!promoSnapshot.exists) {
          throw Exception('Offer no longer exists');
        }

        final currentPromo = PromotionModel.fromJson(
          promoSnapshot.data() as Map<String, dynamic>,
          promoSnapshot.id,
        );

        print(
          'Current promo usage: ${currentPromo.usageCount}/${currentPromo.usageLimit}',
        );

        // Double-check availability within transaction
        if (currentPromo.usageCount >= currentPromo.usageLimit) {
          throw Exception('Offer is fully claimed');
        }

        if (currentPromo.status.toLowerCase() != 'active') {
          throw Exception('Offer is no longer active');
        }

        // Create claimed offer
        final claimedOfferId = _claimedOffersCollection.doc().id;
        final claimedOffer = ClaimedOffer(
          id: claimedOfferId,
          userId: user.uid,
          promoId: promotion.promoId,
          promoType: promotion.promoType,
          discountValue: promotion.precentage,
          status: 'active',
          claimedAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: 30)), // 30 days validity
          isUsed: false,
        );

        print('Creating claimed offer with ID: $claimedOfferId');

        // Add claimed offer
        transaction.set(
          _claimedOffersCollection.doc(claimedOfferId),
          claimedOffer.toJson(),
        );

        // Update promotion usage count
        transaction.update(promoRef, {
          'usageCount': FieldValue.increment(1),
          'lastClaimedAt': FieldValue.serverTimestamp(),
        });

        // Update user's claimed offers list (optional, for quick reference)
        final userRef = _usersCollection.doc(user.uid);
        transaction.set(userRef, {
          'claimedOffers': FieldValue.arrayUnion([claimedOfferId]),
          'lastOfferClaimedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('Transaction completed successfully');
        return claimedOffer;
      });
    } catch (e) {
      print('Error claiming offer: $e');
      rethrow;
    }
  }

  // Rest of the methods remain the same but with added error handling...

  // Use a claimed offer (mark as used)
  Future<void> useClaimedOffer(String claimedOfferId, String orderId) async {
    try {
      // Validate the claimed offer exists and is active
      final claimedOfferDoc =
          await _claimedOffersCollection.doc(claimedOfferId).get();
      if (!claimedOfferDoc.exists) {
        throw Exception('Claimed offer not found');
      }

      final claimedOffer = ClaimedOffer.fromJson(
        claimedOfferDoc.data() as Map<String, dynamic>,
        claimedOfferDoc.id,
      );

      if (claimedOffer.isUsed) {
        throw Exception('This offer has already been used');
      }

      if (claimedOffer.isExpired) {
        throw Exception('This offer has expired');
      }

      if (claimedOffer.status != 'active') {
        throw Exception('This offer is not active');
      }

      // Update the claimed offer
      await _claimedOffersCollection.doc(claimedOfferId).update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
        'status': 'used',
        'orderId': orderId,
      });
    } catch (e) {
      print('Error using claimed offer: $e');
      rethrow;
    }
  }

  // Calculate discount for a claimed offer
  double calculateDiscount(ClaimedOffer claimedOffer, double originalPrice) {
    try {
      if (claimedOffer.promoType.toLowerCase() == 'percentage') {
        return originalPrice * (claimedOffer.discountValue / 100);
      } else {
        // Fixed amount discount
        return claimedOffer.discountValue > originalPrice
            ? originalPrice
            : claimedOffer.discountValue;
      }
    } catch (e) {
      print('Error calculating discount: $e');
      return 0.0;
    }
  }

  // Simple method to test connection
  Future<bool> testConnection() async {
    try {
      await _promoCollection.limit(1).get();
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Get promotions with simpler query for testing
  Stream<List<PromotionModel>> getSimpleActivePromo() {
    try {
      return _promoCollection
          .limit(10) // Limit results for testing
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((docs) {
                      try {
                        final data = docs.data() as Map<String, dynamic>;
                        return PromotionModel.fromJson(data, docs.id);
                      } catch (e) {
                        print('Error parsing doc ${docs.id}: $e');
                        return null;
                      }
                    })
                    .whereType<PromotionModel>()
                    .where((promo) => promo.status.toLowerCase() == 'active')
                    .toList(),
          );
    } catch (e) {
      print('Error in getSimpleActivePromo: $e');
      return Stream.value([]);
    }
  }
}
