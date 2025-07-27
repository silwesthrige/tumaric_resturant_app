import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class OfferPageCard extends StatelessWidget {
  final String imageUrl;
  final String? offerTitle;
  final String? discount;
  final VoidCallback? onClaimPressed;

  const OfferPageCard({
    super.key,
    required this.imageUrl,
    this.offerTitle,
    this.discount,
    this.onClaimPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
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
                ],
              ),
            ),

            // Top Right Discount Badge
            if (discount != null)
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    discount!,
                    style: TextStyle(
                      color: kmainWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Top Left Fire Icon with Glow Effect
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kMainOrange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: kMainOrange.withOpacity(0.5),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: kmainWhite,
                  size: 20,
                ),
              ),
            ),

            // Bottom Content Area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Offer Title
                    if (offerTitle != null)
                      Text(
                        offerTitle!,
                        style: TextStyle(
                          color: kmainWhite,
                          fontSize: 18,
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

                    SizedBox(height: 12),

                    // Claim Offer Button
                    Center(
                      child: GestureDetector(
                        onTap: onClaimPressed,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 160,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kMainOrange,
                                kMainOrange.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: kMainOrange.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard_rounded,
                                color: kmainWhite,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Claim Offer",
                                style: TextStyle(
                                  color: kmainWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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

            // Shimmer Effect on Hover (Optional)
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
