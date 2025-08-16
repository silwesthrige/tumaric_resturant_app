import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/food_detail_model.dart';
import 'package:the_tumeric_papplication/services/cart_service.dart';

class MainFoodCard extends StatefulWidget {
  final FoodDetailModel food;
  final String title;
  final String imageUrl;
  final double price;
  final VoidCallback? ontap;

  const MainFoodCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.ontap,
    required this.food,
  });

  @override
  State<MainFoodCard> createState() => _MainFoodCardState();
}

class _MainFoodCardState extends State<MainFoodCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool isFavorite = false;
  bool isInCart = false;
  bool isLoading = false;
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    // Add observer to listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Debug: Print food data when card initializes
    print('🍽️ MainFoodCard initialized with:');
    print('   - Food ID: "${widget.food.foodId}"');
    print('   - Food Name: "${widget.food.foodName}"');
    print('   - Title: "${widget.title}"');
    print('   - Price: ${widget.price}');

    // Check cart status when widget initializes
    _checkCartStatus();
  }

  @override
  void dispose() {
    // Remove observer when disposing
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  // This method is called when the app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh cart status when app comes back to foreground
      _checkCartStatus();
    }
  }

  // Also override didChangeDependencies to refresh when returning from navigation
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkCartStatus();
  }

  // Check if item is in cart from Firestore
  Future<void> _checkCartStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      print('🛒 Checking cart status:');
      print('   - User ID: $uid');
      print('   - Food ID: "${widget.food.foodId}"');

      if (uid != null &&
          widget.food.foodId != null &&
          widget.food.foodId!.isNotEmpty) {
        final inCart = await _cartService.isInCart(uid, widget.food.foodId!);
        print('   - In cart: $inCart');

        if (mounted) {
          setState(() {
            isInCart = inCart;
          });
        }
      } else {
        print('   - Cannot check cart: Missing UID or Food ID');
      }
    } catch (e) {
      print('❌ Error checking cart status: $e');
    }
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Check if we have required data
    if (widget.food.foodId == null || widget.food.foodId!.isEmpty) {
      print('⚠️ WARNING: MainFoodCard has null or empty foodId!');
      print('   Food data: ${widget.food.toJson()}');
    }

    return GestureDetector(
      onTap: widget.ontap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 175,
          height: 250,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFFFBF0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container with Favorite Badge
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFF6B35).withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFFF6B35),
                                        ),
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Favorite Button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isFavorite = !isFavorite;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  isFavorite
                                      ? const Color(0xFFFF6B35)
                                      : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "£",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.price.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add to Cart Button
                    GestureDetector(
                      onTap:
                          isLoading
                              ? null
                              : () async {
                                print('🛒 Cart button tapped');

                                // Better check: Ensure we have valid foodId
                                if (widget.food.foodId == null ||
                                    widget.food.foodId!.trim().isEmpty) {
                                  print(
                                    '❌ Cannot add to cart: Invalid food ID',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error: Invalid food item'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) {
                                  print(
                                    '❌ Cannot add to cart: User not logged in',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please log in to add items to cart',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  final foodId = widget.food.foodId!.trim();
                                  print(
                                    '🛒 ${isInCart ? "Removing from" : "Adding to"} cart: $foodId',
                                  );

                                  if (isInCart) {
                                    await _cartService.removeFromCart(
                                      context,
                                      foodId,
                                    );
                                  } else {
                                    await _cartService.addToCart(
                                      context,
                                      foodId,
                                    );
                                  }

                                  setState(() {
                                    isInCart = !isInCart;
                                  });

                                  print('✅ Cart operation successful');

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isInCart
                                            ? '${widget.title} added to cart'
                                            : '${widget.title} removed from cart',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  print('❌ Error updating cart: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  // Refresh cart status on error
                                  await _checkCartStatus();
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isInCart
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF2E3192).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:
                              isInCart
                                  ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : [],
                        ),
                        child:
                            isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isInCart
                                          ? Colors.white
                                          : const Color(0xFF2E3192),
                                    ),
                                  ),
                                )
                                : Icon(
                                  isInCart
                                      ? Icons.shopping_cart
                                      : Icons.add_shopping_cart,
                                  color:
                                      isInCart
                                          ? Colors.white
                                          : const Color(0xFF2E3192),
                                  size: 20,
                                ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
