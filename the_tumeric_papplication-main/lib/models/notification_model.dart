class NotificationModel {
  final String? notificationId;
  final String userId;
  final String title;
  final String message;
  final String type; // 'order_status', 'promotion', 'general'
  final String? orderId;
  final String? orderStatus;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  NotificationModel({
    this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.orderId,
    this.orderStatus,
    required this.createdAt,
    this.isRead = false,
    this.additionalData,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'orderId': orderId,
      'orderStatus': orderStatus,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'additionalData': additionalData,
    };
  }

  // Create from JSON (Firestore document)
  factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
    return NotificationModel(
      notificationId: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      orderId: json['orderId'],
      orderStatus: json['orderStatus'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      additionalData: json['additionalData'],
    );
  }

  // Copy with method for updates
  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? orderId,
    String? orderStatus,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? additionalData,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}