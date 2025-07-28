class OrderModel {
  final String orderId;
  final String userId;
  final List<Map<String, dynamic>> items; // each item: name, price, qty
  final String status;
  final DateTime createdAt;
  final String deliveryAddress;

  OrderModel({
    required this.deliveryAddress,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.status,
    required this.createdAt,
  });

  //toJson
  Map<String, dynamic> toJson() {
    return {
      "orderId": orderId,
      "userId": userId,
      "items": items,
      "status": status,
      "createdAt": createdAt,
      "deliveryAddress": deliveryAddress,
    };
  }

  //from Json
  factory OrderModel.fromJson(Map<String, dynamic> Json, String docId) {
    return OrderModel(
      orderId: docId,
      userId: Json["userId"],
      items: List<Map<String, dynamic>>.from(Json['items']),
      status: Json["status"],
      createdAt: DateTime.parse(Json["createdAt"]),
      deliveryAddress: Json["deliveryAddress"],
    );
  }
}
