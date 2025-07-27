import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Cart item model to store food ID and quantity
class CartItem {
  final String foodId;
  final int quantity;

  CartItem({required this.foodId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {'foodId': foodId, 'quantity': quantity};
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      foodId: json['foodId'] ?? '',
      quantity: json['quantity'] ?? 1,
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
