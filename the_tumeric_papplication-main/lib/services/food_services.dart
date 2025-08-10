import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/food_detail_model.dart';

class FoodServices {
  final CollectionReference _FoodCollection = FirebaseFirestore.instance
      .collection("menus");

  //Get food details
  Stream<List<FoodDetailModel>> getFood() {
    return _FoodCollection.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map(
                (docs) => FoodDetailModel.fromJsonFood(
                  docs.data() as Map<String, dynamic>,
                  docs.id,
                ),
              )
              .toList(),
    );
  }

  Future<void> showUserId(BuildContext context, String Uid) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("UserID ${Uid}")));
  }

  Future<void> addToCart(
    BuildContext context,
    String foodId,
    String uid,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance.collection("users").doc(uid);

      await userRef.update({
        "cart": FieldValue.arrayUnion([foodId]),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Added to cart")));
    } catch (e) {
      print("Add to cart failed: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add to cart {$e}")));
    }
  }

  Future<void> removeFromCart(
    BuildContext context,
    String foodId,
    String uid,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance.collection("users").doc(uid);

      await userRef.update({
        "cart": FieldValue.arrayRemove([foodId]),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Removed from cart")));
    } catch (e) {
      print("Remove from cart failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove from cart {$e}")),
      );
    }
  }
}
