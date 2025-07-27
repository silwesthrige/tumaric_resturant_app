import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/services/cart_service.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
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
                  padding: const EdgeInsets.all(28),
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

                      const SizedBox(height: 32),

                      const SizedBox(height: 28),

                      // Description
                      _buildDescriptionSection(),

                      const SizedBox(height: 28),

                      // Quick Info Cards
                      _buildInfoCards(),

                      const SizedBox(height: 32),

                      // Quantity & Add to Cart
                      _buildQuantityAndCart(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
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

  Widget _buildInfoCards() {
    final List<Map<String, dynamic>> infoData = [
      {
        'icon': Icons.local_fire_department_rounded,
        'title': '245',
        'subtitle': 'Calories',
        'color': kMainOrange,
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': '1-2',
        'subtitle': 'Servings',
        'color': kmainGreen,
      },
      {
        'icon': Icons.thumb_up_rounded,
        'title': '95%',
        'subtitle': 'Liked',
        'color': kmainBlack,
      },
    ];

    return Row(
      children:
          infoData.map((info) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (info['color'] as Color).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: (info['color'] as Color).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: info['color'],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (info['color'] as Color).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(info['icon'], color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: info['color'],
                      ),
                    ),
                    Text(
                      info['subtitle'],
                      style: TextStyle(
                        fontSize: 12,
                        color: kmainBlack.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildQuantityAndCart() {
    return Column(
      children: [
        // Quantity Selector
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
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
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
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

        const SizedBox(height: 24),

        // Add to Cart Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kmainGreen, kmainGreen.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(28),
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
                CartService().addToCart(
                  context,
                  widget.foodId,
                  quantity: quantity,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Added ${quantity}x ${widget.title} to cart!',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
              },
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add to Cart • \$${(widget.price * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[400],
            size: 20,
          ),
        ),
      ),
    );
  }
}
