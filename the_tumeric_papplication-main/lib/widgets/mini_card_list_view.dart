import 'package:flutter/material.dart';

import 'package:the_tumeric_papplication/models/food_detail_model.dart';

import 'package:the_tumeric_papplication/pages/main_food_disc_page.dart';
import 'package:the_tumeric_papplication/widgets/item_mini_circlie_card.dart';

class MiniCardListView extends StatelessWidget {
  final List<FoodDetailModel> miniFoods;
  const MiniCardListView({super.key, required this.miniFoods});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, // Adjust as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: miniFoods.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final food = miniFoods[index];
          return Padding(
            padding: const EdgeInsets.only(right: 17),
            child: ItemMiniCirclieCard(
              ontap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return MainFoodDiscPage(
                        title: food.foodName,
                        disc: food.discription,
                        imageUrl: food.imageUrl,
                        price: food.price,
                        time: food.cookedTime,
                      );
                    },
                  ),
                );
              },

              imageUrl: food.imageUrl,
              imageTitle: food.foodName,
            ),
          );
        },
      ),
    );
  }
}
