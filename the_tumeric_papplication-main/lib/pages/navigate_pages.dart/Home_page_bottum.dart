import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/catogary_model.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/models/food_detail_model.dart';

import 'package:the_tumeric_papplication/pages/main_food_disc_page.dart';

import 'package:the_tumeric_papplication/pages/navigate_pages.dart/food%20page/all_food_page.dart';
import 'package:the_tumeric_papplication/reuse_component/pramotion_card.dart';
import 'package:the_tumeric_papplication/services/catogary_service.dart';
import 'package:the_tumeric_papplication/services/food_services.dart';
import 'package:the_tumeric_papplication/services/user_services.dart';
import 'package:the_tumeric_papplication/services/rating_service.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

import 'package:the_tumeric_papplication/widgets/main_food_card.dart';
import 'package:the_tumeric_papplication/widgets/mini_card_list_view.dart';
import 'package:the_tumeric_papplication/widgets/search_bar.dart';

class HomePageBottum extends StatefulWidget {
  const HomePageBottum({super.key});

  @override
  State<HomePageBottum> createState() => _HomePageBottumState();
}

class _HomePageBottumState extends State<HomePageBottum>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<FoodDetailModel> _allFoods = [];
  List<FoodDetailModel> _filteredFoods = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    fetchUserData();
    _setupSearchListener();
    _loadAllFoods();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _isSearching = _searchQuery.isNotEmpty;
        if (_isSearching) {
          _filterFoods(_searchQuery);
        }
      });
    });
  }

  void _loadAllFoods() async {
    try {
      final foodServices = FoodServices();
      foodServices.getFood().listen((foods) {
        setState(() {
          _allFoods =
              foods.where((food) => food.status == 'available').toList();
        });
      });
    } catch (e) {
      print("Error loading foods: $e");
    }
  }

  void _filterFoods(String query) {
    if (query.isEmpty) {
      _filteredFoods = [];
      return;
    }

    _filteredFoods =
        _allFoods.where((food) {
          return food.foodName.toLowerCase().contains(query.toLowerCase()) ||
              food.discription.toLowerCase().contains(query.toLowerCase()) ||
              food.shortDisc.toLowerCase().contains(query.toLowerCase());
        }).toList();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
      _filteredFoods = [];
    });
    _searchFocusNode.unfocus();
  }

  // Dynamic greeting based on time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour >= 5 && hour < 12) {
      greeting = "Good Morning";
      emoji = "🌅";
    } else if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
      emoji = "☀️";
    } else if (hour >= 17 && hour < 21) {
      greeting = "Good Evening";
      emoji = "🌆";
    } else {
      greeting = "Good Night";
      emoji = "🌙";
    }

    return "$greeting! $emoji";
  }

  String _getGreetingSubtext() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Ready to start your day with delicious food?";
    } else if (hour >= 12 && hour < 17) {
      return "Time for a delightful lunch break!";
    } else if (hour >= 17 && hour < 21) {
      return "What's for dinner tonight?";
    } else {
      return "Craving a late night snack?";
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  final UserServices _userServices = UserServices();
  final RatingService _ratingService = RatingService();
  UserModel? currentUser;
  bool isLoading = true;

  String? _userAddress;
  void _loadUserDetails() async {
    final user = await UserServices().getCurrentUserDetails();
    if (user != null && mounted) {
      setState(() {
        _userAddress = user.address;
      });
    }
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final userStream = _userServices.getCurrentUserDetails();
      currentUser = await userStream;
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodServices = FoodServices();
    final catogaryService = CatogaryService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  _buildWelcomeHeader(),

                  // Search Bar Section
                  _buildSearchSection(),

                  // Show search results or normal content
                  if (_isSearching && _searchQuery.isNotEmpty)
                    _buildSearchResults()
                  else ...[
                    // Normal content when not searching
                    _buildPromotionsSection(),
                    _buildCategoriesSection(),
                    _buildPopularSection(foodServices),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 80,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4A300), Color(0xFFFFD166)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.menu, color: Colors.white),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4A300), Color(0xFFFFD166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kmainWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getGreetingSubtext(),
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userAddress ?? "Loading address...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: "Search for delicious food...",
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFFFF6B35),
              size: 24,
            ),
            suffixIcon:
                _isSearching
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: _clearSearch,
                    )
                    : const Icon(Icons.tune, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _filterFoods(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredFoods.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "No dishes found for '$_searchQuery'",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try searching with different keywords",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "🔍 Search Results (${_filteredFoods.length} found)",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3192),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredFoods.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final food = _filteredFoods[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
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
                                  foodId: food.foodId.toString(),
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
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPromotionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "🔥 Special Offers",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kMainOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "Limited Time",
                  style: TextStyle(
                    color: kMainOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PromotionCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🍽️ Categories",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: StreamBuilder<List<CatogaryModel>>(
              stream: CatogaryService().getCatogary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6B35),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return _buildErrorWidget("Error: ${snapshot.error}");
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildErrorWidget("No categories available");
                } else {
                  final categories = snapshot.data!;
                  return MiniCardListView(catogarys: categories);
                }
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Helper method for error display
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSection(FoodServices foodServices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "⭐ Popular Dishes",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllFoodsPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kMainOrange, Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "See More",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Use FutureBuilder to get top rated items, but use MainFoodCard for display
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _ratingService.getTopRatedmenusItems(limit: 6),
            builder: (context, ratingSnapshot) {
              if (ratingSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingGrid();
              } else if (ratingSnapshot.hasError) {
                // Fallback to regular food stream if rating service fails
                return _buildFallbackFoodGrid(foodServices);
              } else if (!ratingSnapshot.hasData ||
                  ratingSnapshot.data!.isEmpty) {
                // Fallback to regular food stream if no rated items
                return _buildFallbackFoodGrid(foodServices);
              } else {
                final topRatedItems = ratingSnapshot.data!;
                return _buildTopRatedFoodGridWithMainFoodCard(topRatedItems);
              }
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Build grid for top rated items using MainFoodCard with rating badge overlay
  Widget _buildTopRatedFoodGridWithMainFoodCard(
    List<Map<String, dynamic>> topRatedItems,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topRatedItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final foodData = topRatedItems[index];

        // Convert the rating data to FoodDetailModel
        final foodModel = FoodDetailModel(
          foodId: foodData['id'] ?? '',
          foodName: foodData['foodName'] ?? 'Unknown',
          discription: foodData['discription'] ?? '',
          imageUrl: foodData['imageUrl'] ?? '',
          price: ((foodData['price'] as num).toDouble() ?? 0.0),
          cookedTime: (foodData['cookedTime'] as num).toDouble() ?? 0,
          status: 'available',
          shortDisc: foodData['shortDisc'] ?? '',
        );

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutBack,
          child: Stack(
            children: [
              // MainFoodCard
              MainFoodCard(
                food: foodModel,
                title: foodModel.foodName,
                imageUrl: foodModel.imageUrl,
                price: foodModel.price,
                ontap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              MainFoodDiscPage(
                                foodId: foodModel.foodId.toString(),
                                title: foodModel.foodName,
                                disc: foodModel.discription,
                                imageUrl: foodModel.imageUrl,
                                price: foodModel.price,
                                time: foodModel.cookedTime,
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

              // Rating Badge Overlay
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        "${(foodData['averageRating'] ?? 0.0).toStringAsFixed(1)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Review count badge (if available)
              if ((foodData['totalRatings'] ?? 0) > 0)
                Positioned(
                  top: 35,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      "${foodData['totalRatings']}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Fallback grid using regular food stream with MainFoodCard
  Widget _buildFallbackFoodGrid(FoodServices foodServices) {
    return StreamBuilder<List<FoodDetailModel>>(
      stream: foodServices.getFood(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid();
        } else if (snapshot.hasError) {
          return _buildErrorWidget("Error: ${snapshot.error}");
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildErrorWidget("No dishes available");
        } else {
          final foods = snapshot.data!;
          final availableFoods =
              foods.where((food) => food.status == 'available').toList();
          final displayFoods =
              availableFoods.length > 6
                  ? availableFoods.take(6).toList()
                  : availableFoods;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayFoods.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final food = displayFoods[index];

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                child: Hero(
                  tag: "food_${food.foodName}_$index",
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
                                    foodId: food.foodId.toString(),
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
              );
            },
          );
        }
      },
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
}
