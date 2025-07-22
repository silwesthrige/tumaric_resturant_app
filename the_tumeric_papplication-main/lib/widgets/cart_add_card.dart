import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart'; // Assuming this file exists and defines your colors

class CaertAddCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String disc;
  final double price;
  final VoidCallback? onDelete;

  const CaertAddCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.disc,
    required this.price,
    this.onDelete,
  });

  @override
  State<CaertAddCard> createState() => _CaertAddCardState();
}

class _CaertAddCardState extends State<CaertAddCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150), // Quick shake duration
      vsync: this,
    );

    // Define the shake animation
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 0.25),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 0.50),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 0.25),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth in and out
      ),
    );

    // Listen for animation status to reset it after completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerShake() {
    if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerShake, // Trigger shake on tap
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_animation.value, 0), // Apply horizontal shake
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kmainWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kmainBlack.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl, // Use widget.imageUrl
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                            ),
                          ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                            color: kmainGreen,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Details Area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.title, // Use widget.title
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kmainBlack,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Text(
                          widget.disc, // Use widget.disc
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: kmainText.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price as a Chip
                        Container(
                          decoration: BoxDecoration(
                            color: kmainGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kmainGreen.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          child: Text(
                            "\$${widget.price.toStringAsFixed(2)}", // Use widget.price
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kmainGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete Button
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: widget.onDelete, // Use widget.onDelete
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red[500],
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
