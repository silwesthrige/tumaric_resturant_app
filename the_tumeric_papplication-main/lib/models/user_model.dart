import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uID;
  final String? name;
  final String? email;
  final String? password;
  final String? address;
  final String? phone;
  final List<String>? cart;
  final List<String>? favFoods;
  final List<String>? orders;

  UserModel({
    required this.uID,
    this.email,
    this.password,
    this.address,
    this.phone,
    this.cart,
    this.favFoods,
    this.name,
    this.orders,
  });

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      "userId": uID,
      "name": name,
      "email": email,
      "password": password,
      "address": address,
      "phone": phone,
      "cart": cart ?? [],
      "favFoods": favFoods ?? [],
      "orders": orders ?? [],
    };
  }

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      uID: json['userId'] ?? '',
      name: json['name'],
      email: json['email'],
      password: json['password'],
      address: json['address'],
      phone: json['phone'],
      cart: json['cart'] != null ? List<String>.from(json['cart']) : null,
      favFoods:
          json['favFoods'] != null ? List<String>.from(json['favFoods']) : null,
      orders: json['orders'] != null ? List<String>.from(json['orders']) : null,
    );
  }
}
