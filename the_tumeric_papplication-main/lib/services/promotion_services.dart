import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/promotion_model.dart';

class PromotionServices {
  final CollectionReference _promoCollection = 
      FirebaseFirestore.instance.collection("promotions");
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection("users");
  final CollectionReference _claimedOffersCollection = 
      FirebaseFirestore.instance.collection("claimed_offers");

  // Get all promotions
  Stream<List<PromotionModel>> getPromo() {
    return _promoCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((docs) => PromotionModel.fromJson(
                docs.data() as Map<String, dynamic>,
                docs.id,
              ))
          .toList(),
    );
  }

  // Get active promotions only
  Stream<List<PromotionModel>> getActivePromo() {
    return _promoCollection
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((docs) => PromotionModel.fromJson(
                    docs.data() as Map<String, dynamic>,
                    docs.id,
                  ))
              .toList(),
        );
  }

  // Get user's claimed offers
  Stream<List<ClaimedOffer>> getUserClaimedOffers(String userId) {
    return _claimedOffersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('claimedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClaimedOffer.fromJson(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList(),
        );
  }

  // Check if user has already claimed a specific offer
  Future<bool> hasUserClaimedOffer(String userId, String promoId) async {
    try {
      final querySnapshot = await _claimedOffersCollection
          .where('userId', isEqualTo: userId)
          .where('promoId', isEqualTo: promoId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking claimed offer: $e');
      return false;
    }
  }

  // Claim an offer
  Future<ClaimedOffer?> claimOffer(PromotionModel promotion) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already claimed
      bool alreadyClaimed = await hasUserClaimedOffer(user.uid, promotion.promoId);
      if (alreadyClaimed) {
        throw Exception('You have already claimed this offer');
      }

      // Check if offer is still available
      if (promotion.usageCount >= promotion.usageLimit) {
        throw Exception('This offer is no longer available');
      }

      if (promotion.status.toLowerCase() != 'active') {
        throw Exception('This offer is not active');
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

      // Use batch to ensure atomic operations
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add claimed offer
      batch.set(
        _claimedOffersCollection.doc(claimedOfferId),
        claimedOffer.toJson(),
      );

      // Update promotion usage count
      batch.update(
        _promoCollection.doc(promotion.promoId),
        {'usageCount': FieldValue.increment(1)},
      );

      // Update user's claimed offers list
      batch.update(
        _usersCollection.doc(user.uid),
        {
          'claimedOffers': FieldValue.arrayUnion([claimedOfferId]),
        },
      );

      await batch.commit();
      return claimedOffer;
    } catch (e) {
      print('Error claiming offer: $e');
      rethrow;
    }
  }

  // Use a claimed offer (mark as used)
  Future<void> useClaimedOffer(String claimedOfferId) async {
    try {
      await _claimedOffersCollection.doc(claimedOfferId).update({
        'isUsed': true,
        'usedAt': FieldValue.serverTimestamp(),
        'status': 'used',
      });
    } catch (e) {
      print('Error using claimed offer: $e');
      rethrow;
    }
  }

  // Calculate discount for a claimed offer
  double calculateDiscount(ClaimedOffer claimedOffer, double originalPrice) {
    if (claimedOffer.promoType.toLowerCase() == 'percentage') {
      return originalPrice * (claimedOffer.discountValue / 100);
    } else {
      // Fixed amount discount
      return claimedOffer.discountValue > originalPrice 
          ? originalPrice 
          : claimedOffer.discountValue;
    }
  }

  // Get best available offer for user
  Future<ClaimedOffer?> getBestAvailableOffer(String userId, double orderTotal) async {
    try {
      final claimedOffers = await _claimedOffersCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .where('isUsed', isEqualTo: false)
          .get();

      if (claimedOffers.docs.isEmpty) return null;

      ClaimedOffer? bestOffer;
      double maxDiscount = 0;

      for (var doc in claimedOffers.docs) {
        final offer = ClaimedOffer.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Check if offer is not expired
        if (offer.expiresAt.isBefore(DateTime.now())) continue;

        double discount = calculateDiscount(offer, orderTotal);
        if (discount > maxDiscount) {
          maxDiscount = discount;
          bestOffer = offer;
        }
      }

      return bestOffer;
    } catch (e) {
      print('Error getting best offer: $e');
      return null;
    }
  }

  // Remove expired offers
  Future<void> cleanupExpiredOffers() async {
    try {
      final expiredOffers = await _claimedOffersCollection
          .where('expiresAt', isLessThan: Timestamp.now())
          .where('status', isEqualTo: 'active')
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in expiredOffers.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }

      await batch.commit();
    } catch (e) {
      print('Error cleaning up expired offers: $e');
    }
  }
}