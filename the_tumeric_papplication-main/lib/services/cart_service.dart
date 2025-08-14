import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:the_tumeric_papplication/models/user_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Timer for periodic cleanup (optional - for when app is active)
  Timer? _cleanupTimer;

  CartService() {
    // Start periodic cleanup every 5 minutes when service is initialized
    _startPeriodicCleanup();
  }

  // Start periodic cleanup timer
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _cleanExpiredCartItems(uid);
      }
    });
  }

  // Stop cleanup timer
  void dispose() {
    _cleanupTimer?.cancel();
  }

  // Clean expired cart items (30+ minutes old)
  Future<List<CartItem>> _cleanExpiredCartItems(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> currentCart = userData['cart'] ?? [];

      // Convert to CartItem objects and filter out expired items
      List<CartItem> validItems = [];
      List<CartItem> expiredItems = [];

      for (var item in currentCart) {
        if (item is Map<String, dynamic>) {
          final cartItem = CartItem.fromJson(item);

          if (cartItem.isExpired) {
            expiredItems.add(cartItem);
            print(
              'Expired cart item: ${cartItem.foodId} (added at: ${cartItem.addedAt})',
            );
          } else {
            validItems.add(cartItem);
          }
        }
      }

      // If there are expired items, update the cart
      if (expiredItems.isNotEmpty) {
        final updatedCart = validItems.map((item) => item.toJson()).toList();
        await userRef.update({"cart": updatedCart});

        print(
          'Removed ${expiredItems.length} expired items from cart for user: $uid',
        );
      }

      return expiredItems;
    } catch (e) {
      print('Error cleaning expired cart items: $e');
      return [];
    }
  }

  // Enhanced method to clean expired items and notify user
  Future<List<CartItem>> cleanExpiredCartItemsWithNotification(
    BuildContext? context,
    String uid,
  ) async {
    try {
      final expiredItems = await _cleanExpiredCartItems(uid);

      // Show notification if items were removed and context is available
      if (expiredItems.isNotEmpty && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${expiredItems.length} item(s) removed from cart (30min expiry)',
            ),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }

      return expiredItems;
    } catch (e) {
      print('Error in cleanExpiredCartItemsWithNotification: $e');
      return [];
    }
  }

  // Get cart items with automatic cleanup
  Future<List<DocumentSnapshot>> getCartFoodDetails(
    List<String> foodIds, {
    BuildContext? context,
  }) async {
    if (foodIds.isEmpty) return [];

    // Clean expired items first
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await cleanExpiredCartItemsWithNotification(context, uid);
    }

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

  // Enhanced method to get cart data with CartItem objects
  Future<List<CartItem>> getCartItems(String uid) async {
    try {
      // Clean expired items first
      await _cleanExpiredCartItems(uid);

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('cart')) {
          final cartList = List<dynamic>.from(data['cart'] ?? []);

          // Convert to CartItem objects
          List<CartItem> cartItems = [];
          for (var item in cartList) {
            if (item is Map<String, dynamic>) {
              cartItems.add(CartItem.fromJson(item));
            } else if (item is String) {
              // Handle old format (migrate to new format)
              cartItems.add(CartItem(foodId: item, quantity: 1));
            }
          }

          print("Cart items for user $uid: ${cartItems.length} items");
          return cartItems;
        }
      }

      return [];
    } catch (e) {
      print("Error getting cart items: $e");
      throw Exception("Failed to load user cart data");
    }
  }

  // Enhanced add to cart with automatic timestamp
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

      // Clean expired items first
      await _cleanExpiredCartItems(uid);

      // Get current cart
      final userDoc = await userRef.get();
      List<CartItem> currentCart = [];

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('cart')) {
          final cartList = List<dynamic>.from(data['cart'] ?? []);

          for (var item in cartList) {
            if (item is Map<String, dynamic>) {
              currentCart.add(CartItem.fromJson(item));
            }
          }
        }
      }

      // Check if item already exists in cart
      final existingItemIndex = currentCart.indexWhere(
        (item) => item.foodId == foodId,
      );

      if (existingItemIndex != -1) {
        // Update quantity and reset timestamp for existing item
        currentCart[existingItemIndex] = currentCart[existingItemIndex]
            .copyWith(
              quantity: currentCart[existingItemIndex].quantity + quantity,
              addedAt:
                  DateTime.now(), // Reset timestamp when quantity is updated
            );

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
        // Add new item to cart with current timestamp
        currentCart.add(
          CartItem(foodId: foodId, quantity: quantity, addedAt: DateTime.now()),
        );

        print("Successfully added $foodId to cart");

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Item added to cart (expires in 30 min)"),
              backgroundColor: Colors.green[400],
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Convert to JSON and update Firestore
      final cartJson = currentCart.map((item) => item.toJson()).toList();
      await userRef.update({"cart": cartJson});
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

  // Enhanced remove from cart
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

      // Convert to CartItem objects and remove the specified item
      List<CartItem> updatedCart = [];

      for (var item in currentCart) {
        if (item is Map<String, dynamic>) {
          final cartItem = CartItem.fromJson(item);
          if (cartItem.foodId != foodId) {
            updatedCart.add(cartItem);
          }
        }
      }

      // Convert back to JSON and update Firestore
      final cartJson = updatedCart.map((item) => item.toJson()).toList();
      await userRef.update({"cart": cartJson});

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

  // Clear entire cart
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

  // Get cart count (with cleanup)
  Future<int> getCartCount(String uid) async {
    try {
      final cartItems = await getCartItems(uid);
      return cartItems.length;
    } catch (e) {
      print("Error getting cart count: $e");
      return 0;
    }
  }

  // Check if item is in cart (with cleanup)
  Future<bool> isInCart(String uid, String foodId) async {
    try {
      final cartItems = await getCartItems(uid);
      return cartItems.any((item) => item.foodId == foodId);
    } catch (e) {
      print("Error checking if item is in cart: $e");
      return false;
    }
  }

  // Get cart expiry info for UI display
  Future<Map<String, dynamic>> getCartExpiryInfo(String uid) async {
    try {
      final cartItems = await getCartItems(uid);

      if (cartItems.isEmpty) {
        return {'hasItems': false, 'nearestExpiry': null, 'expiryMinutes': 0};
      }

      // Find the item that expires soonest
      CartItem? nearestExpiryItem;
      int minMinutesLeft = 30;

      for (var item in cartItems) {
        int minutesLeft = item.minutesUntilExpiry;
        if (minutesLeft < minMinutesLeft) {
          minMinutesLeft = minutesLeft;
          nearestExpiryItem = item;
        }
      }

      return {
        'hasItems': true,
        'nearestExpiry': nearestExpiryItem,
        'expiryMinutes': minMinutesLeft,
        'totalItems': cartItems.length,
      };
    } catch (e) {
      print("Error getting cart expiry info: $e");
      return {'hasItems': false, 'nearestExpiry': null, 'expiryMinutes': 0};
    }
  }

  // Manual cleanup method (can be called from UI)
  Future<void> manualCleanup(BuildContext? context) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await cleanExpiredCartItemsWithNotification(context, uid);
    }
  }
}
