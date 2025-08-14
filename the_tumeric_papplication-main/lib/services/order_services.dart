import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_tumeric_papplication/models/order_model.dart';
import 'package:the_tumeric_papplication/notifications/notification_services.dart';
import 'package:the_tumeric_papplication/services/notification_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _ordersCollection = 'orders';
  final NotificationService _notificationService = NotificationService();

  // Create a new order (with automatic notification)
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
        'total': total.toDouble(),
      };

      DocumentReference docRef = await _firestore
          .collection(_ordersCollection)
          .add(orderData);
      await docRef.update({'orderId': docRef.id});

      // Send order creation notification
      await _notificationService.createNotification(
        userId: currentUser.uid,
        title: '🎉 Order Placed Successfully!',
        message:
            'Your order #${docRef.id.substring(0, 8)} worth ₹${total.toStringAsFixed(2)} has been placed. We\'ll notify you when it\'s confirmed.',
        type: 'order_status',
        orderId: docRef.id,
        orderStatus: status,
        additionalData: {
          'orderTotal': total.toString(),
          'itemCount': items.length,
        },
      );

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

  // Update order status (for admin use - with notification)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();

      if (!doc.exists) {
        throw Exception('Order not found');
      }

      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
      String userId = orderData['userId'];
      double total = (orderData['total'] as num).toDouble();

      // Update order status
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Send notification to user about status change
      await _notificationService.sendOrderStatusNotification(
        userId: userId,
        orderId: orderId,
        newStatus: newStatus,
        orderTotal: total.toStringAsFixed(2),
      );

      return true;
    } catch (e) {
      print('Error updating order status: $e');
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

  // Cancel order (only if status is pending) - with notification
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

      // Send cancellation notification
      double total = (orderData['total'] as num).toDouble();
      await _notificationService.sendOrderStatusNotification(
        userId: currentUser.uid,
        orderId: orderId,
        newStatus: 'cancelled',
        orderTotal: total.toStringAsFixed(2),
      );

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

  // Admin function to get all orders (for admin dashboard)
  Future<List<OrderModel>> getAllOrders() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_ordersCollection)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map(
            (doc) =>
                OrderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error getting all orders: $e');
      rethrow;
    }
  }

  // Admin function to get orders by status
  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_ordersCollection)
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

  // Admin function to listen to all orders
  Stream<List<OrderModel>> listenToAllOrders() {
    return _firestore
        .collection(_ordersCollection)
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

  Future<void> checkAndCreateMissingNotifications() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      print('🔍 Checking for missing notifications...');

      // Get all user orders
      QuerySnapshot orderSnapshot =
          await _firestore
              .collection(_ordersCollection)
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      // Get existing notifications
      QuerySnapshot notificationSnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: currentUser.uid)
              .where('type', isEqualTo: 'order_status')
              .get();

      // Create map of existing notifications by orderId + status
      Set<String> existingNotifications = {};
      for (var doc in notificationSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String key = '${data['orderId']}_${data['orderStatus']}';
        existingNotifications.add(key);
      }

      // Check each order for missing notifications
      for (var orderDoc in orderSnapshot.docs) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final orderId = orderDoc.id;
        final currentStatus = orderData['status'];
        final orderTotal = orderData['total'];

        // Check if notification exists for current status
        String notificationKey = '${orderId}_${currentStatus}';

        if (!existingNotifications.contains(notificationKey) &&
            currentStatus != 'pending') {
          print(
            '📱 Creating missing notification for order $orderId status: $currentStatus',
          );

          // Create missing notification
          await _notificationService.createNotification(
            userId: currentUser.uid,
            title: _getStatusTitle(currentStatus),
            message: _getStatusMessage(
              currentStatus,
              orderId,
              orderTotal.toString(),
            ),
            type: 'order_status',
            orderId: orderId,
            orderStatus: currentStatus,
            additionalData: {
              'orderTotal': orderTotal.toString(),
              'createdFrom': 'status_check',
              'originalOrderTime': orderData['createdAt'],
            },
          );

          // Send local notification
          await NotificationServices.showInstantNotification(
            title: _getStatusTitle(currentStatus),
            body: _getStatusMessage(
              currentStatus,
              orderId,
              orderTotal.toString(),
            ),
          );

          print('✅ Created notification for $orderId - $currentStatus');
        }
      }

      print('🎉 Notification check completed!');
    } catch (e) {
      print('Error checking missing notifications: $e');
    }
  }

  // Helper methods for notification content
  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return '✅ Order Confirmed!';
      case 'preparing':
        return '👨‍🍳 Kitchen is Preparing Your Order';
      case 'out_for_delivery':
        return '🚀 Order Out for Delivery';
      case 'delivered':
        return '🎉 Order Delivered Successfully';
      case 'cancelled':
        return '❌ Order Cancelled';
      default:
        return '📦 Order Status Updated';
    }
  }

  String _getStatusMessage(String status, String orderId, String total) {
    String shortOrderId =
        orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Great! Your order #$shortOrderId worth ₹$total has been confirmed. We\'ll start preparing it soon.';
      case 'preparing':
        return 'Our chefs are carefully preparing your order #$shortOrderId. It will be ready soon!';
      case 'out_for_delivery':
        return 'Your order #$shortOrderId is on its way! Expected delivery in 20-30 minutes.';
      case 'delivered':
        return 'Your order #$shortOrderId has been delivered successfully. Enjoy your meal! 🍽️';
      case 'cancelled':
        return 'Your order #$shortOrderId has been cancelled. If you have any questions, please contact support.';
      default:
        return 'Your order #$shortOrderId status has been updated to $status.';
    }
  }
}
