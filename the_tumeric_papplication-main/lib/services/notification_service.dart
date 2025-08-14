import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:the_tumeric_papplication/models/notification_model.dart';
import 'package:the_tumeric_papplication/notifications/notification_services.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _notificationsCollection = 'notifications';
  final String _userTokensCollection = 'user_tokens';

  // Store user FCM token
  Future<void> storeUserToken() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore
            .collection(_userTokensCollection)
            .doc(currentUser.uid)
            .set({
              'token': token,
              'userId': currentUser.uid,
              'updatedAt': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      print('Error storing user token: $e');
    }
  }

  // Get user FCM token
  Future<String?> getUserToken(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_userTokensCollection).doc(userId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['token'];
      }
      return null;
    } catch (e) {
      print('Error getting user token: $e');
      return null;
    }
  }

  // Create notification in Firestore
  Future<String?> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? orderId,
    String? orderStatus,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      NotificationModel notification = NotificationModel(
        userId: userId,
        title: title,
        message: message,
        type: type,
        orderId: orderId,
        orderStatus: orderStatus,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      DocumentReference docRef = await _firestore
          .collection(_notificationsCollection)
          .add(notification.toJson());

      // Update document with its ID
      await docRef.update({'notificationId': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error creating notification: $e');
      return null;
    }
  }

  // Send push notification to specific user
  Future<void> sendPushNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      String? token = await getUserToken(userId);
      if (token == null) {
        print('No FCM token found for user: $userId');
        return;
      }

      // Send local notification if app is in foreground
      await NotificationServices.showInstantNotification(
        title: title,
        body: message,
      );

      // Here you would typically call your cloud function or use FCM admin SDK
      // For now, we'll just print the details
      print('Sending push notification to user: $userId');
      print('Title: $title');
      print('Message: $message');
      print('Token: $token');
      print('Data: $data');
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Create and send order status notification
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String newStatus,
    required String orderTotal,
  }) async {
    try {
      String title = _getOrderStatusTitle(newStatus);
      String message = _getOrderStatusMessage(newStatus, orderId, orderTotal);

      // Create notification in Firestore
      await createNotification(
        userId: userId,
        title: title,
        message: message,
        type: 'order_status',
        orderId: orderId,
        orderStatus: newStatus,
        additionalData: {
          'orderTotal': orderTotal,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Send push notification
      await sendPushNotificationToUser(
        userId: userId,
        title: title,
        message: message,
        data: {'type': 'order_status', 'orderId': orderId, 'status': newStatus},
      );
    } catch (e) {
      print('Error sending order status notification: $e');
    }
  }

  // Get order status title
  String _getOrderStatusTitle(String status) {
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

  // Get order status message
  String _getOrderStatusMessage(String status, String orderId, String total) {
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

  // FIXED: Get notifications for current user - NO COMPOSITE INDEX NEEDED
  Stream<List<NotificationModel>> getUserNotifications() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: currentUser.uid)
        // Removed orderBy to avoid composite index requirement
        .snapshots()
        .map((querySnapshot) {
          List<NotificationModel> notifications =
              querySnapshot.docs
                  .map(
                    (doc) => NotificationModel.fromJson(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

          // Sort in code instead of in query
          notifications.sort((a, b) {
            return b.createdAt.compareTo(
              a.createdAt,
            ); // Descending order (newest first)
          });

          return notifications;
        });
  }

  // FIXED: Get unread notification count - NO COMPOSITE INDEX NEEDED
  Stream<int> getUnreadNotificationCount() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: currentUser.uid)
        // Removed second where clause to avoid composite index
        .snapshots()
        .map((querySnapshot) {
          // Filter unread notifications in code instead
          return querySnapshot.docs
              .where(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['isRead'] == false,
              )
              .length;
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      QuerySnapshot unreadNotifications =
          await _firestore
              .collection(_notificationsCollection)
              .where('userId', isEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      QuerySnapshot userNotifications =
          await _firestore
              .collection(_notificationsCollection)
              .where('userId', isEqualTo: currentUser.uid)
              .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // Send promotional notification to all users
  Future<void> sendPromotionalNotification({
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get all user tokens
      QuerySnapshot userTokens =
          await _firestore.collection(_userTokensCollection).get();

      for (QueryDocumentSnapshot doc in userTokens.docs) {
        String userId = (doc.data() as Map<String, dynamic>)['userId'];

        await createNotification(
          userId: userId,
          title: title,
          message: message,
          type: 'promotion',
          additionalData: additionalData,
        );

        await sendPushNotificationToUser(
          userId: userId,
          title: title,
          message: message,
          data: {'type': 'promotion'},
        );
      }
    } catch (e) {
      print('Error sending promotional notification: $e');
    }
  }
}
