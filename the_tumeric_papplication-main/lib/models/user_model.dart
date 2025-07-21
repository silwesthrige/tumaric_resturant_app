
class UserModel {
  final String uID;
  final String? name;
  final String? email;
  final String? password;
  final String? address;
  final String? phone;
  final List<String>? cart;
  final List<String>? favFoods;

  UserModel({
    required this.uID,
    this.email,
    this.password,
    this.address,
    this.phone,
    this.cart,
    this.favFoods,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": uID,
      "name": name,
      "email": email,
      "password": password,
      "address": address,
      "phone": phone,
      "cart": cart,
      "favFoods": favFoods,
    };
  }
}
