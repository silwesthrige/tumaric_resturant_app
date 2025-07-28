class CatogaryModel {
  final String catogaryName;
  final List<String> foodIds;
  final String imageUrl;
  final String catogaryId;

  CatogaryModel({
    required this.catogaryId,
    required this.imageUrl,
    required this.catogaryName,
    required this.foodIds,
  });

  factory CatogaryModel.fromJsonCatogary(Map<String, dynamic> docs, String id) {
    return CatogaryModel(
      catogaryName: docs['categoryName'] ?? '',
      foodIds: docs['FoodId'] != null ? List<String>.from(docs['FoodId']) : [],
      imageUrl: docs['imageUrl'] ?? '',
      catogaryId:
          docs['categoryId'] ??
          id, // Use from docs or fallback to the passed id
    );
  }
}
