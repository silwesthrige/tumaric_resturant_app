import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/pages/main_food_disc_page.dart';
import 'package:the_tumeric_papplication/services/food_services.dart';
import 'package:the_tumeric_papplication/services/catogary_service.dart';
import 'package:the_tumeric_papplication/models/catogary_model.dart';
import 'package:the_tumeric_papplication/widgets/main_food_card.dart';

class ListOfCatogaryPage extends StatefulWidget {
  final String catogaryId;
  final String? catogaryName; // Optional category name for display

  const ListOfCatogaryPage({
    super.key,
    required this.catogaryId,
    this.catogaryName,
  });

  @override
  State<ListOfCatogaryPage> createState() => _ListOfCatogaryPageState();
}

class _ListOfCatogaryPageState extends State<ListOfCatogaryPage> {
  final FoodServices _foodServices = FoodServices();
  final CatogaryService _categoryService = CatogaryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.catogaryName ?? "Category Foods",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3192),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E3192)),
      ),
      body: SingleChildScrollView(
        child: Column(children: [_buildFoodSection()]),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodGrid(List foods, List<String> categoryFoodIds) {
    // Filter foods that belong to this category and are available
    final categoryFoods =
        foods
            .where(
              (food) =>
                  categoryFoodIds.contains(food.foodId) &&
                  food.status == 'available',
            )
            .toList();

    if (categoryFoods.isEmpty) {
      return _buildEmptyWidget();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categoryFoods.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final food = categoryFoods[index];

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          child: Hero(
            tag: "food_${food.foodName}_${food.foodId}_$index",
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: MainFoodCard(
                food: food,
                title: food.foodName,
                imageUrl: food.imageUrl,
                price: food.price,
                ontap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              MainFoodDiscPage(
                                foodId: food.foodId,
                                title: food.foodName,
                                disc: food.discription,
                                imageUrl: food.imageUrl,
                                price: food.price,
                                time: food.cookedTime,
                              ),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: Curves.ease)),
                          ),
                          child: child,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No dishes in this category yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for new additions!",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "🍽️ ${widget.catogaryName ?? 'Category'} Dishes",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3192),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Use StreamBuilder to get category data first, then foods
          StreamBuilder<List<CatogaryModel>>(
            stream: _categoryService.getCatogary(),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingGrid();
              } else if (categorySnapshot.hasError) {
                return _buildErrorWidget(
                  "Error loading category: ${categorySnapshot.error}",
                );
              } else if (!categorySnapshot.hasData ||
                  categorySnapshot.data!.isEmpty) {
                return _buildErrorWidget("Category not found");
              } else {
                // Find the specific category by catogaryId
                final categories = categorySnapshot.data!;
                final currentCategory = categories.firstWhere(
                  (cat) => cat.catogaryId == widget.catogaryId,
                  orElse: () => categories.first, // Fallback to first category
                );

                // Now get foods and filter by category foodIds
                return StreamBuilder(
                  stream: _foodServices.getFood(),
                  builder: (context, foodSnapshot) {
                    if (foodSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingGrid();
                    } else if (foodSnapshot.hasError) {
                      return _buildErrorWidget(
                        "Error loading foods: ${foodSnapshot.error}",
                      );
                    } else if (!foodSnapshot.hasData ||
                        foodSnapshot.data!.isEmpty) {
                      return _buildErrorWidget("No dishes available");
                    } else {
                      final foods = foodSnapshot.data!;
                      return _buildFoodGrid(foods, currentCategory.foodIds);
                    }
                  },
                );
              }
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
