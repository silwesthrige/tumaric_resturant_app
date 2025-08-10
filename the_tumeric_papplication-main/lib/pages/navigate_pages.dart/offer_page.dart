import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:the_tumeric_papplication/services/promotion_services.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';
import 'package:the_tumeric_papplication/models/promotion_model.dart';

class OfferPageCard extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback? onClaimPressed;
  final bool isAlreadyClaimed;

  const OfferPageCard({
    super.key,
    required this.promotion,
    this.onClaimPressed,
    this.isAlreadyClaimed = false,
  });

  String _getDiscountText() {
    return promotion.discountText;
  }

  String _getOfferTitle() {
    return promotion.title.isNotEmpty
        ? promotion.title
        : '${promotion.promoType.toUpperCase()} Offer';
  }

  bool _isOfferAvailable() {
    return promotion.isAvailable &&
        !promotion.isExpired &&
        promotion.hasStarted;
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = _isOfferAvailable() && !isAlreadyClaimed;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kmainBlack.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image with Gradient Overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Image.network(
                    promotion.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 50,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kMainOrange,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          kmainBlack.withOpacity(0.3),
                          kmainBlack.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Disabled overlay if not available
                  if (!isAvailable)
                    Container(
                      color: kmainBlack.withOpacity(0.6),
                      child: Center(
                        child: Text(
                          isAlreadyClaimed
                              ? 'CLAIMED'
                              : promotion.isExpired
                              ? 'EXPIRED'
                              : !promotion.hasStarted
                              ? 'NOT STARTED'
                              : !promotion.isActive
                              ? 'INACTIVE'
                              : 'SOLD OUT',
                          style: TextStyle(
                            color: kmainWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Top Right Discount Badge
            Positioned(
              top: 12,
              right: 3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getDiscountText(),
                  style: TextStyle(
                    color: kmainWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // Top Left Fire Icon with Glow Effect
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kMainOrange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kMainOrange.withOpacity(0.5),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: kmainWhite,
                  size: 16,
                ),
              ),
            ),

            // Usage Counter (Top Center)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kmainBlack.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${promotion.remainingCount} left',
                    style: TextStyle(
                      color: kmainWhite,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Content Area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Offer Title
                    Text(
                      _getOfferTitle(),
                      style: TextStyle(
                        color: kmainWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: kmainBlack.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),

                    // Description if available
                    if (promotion.description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        promotion.description,
                        style: TextStyle(
                          color: kmainWhite.withOpacity(0.9),
                          fontSize: 10,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: kmainBlack.withOpacity(0.7),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: 8),

                    // Claim Offer Button
                    Center(
                      child: GestureDetector(
                        onTap: onClaimPressed,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 120,
                          height: 35,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isAvailable
                                      ? [
                                        kMainOrange,
                                        kMainOrange.withOpacity(0.8),
                                      ]
                                      : [
                                        Colors.grey,
                                        Colors.grey.withOpacity(0.8),
                                      ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow:
                                isAvailable
                                    ? [
                                      BoxShadow(
                                        color: kMainOrange.withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                        spreadRadius: 1,
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.card_giftcard_rounded
                                    : isAlreadyClaimed
                                    ? Icons.check_circle
                                    : Icons.block,
                                color: kmainWhite,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                isAvailable
                                    ? "Claim"
                                    : isAlreadyClaimed
                                    ? "Claimed"
                                    : "Unavailable",
                                style: TextStyle(
                                  color: kmainWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Ripple Effect
            if (isAvailable || !isAlreadyClaimed)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onClaimPressed,
                    splashColor: kMainOrange.withOpacity(0.2),
                    highlightColor: kMainOrange.withOpacity(0.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OfferPage extends StatefulWidget {
  const OfferPage({super.key});

  @override
  State<OfferPage> createState() => _OfferPageState();
}

class _OfferPageState extends State<OfferPage> {
  final PromotionServices _promotionServices = PromotionServices();
  List<String> _claimedOfferIds = [];
  bool _isLoadingClaim = false;

  @override
  void initState() {
    super.initState();
    _loadClaimedOffers();

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        _loadClaimedOffers(); // Reload claimed offers when auth state changes
      }
    });
  }

  Future<void> _loadClaimedOffers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading claimed offers for user: ${user.uid}');
        final claimedOffersStream = _promotionServices.getUserClaimedOffers(
          user.uid,
        );

        claimedOffersStream.listen(
          (claimedOffers) {
            print('Received ${claimedOffers.length} claimed offers');
            if (mounted) {
              setState(() {
                _claimedOfferIds =
                    claimedOffers.map((offer) => offer.promoId).toList();
              });
              print('Updated claimed offer IDs: $_claimedOfferIds');
            }
          },
          onError: (error) {
            print('Error in claimed offers stream: $error');
          },
        );
      } else {
        print('No user logged in, clearing claimed offers');
        if (mounted) {
          setState(() {
            _claimedOfferIds.clear();
          });
        }
      }
    } catch (e) {
      print('Error loading claimed offers: $e');
    }
  }

  // Show login/signup dialog when user is not logged in
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: kMainOrange),
              SizedBox(width: 8),
              Text('Login Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 64,
                color: kMainOrange.withOpacity(0.7),
              ),
              SizedBox(height: 16),
              Text(
                'Please login or create an account to claim exclusive offers and discounts!',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Join thousands of users enjoying amazing deals!',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      GoRouter.of(context).push("/auth/signup");
                      // Navigate to signup page
                      _navigateToAuth(context, isLogin: false);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: kMainOrange),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: kMainOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      GoRouter.of(context).push("/auth/signin");
                      // Navigate to login page
                      _navigateToAuth(context, isLogin: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainOrange,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: kmainWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _navigateToAuth(BuildContext context, {required bool isLogin}) {
    // TODO: Replace with your actual login/signup page navigation
    // Navigator.pushNamed(context, isLogin ? '/login' : '/signup');

    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLogin ? 'Navigate to Login Page' : 'Navigate to Sign Up Page',
        ),
        backgroundColor: kMainOrange,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Special Offers',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kmainBlack,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.card_giftcard, color: kMainOrange, size: 20),
            ),
            onPressed: () => _showMyOffersDialog(),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with description
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kMainOrange.withOpacity(0.1),
                        kmainGreen.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: kMainOrange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kMainOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_offer,
                          color: kMainOrange,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Limited Time Offers!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kmainBlack,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Claim exclusive deals and save on your orders',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                StreamBuilder<List<PromotionModel>>(
                  stream: _promotionServices.getPromo(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          children: [
                            SizedBox(height: 50),
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kMainOrange,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading offers...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return _buildErrorWidget(
                        "Error loading offers: ${snapshot.error}",
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyWidget();
                    } else {
                      final promotions = snapshot.data!;

                      // Separate active and inactive promotions
                      final activePromotions =
                          promotions
                              .where(
                                (promo) =>
                                    promo.isActive &&
                                    promo.hasStarted &&
                                    !promo.isExpired,
                              )
                              .toList();

                      final upcomingPromotions =
                          promotions
                              .where(
                                (promo) => promo.isActive && !promo.hasStarted,
                              )
                              .toList();

                      final expiredPromotions =
                          promotions
                              .where(
                                (promo) => !promo.isActive || promo.isExpired,
                              )
                              .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active Promotions
                          if (activePromotions.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Available Now',
                              activePromotions.length,
                              Icons.flash_on,
                              kMainOrange,
                            ),
                            SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12.0,
                                    mainAxisSpacing: 12.0,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: activePromotions.length,
                              itemBuilder: (context, index) {
                                final promo = activePromotions[index];
                                final isAlreadyClaimed = _claimedOfferIds
                                    .contains(promo.promoId);

                                return OfferPageCard(
                                  promotion: promo,
                                  isAlreadyClaimed: isAlreadyClaimed,
                                  onClaimPressed:
                                      () => _handleClaimOffer(context, promo),
                                );
                              },
                            ),
                          ],

                          // Upcoming Promotions
                          if (upcomingPromotions.isNotEmpty) ...[
                            SizedBox(height: 24),
                            _buildSectionHeader(
                              'Coming Soon',
                              upcomingPromotions.length,
                              Icons.schedule,
                              Colors.blue,
                            ),
                            SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12.0,
                                    mainAxisSpacing: 12.0,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: upcomingPromotions.length,
                              itemBuilder: (context, index) {
                                final promo = upcomingPromotions[index];
                                return OfferPageCard(
                                  promotion: promo,
                                  onClaimPressed: null,
                                );
                              },
                            ),
                          ],

                          // Expired Promotions
                          if (expiredPromotions.isNotEmpty) ...[
                            SizedBox(height: 24),
                            _buildSectionHeader(
                              'Expired Offers',
                              expiredPromotions.length,
                              Icons.history,
                              Colors.grey,
                            ),
                            SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12.0,
                                    mainAxisSpacing: 12.0,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: expiredPromotions.length,
                              itemBuilder: (context, index) {
                                final promo = expiredPromotions[index];
                                return OfferPageCard(
                                  promotion: promo,
                                  onClaimPressed: null,
                                );
                              },
                            ),
                          ],

                          if (activePromotions.isEmpty &&
                              upcomingPromotions.isEmpty &&
                              expiredPromotions.isEmpty)
                            _buildEmptyWidget(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          '$title ($count)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _handleClaimOffer(BuildContext context, PromotionModel promotion) async {
    // Check if user is authenticated first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog(context);
      return;
    }

    // Prevent multiple simultaneous claims
    if (_isLoadingClaim) {
      return;
    }

    // Check if already claimed
    if (_claimedOfferIds.contains(promotion.promoId)) {
      _showSnackBar(
        context,
        'You have already claimed this offer!',
        Colors.orange,
      );
      return;
    }

    // Double-check if user has claimed this offer from database
    try {
      bool hasAlreadyClaimed = await _promotionServices.hasUserClaimedOffer(
        user.uid,
        promotion.promoId,
      );
      if (hasAlreadyClaimed) {
        _showSnackBar(
          context,
          'You have already claimed this offer!',
          Colors.orange,
        );
        // Update local state
        setState(() {
          _claimedOfferIds.add(promotion.promoId);
        });
        return;
      }
    } catch (e) {
      _showSnackBar(context, 'Error checking offer status', Colors.red);
      return;
    }

    // Check if offer is still available
    if (!promotion.isAvailable) {
      _showSnackBar(
        context,
        'Sorry, this offer is no longer available!',
        Colors.red,
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.card_giftcard, color: kMainOrange),
              SizedBox(width: 8),
              Text('Claim Offer'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to claim this offer?'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kMainOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kMainOrange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.title.isNotEmpty
                          ? promotion.title
                          : 'Special Offer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kmainBlack,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Discount: ${promotion.discountText}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kMainOrange,
                        fontSize: 14,
                      ),
                    ),
                    if (promotion.description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        promotion.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                    if (promotion.minimumOrderAmount != null) ...[
                      SizedBox(height: 4),
                      Text(
                        'Min. order: \$${promotion.minimumOrderAmount!.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed:
                  _isLoadingClaim
                      ? null
                      : () {
                        Navigator.of(context).pop();
                        _processOfferClaim(context, promotion);
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Claim Now', style: TextStyle(color: kmainWhite)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processOfferClaim(
    BuildContext context,
    PromotionModel promotion,
  ) async {
    if (_isLoadingClaim) return; // Prevent double claims

    setState(() {
      _isLoadingClaim = true;
    });

    // Show loading dialog
    bool isLoadingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kMainOrange),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Claiming your offer...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
    ).then((_) {
      isLoadingDialogShown = false;
    });

    try {
      // Final check before claiming
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please login to claim offers');
      }

      // Double-check if user has already claimed
      bool hasAlreadyClaimed = await _promotionServices.hasUserClaimedOffer(
        user.uid,
        promotion.promoId,
      );
      if (hasAlreadyClaimed) {
        throw Exception('You have already claimed this offer');
      }

      // Claim the offer using PromotionServices
      ClaimedOffer? claimedOffer = await _promotionServices.claimOffer(
        promotion,
      );

      // Close loading dialog if still showing
      if (isLoadingDialogShown && Navigator.canPop(context)) {
        Navigator.of(context).pop();
        isLoadingDialogShown = false;
      }

      if (claimedOffer != null) {
        // Update local claimed offers list
        setState(() {
          _claimedOfferIds.add(promotion.promoId);
        });

        // Show success dialog
        _showSuccessDialog(context, claimedOffer);
      } else {
        throw Exception('Failed to claim offer. Please try again.');
      }
    } catch (e) {
      // Make sure to close loading dialog
      if (isLoadingDialogShown && Navigator.canPop(context)) {
        Navigator.of(context).pop();
        isLoadingDialogShown = false;
      }

      // Show error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      _showSnackBar(context, errorMessage, Colors.red);
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoadingClaim = false;
        });
      }
    }
  }

  void _showSuccessDialog(BuildContext context, ClaimedOffer claimedOffer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 48,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Offer Claimed Successfully!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kMainOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kMainOrange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          claimedOffer.discountText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kMainOrange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Expires in ${claimedOffer.daysUntilExpiry} days',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your offer has been added to your account. Use it during checkout to get the discount!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Awesome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showMyOffersDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog(context);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.card_giftcard, color: kMainOrange),
                    SizedBox(width: 8),
                    Text(
                      'My Claimed Offers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<ClaimedOffer>>(
                    stream: _promotionServices.getUserClaimedOffers(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kMainOrange,
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading offers',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No claimed offers yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Claim some offers to see them here!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final claimedOffers = snapshot.data!;
                        final activeOffers =
                            claimedOffers
                                .where((offer) => offer.isActive)
                                .toList();
                        final expiredOffers =
                            claimedOffers
                                .where((offer) => !offer.isActive)
                                .toList();

                        return ListView(
                          children: [
                            if (activeOffers.isNotEmpty) ...[
                              Text(
                                'Active Offers (${activeOffers.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              ...activeOffers.map(
                                (offer) => _buildClaimedOfferCard(offer, true),
                              ),
                            ],
                            if (expiredOffers.isNotEmpty) ...[
                              if (activeOffers.isNotEmpty) SizedBox(height: 16),
                              Text(
                                'Expired/Used Offers (${expiredOffers.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              ...expiredOffers.map(
                                (offer) => _buildClaimedOfferCard(offer, false),
                              ),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimedOfferCard(ClaimedOffer offer, bool isActive) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? kMainOrange.withOpacity(0.3) : Colors.grey[300]!,
        ),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.discountText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? kMainOrange.withOpacity(0.1)
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive
                      ? 'ACTIVE'
                      : offer.isUsed
                      ? 'USED'
                      : 'EXPIRED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? kMainOrange : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Promo ID: ${offer.promoId}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 4),
          Text(
            isActive
                ? 'Expires in ${offer.daysUntilExpiry} days'
                : offer.isUsed
                ? 'Used on ${offer.usedAt?.day}/${offer.usedAt?.month}/${offer.usedAt?.year}'
                : 'Expired',
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.green[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 64,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainOrange,
                foregroundColor: kmainWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.local_offer_outlined,
                color: Colors.grey[400],
                size: 80,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Offers Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Check back later for exciting deals and promotions!',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kMainOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: kMainOrange.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: kMainOrange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'We\'ll notify you when new offers arrive!',
                    style: TextStyle(
                      color: kMainOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
