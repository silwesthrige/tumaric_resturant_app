// STEP 1: COMPLETELY SAFE FoodDetailModel
class FoodDetailModel {
  final String foodName;
  final String discription;
  final String shortDisc;
  final String imageUrl;
  final double price;
  final double cookedTime;
  final String foodId;
  final String status;

  FoodDetailModel({
    required this.foodId,
    required this.foodName,
    required this.discription,
    required this.imageUrl,
    required this.price,
    required this.cookedTime,
    required this.shortDisc,
    required this.status,
  });

  factory FoodDetailModel.fromJsonFood(Map<String, dynamic> docs, String id) {
    print('=== DEBUGGING DOCUMENT $id ===');
    print('Raw document data: $docs');
    print('Document keys: ${docs.keys.toList()}');
    
    // Check each field individually
    print('foodId: ${docs["foodId"]} (type: ${docs["foodId"].runtimeType})');
    print('foodName: ${docs["foodName"]} (type: ${docs["foodName"].runtimeType})');
    print('disc: ${docs["disc"]} (type: ${docs["disc"].runtimeType})');
    print('imageUrl: ${docs["imageUrl"]} (type: ${docs["imageUrl"].runtimeType})');
    print('price: ${docs["price"]} (type: ${docs["price"].runtimeType})');
    print('cookedTime: ${docs["cookedTime"]} (type: ${docs["cookedTime"].runtimeType})');
    print('shortDisc: ${docs["shortDisc"]} (type: ${docs["shortDisc"].runtimeType})');
    print('status: ${docs["status"]} (type: ${docs["status"].runtimeType})');
    
    try {
      // Safe conversion with detailed error checking
      String safeFoodName = _getSafeString(docs["foodName"], "Unknown Food");
      String safeDescription = _getSafeString(docs["disc"], "No description");
      String safeImageUrl = _getSafeString(docs["imageUrl"], "");
      String safeShortDisc = _getSafeString(docs["shortDisc"], "No description");
      String safeStatus = _getSafeString(docs["status"], "available");
      String safeFoodId = _getSafeString(docs["foodId"], id);
      
      double safePrice = _getSafeDouble(docs["price"], 0.0);
      double safeCookedTime = _getSafeDouble(docs["cookedTime"], 0.0);
      
      print('All conversions successful for document $id');
      
      return FoodDetailModel(
        foodId: safeFoodId,
        foodName: safeFoodName,
        discription: safeDescription,
        imageUrl: safeImageUrl,
        price: safePrice,
        cookedTime: safeCookedTime,
        shortDisc: safeShortDisc,
        status: safeStatus,
      );
    } catch (e) {
      print('ERROR in fromJsonFood for document $id: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static String _getSafeString(dynamic value, String defaultValue) {
    if (value == null) {
      print('String value is null, using default: $defaultValue');
      return defaultValue;
    }
    if (value is String) {
      return value;
    }
    print('String value is not a string (${value.runtimeType}), converting: $value');
    return value.toString();
  }

  static double _getSafeDouble(dynamic value, double defaultValue) {
    if (value == null) {
      print('Double value is null, using default: $defaultValue');
      return defaultValue;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Could not parse string "$value" as double, using default: $defaultValue');
        return defaultValue;
      }
    }
    print('Double value is unknown type (${value.runtimeType}): $value, using default: $defaultValue');
    return defaultValue;
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
      "status": status,
    };
  }
}