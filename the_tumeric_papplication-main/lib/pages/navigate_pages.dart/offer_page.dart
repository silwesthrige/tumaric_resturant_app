import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/data/food_details_data.dart';

import 'package:the_tumeric_papplication/widgets/offer_page_card.dart';

class OfferPage extends StatelessWidget {
  const OfferPage({super.key});

  @override
  Widget build(BuildContext context) {
    FoodDetailsData listFood = FoodDetailsData();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                OfferPageCard(
                  imageUrl:
                      "https://www.bdtask.com/blog/assets/plugins/ckfinder/core/connector/php/uploads/images/promote-your-food-combo-offers.jpg",
                ),
                SizedBox(height: 8),
                OfferPageCard(
                  imageUrl:
                      "https://www.bdtask.com/blog/assets/plugins/ckfinder/core/connector/php/uploads/images/keep-an-attractive-and-creative-name-of-your-food-combo.jpg",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
