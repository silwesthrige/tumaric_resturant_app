import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_tumeric_papplication/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _ordersCollection = 'orders';

  // Create a new order
  Future<String?> createOrder({
    required double total,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    String status = 'pending',
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (items.isEmpty) {
        throw Exception('Order must contain at least one item');
      }

      if (deliveryAddress.trim().isEmpty) {
        throw Exception('Delivery address is required');
      }

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

      Map<String, dynamic> orderData = {
        'orderId': "",
        'userId': currentUser.uid,
        'items': items,
        'status': status,
        'deliveryAddress': deliveryAddress.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'total' : total.toDouble(),
      };

      DocumentReference docRef = await _firestore
          .collection(_ordersCollection)
          .add(orderData);
      await docRef.update({'orderId': docRef.id});
      return docRef.id;
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

  // FIXED: Get all orders for current user - NO COMPOSITE INDEX NEEDED
  Future<List<OrderModel>> getUserOrders() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Simple query with only WHERE clause - no orderBy to avoid composite index
      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_ordersCollection)
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      List<OrderModel> orders =
          querySnapshot.docs
              .map(
                (doc) => OrderModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Sort in code instead of in query
      orders.sort((a, b) {
        DateTime dateA = DateTime.parse(a.createdAt.toString());
        DateTime dateB = DateTime.parse(b.createdAt.toString());
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

      return orders;
    } catch (e) {
      print('Error getting user orders: $e');
      rethrow;
    }
  }

  // FIXED: Get orders by status - NO COMPOSITE INDEX NEEDED
  Future<List<OrderModel>> getUserOrdersByStatus(String status) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all user orders first
      List<OrderModel> allOrders = await getUserOrders();

      // Filter by status in code
      return allOrders.where((order) => order.status == status).toList();
    } catch (e) {
      print('Error getting orders by status: $e');
      rethrow;
    }
  }

  // FIXED: Get active orders
  Future<List<OrderModel>> getActiveOrders() async {
    try {
      List<OrderModel> allOrders = await getUserOrders();
      const activeStatuses = [
        'pending',
        'confirmed',
        'preparing',
        'out_for_delivery',
      ];
      return allOrders
          .where((order) => activeStatuses.contains(order.status))
          .toList();
    } catch (e) {
      print('Error getting active orders: $e');
      rethrow;
    }
  }

  // FIXED: Get completed orders
  Future<List<OrderModel>> getCompletedOrders() async {
    try {
      List<OrderModel> allOrders = await getUserOrders();
      const completedStatuses = ['delivered', 'cancelled'];
      return allOrders
          .where((order) => completedStatuses.contains(order.status))
          .toList();
    } catch (e) {
      print('Error getting completed orders: $e');
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
          'Order cannot be cancelled. Current status: ${orderData['status']}',
        );
      }

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

  // FIXED: Listen to order status changes - simplified
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

  // FIXED: Listen to all user orders - NO COMPOSITE INDEX NEEDED
  Stream<List<OrderModel>> listenToUserOrders() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_ordersCollection)
        .where('userId', isEqualTo: currentUser.uid)
        // Removed orderBy to avoid composite index requirement
        .snapshots()
        .map((querySnapshot) {
          List<OrderModel> orders =
              querySnapshot.docs
                  .map(
                    (doc) => OrderModel.fromJson(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

          // Sort in code instead
          orders.sort((a, b) {
            DateTime dateA = DateTime.parse(a.createdAt.toString());
            DateTime dateB = DateTime.parse(b.createdAt.toString());
            return dateB.compareTo(dateA); // Descending order
          });

          return orders;
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
