import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/food_detail_model.dart';
import 'package:the_tumeric_papplication/pages/main_food_disc_page.dart';
import 'package:the_tumeric_papplication/services/food_services.dart';
import 'package:the_tumeric_papplication/services/rating_service.dart';
import 'package:the_tumeric_papplication/widgets/main_food_card.dart';

class AllFoodsPage extends StatefulWidget {
  const AllFoodsPage({super.key});

  @override
  State<AllFoodsPage> createState() => _AllFoodsPageState();
}

class _AllFoodsPageState extends State<AllFoodsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FoodServices _foodServices = FoodServices();
  final RatingService _ratingService = RatingService();

  String _sortBy = 'name'; // 'name', 'rating', 'price_low', 'price_high'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchAndFilter(),
              Expanded(child: _buildFoodsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Foods",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Discover all our delicious dishes",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search for foods...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter/Sort Options
          Row(
            children: [
              const Text(
                "Sort by:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3192),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip("Name", "name"),
                      _buildSortChip("Rating", "rating"),
                      _buildSortChip("Price ↑", "price_low"),
                      _buildSortChip("Price ↓", "price_high"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodsList() {
    return StreamBuilder<List<FoodDetailModel>>(
      stream: _foodServices.getFood(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        } else if (snapshot.hasError) {
          return _buildErrorWidget("Error: ${snapshot.error}");
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildErrorWidget("No foods available");
        } else {
          final allFoods = snapshot.data!;
          final availableFoods =
              allFoods.where((food) => food.status == 'available').toList();

          // Apply search filter
          final filteredFoods =
              availableFoods.where((food) {
                return food.foodName!.toLowerCase().contains(_searchQuery) ||
                    food.discription!.toLowerCase().contains(_searchQuery);
              }).toList();

          if (filteredFoods.isEmpty && _searchQuery.isNotEmpty) {
            return _buildNoResultsWidget();
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getSortedFoodsWithRatings(filteredFoods),
            builder: (context, ratingsSnapshot) {
              if (ratingsSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingGrid();
              } else if (ratingsSnapshot.hasError) {
                // Fallback to original list without ratings
                return _buildSimpleFoodGrid(filteredFoods);
              } else {
                final sortedFoods = ratingsSnapshot.data ?? [];
                return _buildEnhancedFoodGrid(sortedFoods);
              }
            },
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getSortedFoodsWithRatings(
    List<FoodDetailModel> foods,
  ) async {
    try {
      // Get food IDs
      final foodIds =
          foods
              .where((food) => food.foodId != null)
              .map((food) => food.foodId!)
              .toList();

      // Get ratings for all foods
      final ratingsMap = await _ratingService.getMultipleFoodRatings(foodIds);

      // Combine food data with ratings
      List<Map<String, dynamic>> foodsWithRatings =
          foods.map((food) {
            final ratingData =
                ratingsMap[food.foodId] ??
                {
                  'averageRating': 0.0,
                  'totalRatings': 0,
                  'ratingBreakdown': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
                };

            return {
              'food': food,
              'averageRating': ratingData['averageRating'],
              'totalRatings': ratingData['totalRatings'],
              'ratingBreakdown': ratingData['ratingBreakdown'],
            };
          }).toList();

      // Sort based on selected criteria
      switch (_sortBy) {
        case 'rating':
          foodsWithRatings.sort((a, b) {
            final aRating = a['averageRating'] as double;
            final bRating = b['averageRating'] as double;
            // Sort by rating desc, then by total ratings desc
            if (aRating != bRating) {
              return bRating.compareTo(aRating);
            }
            return (b['totalRatings'] as int).compareTo(
              a['totalRatings'] as int,
            );
          });
          break;
        case 'price_low':
          foodsWithRatings.sort((a, b) {
            final aPrice = (a['food'] as FoodDetailModel).price;
            final bPrice = (b['food'] as FoodDetailModel).price;
            return aPrice!.compareTo(bPrice!);
          });
          break;
        case 'price_high':
          foodsWithRatings.sort((a, b) {
            final aPrice = (a['food'] as FoodDetailModel).price;
            final bPrice = (b['food'] as FoodDetailModel).price;
            return bPrice!.compareTo(aPrice!);
          });
          break;
        case 'name':
        default:
          foodsWithRatings.sort((a, b) {
            final aName = (a['food'] as FoodDetailModel).foodName;
            final bName = (b['food'] as FoodDetailModel).foodName;
            return aName!.compareTo(bName!);
          });
          break;
      }

      return foodsWithRatings;
    } catch (e) {
      print("Error getting ratings: $e");
      // Return foods without ratings as fallback
      return foods
          .map(
            (food) => {
              'food': food,
              'averageRating': 0.0,
              'totalRatings': 0,
              'ratingBreakdown': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
            },
          )
          .toList();
    }
  }

  Widget _buildEnhancedFoodGrid(List<Map<String, dynamic>> foodsWithRatings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: foodsWithRatings.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final item = foodsWithRatings[index];
          final food = item['food'] as FoodDetailModel;
          final averageRating = item['averageRating'] as double;
          final totalRatings = item['totalRatings'] as int;

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: Hero(
              tag: "food_${food.foodName}_$index",
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
                  title: food.foodName!,
                  imageUrl: food.imageUrl!,
                  price: food.price!,
                  ontap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                MainFoodDiscPage(
                                  foodId: food.foodId.toString(),
                                  title: food.foodName!,
                                  disc: food.discription!,
                                  imageUrl: food.imageUrl!,
                                  price: food.price!,
                                  time: food.cookedTime!,
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
      ),
    );
  }

  Widget _buildSimpleFoodGrid(List<FoodDetailModel> foods) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: foods.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final food = foods[index];

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: Hero(
              tag: "food_${food.foodName}_$index",
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
                  title: food.foodName!,
                  imageUrl: food.imageUrl!,
                  price: food.price!,
                  ontap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                MainFoodDiscPage(
                                  foodId: food.foodId.toString(),
                                  title: food.foodName!,
                                  disc: food.discription!,
                                  imageUrl: food.imageUrl!,
                                  price: food.price!,
                                  time: food.cookedTime!,
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
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        itemCount: 8,
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
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Trigger rebuild
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          Text(
            "No results found for '$_searchQuery'",
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Try searching with different keywords",
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text("Clear Search"),
          ),
        ],
      ),
    );
  }
}
