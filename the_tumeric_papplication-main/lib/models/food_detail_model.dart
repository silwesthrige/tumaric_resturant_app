class FoodDetailModel {
  final String? foodName;
  final String? discription;
  final String? shortDisc;
  final String? imageUrl;
  final double? price;
  final double? cookedTime;
  final String? foodId;
  final String? status;

  FoodDetailModel({
    this.foodId,
    this.status,
    required this.foodName,
    required this.discription,
    required this.imageUrl,
    required this.price,
    required this.cookedTime,
    required this.shortDisc,
  });

  factory FoodDetailModel.fromJsonFood(Map<String, dynamic> docs, String id) {
    return FoodDetailModel(
      foodId: docs["foodId"],
      foodName: docs["foodName"],
      discription: docs["disc"],
      imageUrl: docs["imageUrl"],
      price: (docs["price"] as num).toDouble(),
      cookedTime: (docs["cookedTime"] as num).toDouble(),
      shortDisc: docs["shortDisc"],
      status: docs["status"],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "foodId": foodId,
      "foodName": foodName,
      "disc": discription,
      "imageUrl": imageUrl,
      "price": price,
      "cookedTime": cookedTime,
      "shortDisc": shortDisc,
    };
  }
}
