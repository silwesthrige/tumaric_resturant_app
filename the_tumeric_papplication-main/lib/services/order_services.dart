import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_tumeric_papplication/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _ordersCollection = 'orders';

  // Create a new order
  Future<String?> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,

    String status = 'pending', // Default status
  }) async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate items
      if (items.isEmpty) {
        throw Exception('Order must contain at least one item');
      }

      // Validate delivery address
      if (deliveryAddress.trim().isEmpty) {
        throw Exception('Delivery address is required');
      }

      // Validate each item structure
      for (var item in items) {
        if (!item.containsKey('name') ||
            !item.containsKey('price') ||
            !item.containsKey('qty')) {
          throw Exception('Each item must have name, price, and qty');
        }

        if (item['qty'] <= 0) {
          throw Exception('Item quantity must be greater than 0');
        }

        if (item['price'] <= 0) {
          throw Exception('Item price must be greater than 0');
        }
      }

      // Create order data
      Map<String, dynamic> orderData = {
        'orderId': "",
        'userId': currentUser.uid,
        'items': items,
        'status': status,
        'deliveryAddress': deliveryAddress.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Add order to Firestore
      DocumentReference docRef = await _firestore
          .collection(_ordersCollection)
          .add(orderData);
      await docRef.update({'orderId': docRef.id});
      return docRef.id; // Return the generated order ID
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (doc.exists) {
        return OrderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      rethrow;
    }
  }

  // Get all orders for current user
  Future<List<OrderModel>> getUserOrders() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_ordersCollection)
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                OrderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error getting user orders: $e');
      rethrow;
    }
  }

  // Get orders by status for current user
  Future<List<OrderModel>> getUserOrdersByStatus(String status) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_ordersCollection)
              .where('userId', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: status)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                OrderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error getting orders by status: $e');
      rethrow;
    }
  }

  // Cancel order (only if status is pending)
  Future<bool> cancelOrder(String orderId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // First check if order exists and belongs to user
      DocumentSnapshot doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) {
        throw Exception('Order not found');
      }

      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;

      // Check if order belongs to current user
      if (orderData['userId'] != currentUser.uid) {
        throw Exception('Unauthorized: Order does not belong to current user');
      }

      // Check if order can be cancelled (only pending orders)
      if (orderData['status'] != 'pending') {
        throw Exception(
          'Order cannot be cancelled. Current status: ${orderData['status']}',
        );
      }

      // Update order status to cancelled
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now().toIso8601String(),
        'cancelledAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }

  // Calculate total order amount
  double calculateOrderTotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      double price = (item['price'] as num).toDouble();
      int quantity = item['qty'] as int;
      total += (price * quantity);
    }
    return total;
  }

  // Get order count for current user
  Future<int> getUserOrderCount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_ordersCollection)
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting order count: $e');
      return 0;
    }
  }

  // Listen to order status changes
  Stream<OrderModel?> listenToOrderChanges(String orderId) {
    return _firestore
        .collection(_ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return OrderModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }
          return null;
        });
  }

  // Listen to all user orders
  Stream<List<OrderModel>> listenToUserOrders() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((querySnapshot) {
          return querySnapshot.docs
              .map(
                (doc) => OrderModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  // Update delivery address (only for pending orders)
  Future<bool> updateDeliveryAddress(String orderId, String newAddress) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (newAddress.trim().isEmpty) {
        throw Exception('Delivery address cannot be empty');
      }

      // Check if order exists and belongs to user
      DocumentSnapshot doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) {
        throw Exception('Order not found');
      }

      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;

      if (orderData['userId'] != currentUser.uid) {
        throw Exception('Unauthorized: Order does not belong to current user');
      }

      if (orderData['status'] != 'pending') {
        throw Exception(
          'Cannot update address. Order status: ${orderData['status']}',
        );
      }

      // Update delivery address
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'deliveryAddress': newAddress.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating delivery address: $e');
      rethrow;
    }
  }

  // Check if user can modify order
  Future<bool> canModifyOrder(String orderId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      DocumentSnapshot doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) return false;

      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;

      return orderData['userId'] == currentUser.uid &&
          orderData['status'] == 'pending';
    } catch (e) {
      print('Error checking order modification rights: $e');
      return false;
    }
  }
}
