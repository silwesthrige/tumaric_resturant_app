import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:the_tumeric_papplication/models/promotion_model.dart';
import 'package:the_tumeric_papplication/services/promotion_services.dart';

class PromotionCard extends StatefulWidget {
  const PromotionCard({super.key});

  @override
  State<PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<PromotionCard> {
  final PageController _pageController = PageController();
  final PromotionServices _promotionServices = PromotionServices();
  int _currentPage = 0;
  List<PromotionModel>? _cachedPromotions;
  bool _isInitialized = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PromotionModel>>(
      stream: _promotionServices.getActivePromo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialized) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        final promotions = snapshot.data ?? [];

        if (promotions.isEmpty) {
          return _buildEmptyCard();
        }

        // Only update if data actually changed or first time
        if (_cachedPromotions == null ||
            _cachedPromotions!.length != promotions.length ||
            !_isInitialized) {
          _cachedPromotions = promotions;
          _isInitialized = true;
        }

        return _buildPromotionSlider(_cachedPromotions!);
      },
    );
  }

  Widget _buildPromotionSlider(List<PromotionModel> promotions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  return _buildPromotionSlide(promotions[index]);
                },
              ),
            ),
          ),

          if (promotions.length > 1) ...[
            const SizedBox(height: 12),
            SmoothPageIndicator(
              controller: _pageController,
              count: promotions.length,
              effect: const ExpandingDotsEffect(
                activeDotColor: Colors.orange,
                dotColor: Colors.grey,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 2,
                spacing: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromotionSlide(PromotionModel promotion) {
    return GestureDetector(
      onTap: () => _navigateToOfferPage(promotion),
      child: Container(
        width: double.infinity,
        height: 200,
        child:
            promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty
                ? Image.network(
                  promotion.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                        ),
                      ),
                    );
                  },
                )
                : Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.grey, size: 50),
                  ),
                ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.shade50,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Failed to load promotions',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text(
              'No Active Promotions',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOfferPage(PromotionModel promotion) {
    try {} catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open offer details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
