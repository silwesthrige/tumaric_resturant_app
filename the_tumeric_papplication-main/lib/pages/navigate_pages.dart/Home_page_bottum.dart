import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/data/food_details_data.dart';
import 'package:the_tumeric_papplication/pages/main_food_disc_page.dart';

import 'package:the_tumeric_papplication/reuse_component/pramotion_card.dart';

import 'package:the_tumeric_papplication/widgets/main_food_card.dart';
import 'package:the_tumeric_papplication/widgets/mini_card_list_view.dart';
import 'package:the_tumeric_papplication/widgets/search_bar.dart';

class HomePageBottum extends StatelessWidget {
  const HomePageBottum({super.key});

  @override
  Widget build(BuildContext context) {
    FoodDetailsData listFood = FoodDetailsData();

    return Scaffold(
      appBar: AppBar(toolbarHeight: 80, elevation: 0, title: Search_Bar()),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 15),
                Text(
                  "Pramotions",
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                PramotionCard(),
                SizedBox(height: 20),
                MiniCardListView(),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "see more >",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                //sample Data
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainFoodDiscPage(),
                          ),
                        );
                      },
                      child: MainFoodCard(),
                    ),

                    MainFoodCard(),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [MainFoodCard(), MainFoodCard()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
