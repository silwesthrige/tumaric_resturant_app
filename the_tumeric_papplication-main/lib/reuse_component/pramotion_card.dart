import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PramotionCard extends StatefulWidget {
  const PramotionCard({super.key});

  @override
  State<PramotionCard> createState() => _PramotionCardState();
}

class _PramotionCardState extends State<PramotionCard> {
  @override
  Widget build(BuildContext context) {
    final PageController _controller = PageController();
    return Column(
      children: [
        Container(
          height: 200,
          margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.green, // You can change or remove this
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView(
              controller: _controller,
              children: [
                Image.asset("assets/images/offer.jpg", fit: BoxFit.cover),
                Image.asset("assets/images/offer.jpg", fit: BoxFit.cover),
                Image.asset("assets/images/offer.jpg", fit: BoxFit.cover),
              ],
            ),
          ),
        ),
        SizedBox(height: 5),
        // 🔘 Smooth Page Indicator
        SmoothPageIndicator(
          controller: _controller,
          count: 3,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Colors.green,
            dotColor: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
