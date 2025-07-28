import 'dart:async';
import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/order_model.dart';
import 'package:the_tumeric_papplication/services/order_services.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  List<OrderModel>? _cachedActiveOrders;
  List<OrderModel>? _cachedHistoryOrders;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
    _startRealTimeUpdates();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _loadInitialData() async {
    try {
      final activeOrders = await _orderService.getActiveOrders();
      final historyOrders = await _orderService.getCompletedOrders();

      if (mounted) {
        setState(() {
          _cachedActiveOrders = activeOrders;
          _cachedHistoryOrders = historyOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startRealTimeUpdates() {
    // Refresh orders every 30 seconds to get real-time status updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshOrdersData();
      }
    });
  }

  void _startCountdownTimer() {
    // Update countdown every second for better user experience
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        // Only trigger rebuild for countdown, not data refresh
        setState(() {
          // This will only update the countdown timers, not reload data
        });
      }
    });
  }

  void _refreshOrdersData() async {
    try {
      final activeOrders = await _orderService.getActiveOrders();
      final historyOrders = await _orderService.getCompletedOrders();

      if (mounted) {
        setState(() {
          _cachedActiveOrders = activeOrders;
          _cachedHistoryOrders = historyOrders;
        });
      }
    } catch (e) {
      // Silently handle errors for background refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          // Add refresh button for manual refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _refreshOrdersData();
              _showSnackBar('Refreshing orders...', Colors.orange);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.orange[100],
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'Active Orders'),
            Tab(icon: Icon(Icons.history), text: 'Order History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildActiveOrders(), _buildOrderHistory()],
      ),
    );
  }

  Widget _buildActiveOrders() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    final activeOrders = _cachedActiveOrders ?? [];

    if (activeOrders.isEmpty) {
      return _buildEmptyState(
        'No Active Orders',
        'You don\'t have any active orders at the moment.',
        Icons.shopping_bag_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadInitialData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(activeOrders[index], isActive: true);
        },
      ),
    );
  }

  Widget _buildOrderHistory() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    final historyOrders = _cachedHistoryOrders ?? [];

    if (historyOrders.isEmpty) {
      return _buildEmptyState(
        'No Order History',
        'Your completed and cancelled orders will appear here.',
        Icons.history,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadInitialData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(historyOrders[index], isActive: false);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isActive}) {
    final canModify = _canModifyOrder(order);
    final canCancel = _canCancelOrder(order);
    final total = _orderService.calculateOrderTotal(order.items);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt.toString()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                _buildItemsList(order.items),

                const SizedBox(height: 16),

                // Delivery Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Total
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons for active orders (with 10-minute logic)
                if (isActive && (canModify || canCancel)) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(order),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items (${items.length})',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name']} x${item['qty']}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                    Text(
                      '\$${(item['price'] * item['qty']).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        displayText = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        displayText = 'Confirmed';
        break;
      case 'preparing':
        color = Colors.purple;
        displayText = 'Preparing';
        break;
      case 'out_for_delivery':
        color = Colors.indigo;
        displayText = 'Out for Delivery';
        break;
      case 'delivered':
        color = Colors.green;
        displayText = 'Delivered';
        break;
      case 'cancelled':
        color = Colors.red;
        displayText = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final canCancel = _canCancelOrder(order);
    final canEdit = _canModifyOrder(order);
    final timeRemaining = _getTimeRemainingForCancel(order);

    return Column(
      children: [
        // Time remaining indicator
        if (canCancel || canEdit) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  timeRemaining.inMinutes <= 2
                      ? Colors.red[50]
                      : Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    timeRemaining.inMinutes <= 2
                        ? Colors.red[300]!
                        : Colors.orange[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color:
                      timeRemaining.inMinutes <= 2
                          ? Colors.red[700]
                          : Colors.orange[700],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimeRemaining(timeRemaining),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        timeRemaining.inMinutes <= 2
                            ? Colors.red[700]
                            : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Action buttons
        Row(
          children: [
            // Edit Address Button
            if (canEdit) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditAddressDialog(order),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Address'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (canCancel) const SizedBox(width: 12),
            ],

            // Cancel Button - Only show if within 10 minutes
            if (canCancel) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCancelDialog(order),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        timeRemaining.inMinutes <= 2
                            ? Colors.red[700]
                            : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Expired message
        if (!canCancel && !canEdit && order.status == 'pending') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Modification time expired (10 min limit)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text('Loading orders...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  bool _canModifyOrder(OrderModel order) {
    if (order.status != 'pending') return false;

    final createdAt = DateTime.parse(order.createdAt.toString());
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    return difference.inMinutes <= 10;
  }

  bool _canCancelOrder(OrderModel order) {
    if (order.status != 'pending') return false;

    final createdAt = DateTime.parse(order.createdAt.toString());
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    return difference.inMinutes <= 3;
  }

  Duration _getTimeRemainingForCancel(OrderModel order) {
    final createdAt = DateTime.parse(order.createdAt.toString());
    final now = DateTime.now();
    final elapsed = now.difference(createdAt);
    final remaining = const Duration(minutes: 3) - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatTimeRemaining(Duration remaining) {
    if (remaining == Duration.zero) {
      return 'Time expired';
    }

    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s left';
    } else {
      return '${remaining.inSeconds}s left';
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showEditAddressDialog(OrderModel order) {
    final controller = TextEditingController(text: order.deliveryAddress);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Delivery Address'),
            content: TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter new delivery address',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _updateAddress(order.orderId, controller.text),
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showCancelDialog(OrderModel order) {
    final timeRemaining = _getTimeRemainingForCancel(order);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text('Cancel Order'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to cancel this order? This action cannot be undone.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.red[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Time remaining: ${_formatTimeRemaining(timeRemaining)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep Order'),
              ),
              ElevatedButton(
                onPressed:
                    timeRemaining > Duration.zero
                        ? () => _cancelOrder(order.orderId)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Cancel Order'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateAddress(String orderId, String newAddress) async {
    Navigator.pop(context);

    try {
      await _orderService.updateDeliveryAddress(orderId, newAddress);
      _showSnackBar('Address updated successfully', Colors.green);
      // Refresh immediately after update
      _refreshOrdersData();
    } catch (e) {
      _showSnackBar('Failed to update address: $e', Colors.red);
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    Navigator.pop(context);

    try {
      await _orderService.cancelOrder(orderId);
      _showSnackBar('Order cancelled successfully', Colors.green);
      // Refresh immediately after cancellation
      _refreshOrdersData();
    } catch (e) {
      _showSnackBar('Failed to cancel order: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
