import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionModel {
  final String promoId;
  final String imageUrl;
  final String status;
  final double precentage; // Keep original naming for compatibility
  final String promoType;
  final int usageLimit;
  final int usageCount;
  final String title;
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minimumOrderAmount;

  PromotionModel({
    required this.usageCount,
    required this.promoId,
    required this.imageUrl,
    required this.status,
    required this.precentage,
    required this.promoType,
    required this.usageLimit,
    this.title = '',
    this.description = '',
    this.startDate,
    this.endDate,
    this.minimumOrderAmount,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> docs, String id) {
    return PromotionModel(
      promoId: docs["promoId"] ?? id,
      imageUrl: docs["imageUrl"] ?? '',
      status: docs["status"] ?? 'inactive',
      precentage: (docs["discountValue"] as num?)?.toDouble() ?? 0.0,
      promoType: docs["discountType"] ?? 'percentage',
      usageLimit: docs["usageLimit"] ?? 0,
      usageCount: docs["usageCount"] ?? 0,
      title: docs["title"] ?? '',
      description: docs["description"] ?? '',
      startDate: docs["startDate"] != null 
          ? (docs["startDate"] as Timestamp).toDate() 
          : null,
      endDate: docs["endDate"] != null 
          ? (docs["endDate"] as Timestamp).toDate() 
          : null,
      minimumOrderAmount: (docs["minimumOrderAmount"] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "promoId": promoId,
      "imageUrl": imageUrl,
      "status": status,
      "discountValue": precentage,
      "discountType": promoType,
      "usageLimit": usageLimit,
      "usageCount": usageCount,
      "title": title,
      "description": description,
      "startDate": startDate != null ? Timestamp.fromDate(startDate!) : null,
      "endDate": endDate != null ? Timestamp.fromDate(endDate!) : null,
      "minimumOrderAmount": minimumOrderAmount,
    };
  }

  // Helper methods
  bool get isActive => status.toLowerCase() == 'active';
  bool get isAvailable => isActive && usageCount < usageLimit;
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get hasStarted => startDate == null || startDate!.isBefore(DateTime.now());
  
  int get remainingCount => usageLimit - usageCount;
  
  String get discountText {
    if (promoType.toLowerCase() == 'percentage') {
      return '${precentage.toInt()}% OFF';
    } else {
      return '\$${precentage.toStringAsFixed(0)} OFF';
    }
  }

  bool isValidForOrder(double orderAmount) {
    return minimumOrderAmount == null || orderAmount >= minimumOrderAmount!;
  }
}

class ClaimedOffer {
  final String id;
  final String userId;
  final String promoId;
  final String promoType;
  final double discountValue;
  final String status; // active, used, expired
  final DateTime claimedAt;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? orderId; // Order where this offer was used

  ClaimedOffer({
    required this.id,
    required this.userId,
    required this.promoId,
    required this.promoType,
    required this.discountValue,
    required this.status,
    required this.claimedAt,
    required this.expiresAt,
    required this.isUsed,
    this.usedAt,
    this.orderId,
  });

  factory ClaimedOffer.fromJson(Map<String, dynamic> json, String id) {
    return ClaimedOffer(
      id: id,
      userId: json['userId'] ?? '',
      promoId: json['promoId'] ?? '',
      promoType: json['promoType'] ?? 'percentage',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'active',
      claimedAt: json['claimedAt'] != null 
          ? (json['claimedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null 
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.now(),
      isUsed: json['isUsed'] ?? false,
      usedAt: json['usedAt'] != null 
          ? (json['usedAt'] as Timestamp).toDate()
          : null,
      orderId: json['orderId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'promoId': promoId,
      'promoType': promoType,
      'discountValue': discountValue,
      'status': status,
      'claimedAt': Timestamp.fromDate(claimedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'orderId': orderId,
    };
  }

  // Helper methods
  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isActive => status == 'active' && !isUsed && !isExpired;
  
  String get discountText {
    if (promoType.toLowerCase() == 'percentage') {
      return '${discountValue.toInt()}% OFF';
    } else {
      return '\$${discountValue.toStringAsFixed(0)} OFF';
    }
  }

  double calculateDiscount(double orderAmount) {
    if (promoType.toLowerCase() == 'percentage') {
      return orderAmount * (discountValue / 100);
    } else {
      return discountValue > orderAmount ? orderAmount : discountValue;
    }
  }

  int get daysUntilExpiry {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }
}