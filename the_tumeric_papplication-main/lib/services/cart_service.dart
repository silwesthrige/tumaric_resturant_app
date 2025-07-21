import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<DocumentSnapshot>> getCartFoodDetails(List<String> foodIds) async {
    if (foodIds.isEmpty) return [];

    List<DocumentSnapshot> allDocs = [];

    try {
      // Process in chunks of 10 (Firestore limit for whereIn)
      for (int i = 0; i < foodIds.length; i += 10) {
        final chunk = foodIds.sublist(
          i,
          i + 10 > foodIds.length ? foodIds.length : i + 10,
        );

        final querySnapshot = await _firestore
            .collection('menus')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        allDocs.addAll(querySnapshot.docs);
      }

      print("Successfully loaded ${allDocs.length} cart items from Firestore");
      return allDocs;
    } catch (e) {
      print("Error getting cart food details: $e");
      throw Exception("Failed to load cart items from database");
    }
  }

  /// Get cart food IDs from user document
  Future<List<String>> getCartFoodIds(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('cart')) {
          final cartList = List<String>.from(data['cart'] ?? []);
          print("Cart IDs for user $uid: $cartList");
          return cartList;
        } else {
          print("Cart field not found in user document");
          return [];
        }
      } else {
        print("User document does not exist for UID: $uid");
        // User document should be created by UserService during registration
        return [];
      }
    } catch (e) {
      print("Error getting cart food IDs: $e");
      throw Exception("Failed to load user cart data");
    }
  }

  /// Load complete cart items with food details
  Future<List<DocumentSnapshot>> loadCartItems(String uid) async {
    try {
      List<String> cartIds = await getCartFoodIds(uid);
      
      if (cartIds.isEmpty) {
        print("Cart is empty for user: $uid");
        return [];
      }
      
      return await getCartFoodDetails(cartIds);
    } catch (e) {
      print("Error loading cart items: $e");
      throw Exception("Failed to load cart items");
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(BuildContext context, String foodId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception("User not logged in");
      }

      final userRef = _firestore.collection('users').doc(uid);

      await userRef.update({
        "cart": FieldValue.arrayRemove([foodId]),
      });

      print("Successfully removed $foodId from cart");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Item removed from cart"),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Remove from cart error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to remove item from cart"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      rethrow;
    }
  }

  /// Add item to cart
  Future<void> addToCart(BuildContext context, String foodId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception("User not logged in");
      }

      final userRef = _firestore.collection('users').doc(uid);

      // Check if item already exists in cart
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final currentCart = List<String>.from(data?['cart'] ?? []);
        
        if (currentCart.contains(foodId)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Item already in cart"),
                backgroundColor: Colors.orange[400],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      await userRef.update({
        "cart": FieldValue.arrayUnion([foodId]),
      });

      print("Successfully added $foodId to cart");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Item added to cart"),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Add to cart error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add item to cart"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart(BuildContext context, String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);

      await userRef.update({
        "cart": [],
      });

      print("Successfully cleared cart for user: $uid");
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cart cleared successfully"),
            backgroundColor: Colors.orange[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("Clear cart error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to clear cart"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      rethrow;
    }
  }

  /// Get cart count for displaying in UI
  Future<int> getCartCount(String uid) async {
    try {
      List<String> cartIds = await getCartFoodIds(uid);
      return cartIds.length;
    } catch (e) {
      print("Error getting cart count: $e");
      return 0;
    }
  }

  /// Check if item is in cart
  Future<bool> isInCart(String uid, String foodId) async {
    try {
      List<String> cartIds = await getCartFoodIds(uid);
      return cartIds.contains(foodId);
    } catch (e) {
      print("Error checking if item is in cart: $e");
      return false;
    }
  }
}