import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<DocumentSnapshot>> getCartFoodDetails(
    List<String> foodIds,
  ) async {
    if (foodIds.isEmpty) return [];

    List<DocumentSnapshot> allDocs = [];

    try {
      // Process in chunks of 10 (Firestore limit for whereIn)
      for (int i = 0; i < foodIds.length; i += 10) {
        final chunk = foodIds.sublist(
          i,
          i + 10 > foodIds.length ? foodIds.length : i + 10,
        );

        final querySnapshot =
            await _firestore
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

  // Add this method to your CartService class
  Future<List<DocumentSnapshot>> loadCartItemsByIds(
    List<String> foodIds,
  ) async {
    try {
      if (foodIds.isEmpty) return [];

      // Firestore 'whereIn' has a limit of 10 items, so we need to batch if more
      List<DocumentSnapshot> allDocs = [];

      // Split into batches of 10
      for (int i = 0; i < foodIds.length; i += 10) {
        int end = (i + 10 < foodIds.length) ? i + 10 : foodIds.length;
        List<String> batch = foodIds.sublist(i, end);

        QuerySnapshot querySnapshot =
            await FirebaseFirestore.instance
                .collection(
                  'foods',
                ) // Make sure this matches your actual collection name
                .where(FieldPath.documentId, whereIn: batch)
                .get();

        allDocs.addAll(querySnapshot.docs);
      }

      return allDocs;
    } catch (e) {
      print("Error loading cart items by IDs: $e");
      throw e;
    }
  }

  // Alternative method if you prefer individual document fetches
  Future<List<DocumentSnapshot>> loadCartItemsByIdsAlternative(
    List<String> foodIds,
  ) async {
    try {
      if (foodIds.isEmpty) return [];

      List<DocumentSnapshot> docs = [];

      for (String foodId in foodIds) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance
                .collection(
                  'foods',
                ) // Make sure this matches your actual collection name
                .doc(foodId)
                .get();

        if (doc.exists) {
          docs.add(doc);
        }
      }

      return docs;
    } catch (e) {
      print("Error loading cart items by IDs (alternative): $e");
      throw e;
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

      // Get current cart data
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception("User document not found");
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> currentCart = userData['cart'] ?? [];

      // Remove the item with matching foodId
      List<Map<String, dynamic>> updatedCart = [];

      for (var item in currentCart) {
        if (item is Map<String, dynamic>) {
          // New format: check foodId in the object
          if (item['foodId'] != foodId) {
            updatedCart.add(item);
          }
        } else if (item is String) {
          // Old format: check if string matches foodId
          if (item != foodId) {
            updatedCart.add({'foodId': item, 'quantity': 1});
          }
        }
      }

      // Update Firestore with the new cart
      await userRef.update({"cart": updatedCart});

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
  Future<void> addToCart(
    BuildContext context,
    String foodId, {
    int quantity = 1,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception("User not logged in");
      }

      final userRef = _firestore.collection('users').doc(uid);

      // Get current cart
      final userDoc = await userRef.get();
      List<Map<String, dynamic>> currentCart = [];

      if (userDoc.exists) {
        final data = userDoc.data();
        currentCart = List<Map<String, dynamic>>.from(data?['cart'] ?? []);
      }

      // Check if item already exists in cart
      final existingItemIndex = currentCart.indexWhere(
        (item) => item['foodId'] == foodId,
      );

      if (existingItemIndex != -1) {
        // Update quantity if item exists
        currentCart[existingItemIndex]['quantity'] =
            (currentCart[existingItemIndex]['quantity'] ?? 1) + quantity;

        print("Successfully updated quantity for $foodId in cart");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Updated quantity in cart"),
              backgroundColor: Colors.green[400],
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add new item to cart
        currentCart.add({'foodId': foodId, 'quantity': quantity});

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
      }

      // Update Firestore
      await userRef.update({"cart": currentCart});
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

      await userRef.update({"cart": []});

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
