import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/services/cart_service.dart';
import 'package:the_tumeric_papplication/services/rating_service.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';
// Add your authentication service import here
// import 'package:the_tumeric_papplication/services/auth_service.dart';

class MainFoodDiscPage extends StatefulWidget {
  final String foodId;
  final String title;
  final String disc;
  final String imageUrl;
  final double price;
  final double time;

  const MainFoodDiscPage({
    super.key,
    required this.title,
    required this.disc,
    required this.imageUrl,
    required this.price,
    required this.time,
    required this.foodId,
  });

  @override
  State<MainFoodDiscPage> createState() => _MainFoodDiscPageState();
}

class _MainFoodDiscPageState extends State<MainFoodDiscPage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  int quantity = 1;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  // Rating display variables
  Map<String, dynamic>? ratingStats;
  List<Map<String, dynamic>>? userReviews;
  bool showAllReviews = false;
  bool isLoadingRatings = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();
    _loadRatingData();
  }

  // Method to check if user is logged in
  // Replace this with your actual authentication check
  bool _isUserLoggedIn() {
    // Example implementations:
    // return AuthService().isLoggedIn();
    // return FirebaseAuth.instance.currentUser != null;
    // return UserPreferences.isLoggedIn();

    // For now, return false to test the popup
    // Change this to your actual authentication check
    return false; // Replace with actual login check
  }

  // Method to show login dialog
  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.orange[50]!],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kMainOrange, kMainOrange.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kMainOrange.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Login Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kmainBlack,
                  ),
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  'Please login or sign up to add items to your cart and enjoy our delicious meals!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: kmainBlack.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    // Sign Up Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: kMainOrange, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to sign up page
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                            print('Navigate to Sign Up');
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: kMainOrange,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Login Button
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kMainOrange, kMainOrange.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kMainOrange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to login page
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                            print('Navigate to Login');
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Close Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadRatingData() async {
    try {
      final stats = await RatingService().getRatingStats(widget.foodId);
      final reviews = await RatingService().getRatingsFormenusItem(
        widget.foodId,
      );

      setState(() {
        ratingStats = stats;
        userReviews = reviews;
        isLoadingRatings = false;
      });
    } catch (e) {
      setState(() {
        isLoadingRatings = false;
      });
      print('Error loading rating data: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                title: Text(
                  widget.title,
                  style: TextStyle(
                    color: kmainBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
                leading: _buildCustomButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                actions: [
                  _buildCustomButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    onTap: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                    },
                    color: isFavorite ? kMainOrange : null,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.grey[50]!, Colors.white],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                      child: FadeTransition(
                        opacity: _animation,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: kmainBlack.withOpacity(0.15),
                                blurRadius: 5,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[300]!,
                                        Colors.grey[200]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.restaurant_menu_rounded,
                                      size: 64,
                                      color: kmainBlack.withOpacity(0.3),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Price Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: kmainBlack,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildTimeChip(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildPriceTag(),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Rating Overview Section
                          _buildRatingOverview(),
                          const SizedBox(height: 28),

                          // Description
                          _buildDescriptionSection(),
                          const SizedBox(height: 28),

                          // Quick Info Cards
                          _buildInfoCards(),
                          const SizedBox(height: 28),

                          // User Reviews Section
                          _buildUserReviewsSection(),
                          const SizedBox(height: 28),

                          // Rating Bar
                          _ratingBar(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Fixed quantity and add to cart at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(child: _buildQuantityAndCart()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOverview() {
    if (isLoadingRatings) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (ratingStats == null || ratingStats!['totalRatings'] == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.star_outline, color: Colors.grey[400], size: 24),
            const SizedBox(width: 12),
            Text(
              'No ratings yet ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final avgRating = ratingStats!['averageRating'] as double;
    final totalRatings = ratingStats!['totalRatings'] as int;
    final breakdown = ratingStats!['ratingBreakdown'] as Map<int, int>;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.orange[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left side - Average rating
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: kMainOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.star_rounded, color: kMainOrange, size: 32),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: avgRating,
                      itemCount: 5,
                      itemSize: 20,
                      unratedColor: Colors.grey[300],
                      itemBuilder:
                          (context, index) =>
                              Icon(Icons.star_rounded, color: kMainOrange),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalRatings ratings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side - Rating breakdown
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              '$i',
                              style: TextStyle(
                                fontSize: 12,
                                color: kmainBlack.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: kMainOrange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor:
                                      totalRatings > 0
                                          ? (breakdown[i] ?? 0) / totalRatings
                                          : 0,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: kMainOrange,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 20,
                              child: Text(
                                '${breakdown[i] ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kmainBlack.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserReviewsSection() {
    if (isLoadingRatings) {
      return const SizedBox.shrink();
    }

    if (userReviews == null || userReviews!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter reviews that have feedback
    final reviewsWithFeedback =
        userReviews!
            .where(
              (review) =>
                  review['feedback'] != null &&
                  review['feedback'].toString().trim().isNotEmpty,
            )
            .toList();

    if (reviewsWithFeedback.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayReviews =
        showAllReviews
            ? reviewsWithFeedback
            : reviewsWithFeedback.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rate_review_rounded, color: kMainOrange, size: 24),
            const SizedBox(width: 8),
            Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kmainBlack,
              ),
            ),
            const Spacer(),
            if (reviewsWithFeedback.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    showAllReviews = !showAllReviews;
                  });
                },
                child: Text(
                  showAllReviews
                      ? 'Show Less'
                      : 'View All (${reviewsWithFeedback.length})',
                  style: TextStyle(
                    color: kMainOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        ...displayReviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num).toDouble();
    final feedback = review['feedback'] as String;
    final userName = review['userName'] as String? ?? 'Anonymous';
    final timestamp = review['timestamp'];

    // Format timestamp
    String timeAgo = 'Recently';
    if (timestamp != null) {
      final reviewTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(reviewTime);

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes}m ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kMainOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kMainOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kmainBlack,
                      ),
                    ),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemCount: 5,
                          itemSize: 14,
                          unratedColor: Colors.grey[300],
                          itemBuilder:
                              (context, index) =>
                                  Icon(Icons.star_rounded, color: kMainOrange),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: kmainBlack.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: kmainBlack.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color ?? kmainBlack, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kMainOrange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kMainOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${widget.time.toInt()} min',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: kmainGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kmainGreen.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        '\$${widget.price.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_rounded, color: kMainOrange, size: 24),
            const SizedBox(width: 8),
            Text(
              'About this dish',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kmainBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.disc,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: kmainBlack.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ratingBar() {
    // Rating descriptions for better UX
    final Map<int, String> ratingDescriptions = {
      1: 'Poor',
      2: 'Fair',
      3: 'Good',
      4: 'Very Good',
      5: 'Excellent',
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.orange[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Your Experience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Help us improve our service',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Rating Stars
          Column(
            children: [
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 40,
                unratedColor: Colors.grey[300],
                glowColor: Colors.orange.withOpacity(0.3),
                itemPadding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      index < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color:
                          index < _rating
                              ? Colors.orange[600]
                              : Colors.grey[400],
                      size: 48,
                    ),
                  );
                },
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Rating Description
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _rating > 0
                        ? Container(
                          key: ValueKey(_rating),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange[300]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            ratingDescriptions[_rating.toInt()] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                        )
                        : Container(
                          key: const ValueKey('placeholder'),
                          height: 36,
                          child: Text(
                            'Tap a star to rate',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Feedback TextField
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Tell us about your experience... (Optional)',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(16),
                counterStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          StatefulBuilder(
            builder: (context, setButtonState) {
              bool isSubmitting = false;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _rating > 0
                          ? () async {
                            if (!isSubmitting) {
                              // Check if user is logged in before submitting rating
                              if (!_isUserLoggedIn()) {
                                // Show login dialog if not logged in
                                _showLoginDialog();
                                return;
                              }

                              setButtonState(() {
                                isSubmitting = true;
                              });

                              try {
                                await RatingService().submitRating(
                                  foodId: widget.foodId,
                                  rating: _rating,
                                  feedback: _feedbackController.text.trim(),
                                );

                                setButtonState(() {
                                  isSubmitting = false;
                                });

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 12),
                                        Text('Thank you for your feedback!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );

                                // Reset form and reload rating data
                                setState(() {
                                  _rating = 0;
                                  _feedbackController.clear();
                                });

                                // Reload rating data to show updated stats
                                _loadRatingData();
                              } catch (e) {
                                setButtonState(() {
                                  isSubmitting = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error submitting rating: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _rating > 0 ? Colors.orange[600] : Colors.grey[300],
                    foregroundColor: Colors.white,
                    elevation: _rating > 0 ? 8 : 0,
                    shadowColor: Colors.orange.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      isSubmitting
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Submitting...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _rating > 0
                                    ? 'Submit Rating'
                                    : 'Select Rating First',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    // Calculate rating statistics for display
    double ratingPercentage = 0.0;
    String totalRatingsText = '0';
    String averageRatingText = '0.0';

    if (ratingStats != null && ratingStats!['totalRatings'] > 0) {
      final avgRating = ratingStats!['averageRating'] as double;
      final totalRatings = ratingStats!['totalRatings'] as int;

      ratingPercentage = (avgRating / 5 * 100);
      totalRatingsText = totalRatings.toString();
      averageRatingText = avgRating.toStringAsFixed(1);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, kMainOrange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: kMainOrange.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kMainOrange, kMainOrange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kMainOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kmainBlack,
                      ),
                    ),
                    Text(
                      'Customer satisfaction metrics',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Rating Metrics Row
          Row(
            children: [
              // Average Rating
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kMainOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kMainOrange.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kMainOrange,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kMainOrange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        averageRatingText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kMainOrange,
                        ),
                      ),
                      Text(
                        'Average',
                        style: TextStyle(
                          fontSize: 9,
                          color: kmainBlack.withOpacity(0.6),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Total Ratings
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kmainGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kmainGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kmainGreen,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kmainGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        totalRatingsText,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: kmainGreen,
                        ),
                      ),
                      Text(
                        'Reviews',
                        style: TextStyle(
                          fontSize: 9,
                          color: kmainBlack.withOpacity(0.6),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Satisfaction Percentage
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kmainBlack.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kmainBlack.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kmainBlack,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kmainBlack.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.thumb_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ratingStats != null && ratingStats!['totalRatings'] > 0
                            ? '${ratingPercentage.round()}%'
                            : 'N/A',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kmainBlack,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Satisfied',
                        style: TextStyle(
                          fontSize: 9,
                          color: kmainBlack.withOpacity(0.6),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progress indicator for satisfaction
          if (ratingStats != null && ratingStats!['totalRatings'] > 0) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Satisfaction',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kmainBlack.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${ratingPercentage.round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kMainOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: ratingPercentage / 100,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kMainOrange, kMainOrange.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityAndCart() {
    return Row(
      children: [
        // Quantity Selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kMainOrange.withOpacity(0.2), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove_rounded,
                onTap: quantity > 1 ? () => setState(() => quantity--) : null,
                isActive: quantity > 1,
              ),
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kmainBlack,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add_rounded,
                onTap: () => setState(() => quantity++),
                isActive: true,
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Add to Cart Button - Expanded to fill remaining space
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kmainGreen, kmainGreen.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kmainGreen.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Check if user is logged in
                  if (!_isUserLoggedIn()) {
                    // Show login dialog if not logged in
                    _showLoginDialog();
                    return;
                  }

                  // If logged in, proceed with normal add to cart
                  CartService().addToCart(
                    context,
                    widget.foodId,
                    quantity: quantity,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Added \$${quantity}x ${widget.title} to cart!',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: kmainGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Add \$${(widget.price * quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isActive,
  }) {
    return Material(
      color: isActive ? kMainOrange : Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[400],
            size: 18,
          ),
        ),
      ),
    );
  }
}
