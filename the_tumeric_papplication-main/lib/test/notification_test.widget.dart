import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/services/notification_service.dart';

import 'package:the_tumeric_papplication/notifications/notification_services.dart';
import 'package:the_tumeric_papplication/services/order_services.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final NotificationService _notificationService = NotificationService();
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  String _lastTestResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Testing'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notification Count Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Current Notification Count',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<int>(
                      stream: _notificationService.getUnreadNotificationCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                count > 0
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: count > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Buttons
            const Text(
              'Test Functions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Local Notification Test
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLocalNotification,
              icon: const Icon(Icons.notifications),
              label: const Text('Test Local Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Create Test Order
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createTestOrder,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Create Test Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Create Custom Notification
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createCustomNotification,
              icon: const Icon(Icons.add_alert),
              label: const Text('Create Custom Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Store FCM Token
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _storeFCMToken,
              icon: const Icon(Icons.token),
              label: const Text('Store FCM Token'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Mark All as Read
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _markAllAsRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark All as Read'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Clear All Notifications
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearAllNotifications,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final orderService = OrderService();
                await orderService.checkAndCreateMissingNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Checked for missing notifications!'),
                  ),
                );
              },
              child: Text('Check Notifications'),
            ),

            // Loading Indicator
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Last Test Result
            if (_lastTestResult.isNotEmpty)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Test Result:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastTestResult,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testLocalNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await NotificationServices.showInstantNotification(
        title: '🧪 Test Notification',
        body:
            'This is a local test notification. Time: ${DateTime.now().toString()}',
      );

      setState(() {
        _lastTestResult =
            'Local notification sent successfully at ${DateTime.now()}';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error sending local notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? orderId = await _orderService.createOrder(
        total: 29.99,
        items: [
          {'name': 'Test Chicken Curry', 'price': 19.99, 'qty': 1},
          {'name': 'Test Rice', 'price': 10.00, 'qty': 1},
        ],
        deliveryAddress: '123 Test Street, Test City, 12345',
      );

      setState(() {
        _lastTestResult =
            'Test order created successfully! Order ID: ${orderId?.substring(0, 8)}... Check your notifications.';
      });

      // Wait a moment, then simulate order status updates
      await Future.delayed(const Duration(seconds: 2));
      await _orderService.updateOrderStatus(orderId!, 'confirmed');

      await Future.delayed(const Duration(seconds: 2));
      await _orderService.updateOrderStatus(orderId, 'preparing');
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error creating test order: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createCustomNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? notificationId = await _notificationService.createNotification(
        userId:
            'current_user', // This should be replaced with actual current user ID
        title: '🎉 Special Offer!',
        message:
            'Get 20% off on your next order! Use code TEST20. This is a custom test notification created at ${DateTime.now().hour}:${DateTime.now().minute}.',
        type: 'promotion',
        additionalData: {'discount': '20%', 'code': 'TEST20', 'isTest': true},
      );

      setState(() {
        _lastTestResult =
            'Custom notification created! ID: ${notificationId?.substring(0, 8)}... Check the notifications page.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error creating custom notification: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _storeFCMToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.storeUserToken();

      setState(() {
        _lastTestResult =
            'FCM Token stored successfully! This enables push notifications.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error storing FCM token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.markAllAsRead();

      setState(() {
        _lastTestResult =
            'All notifications marked as read. Badge count should be 0 now.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error marking notifications as read: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // Show confirmation dialog
    bool confirmed =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Clear All Notifications'),
                content: const Text(
                  'Are you sure you want to delete all notifications? This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Delete All',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmed) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _notificationService.deleteAllNotifications();

      setState(() {
        _lastTestResult =
            'All notifications deleted successfully. Notifications page should be empty now.';
      });
    } catch (e) {
      setState(() {
        _lastTestResult = 'Error deleting notifications: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// To add this test page to your app, add this route to main.dart:
// '/notification-test': (context) => const NotificationTestPage(),

// And add this navigation method to your NavigationExtension:
// void goToNotificationTest() => Navigator.of(this).pushNamed('/notification-test');
