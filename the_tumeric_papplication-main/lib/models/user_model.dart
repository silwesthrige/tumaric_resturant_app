import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Cart item model to store food ID and quantity
class CartItem {
  final String foodId;
  final int quantity;
  final DateTime addedAt; // Timestamp when item was added to cart

  CartItem({required this.foodId, required this.quantity, DateTime? addedAt})
    : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'quantity': quantity,
      'addedAt': Timestamp.fromDate(addedAt), // Store as Firestore Timestamp
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      foodId: json['foodId'] ?? '',
      quantity: json['quantity'] ?? 1,
      addedAt:
          json['addedAt'] != null
              ? (json['addedAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Check if this cart item has expired (30 minutes)
  bool get isExpired {
    final now = DateTime.now();
    final expiryTime = addedAt.add(Duration(minutes: 30));
    return now.isAfter(expiryTime);
  }

  // Get remaining time until expiry
  Duration get timeUntilExpiry {
    final now = DateTime.now();
    final expiryTime = addedAt.add(Duration(minutes: 30));
    return expiryTime.difference(now);
  }

  // Get minutes remaining until expiry
  int get minutesUntilExpiry {
    final remaining = timeUntilExpiry;
    return remaining.inMinutes.clamp(0, 30);
  }

  // Create a copy with updated quantity
  CartItem copyWith({String? foodId, int? quantity, DateTime? addedAt}) {
    return CartItem(
      foodId: foodId ?? this.foodId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class UserModel {
  final String uID;
  final String? name;
  final String? email;
  final String?
  password; // Consider security implications of storing plain passwords
  final String? address;
  final String? phone;
  final List<CartItem>? cart; // Updated to use CartItem instead of String
  final List<String>? favFoods;
  final List<String>? orders;
  final List<String>? offers;
  final String? profileImageUrl; // Added for a potential profile image

  UserModel({
    this.offers,
    required this.uID,
    this.email,
    this.password,
    this.address,
    this.phone,
    this.cart,
    this.favFoods,
    this.name,
    this.orders,
    this.profileImageUrl, // Added
  });

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      "userId": uID, // Ensure this matches your Firestore document ID/field
      "name": name,
      "email": email,
      // "password": password, // Do not save passwords directly in Firestore. Use Firebase Auth.
      "address": address,
      "phone": phone,
      "cart": cart?.map((item) => item.toJson()).toList() ?? [],
      "favFoods": favFoods ?? [],
      "orders": orders ?? [],
      "profileImageUrl": profileImageUrl,
      "offers": offers ?? [], // Added
    };
  }

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uID: id, // Use the document ID as the uID
      name: json['name'],
      email: json['email'],
      // password: json['password'], // Do not retrieve passwords directly
      address: json['address'],
      phone: json['phone'],
      cart:
          json['cart'] != null
              ? (json['cart'] as List)
                  .map((item) => CartItem.fromJson(item))
                  .toList()
              : null,
      favFoods:
          json['favFoods'] != null ? List<String>.from(json['favFoods']) : null,
      orders: json['orders'] != null ? List<String>.from(json['orders']) : null,
      profileImageUrl: json['profileImageUrl'],
      offers:
          json['offers'] != null
              ? List<String>.from(json['offers'])
              : null, // Added
    );
  }

  // Helper method for copying with new values
  UserModel copyWith({
    String? uID,
    String? name,
    String? email,
    String? password,
    String? address,
    String? phone,
    List<CartItem>? cart,
    List<String>? favFoods,
    List<String>? orders,
    String? profileImageUrl,
  }) {
    return UserModel(
      uID: uID ?? this.uID,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password, // Be cautious with password
      address: address ?? this.address,
      phone: phone ?? this.phone,
      cart: cart ?? this.cart,
      favFoods: favFoods ?? this.favFoods,
      orders: orders ?? this.orders,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
