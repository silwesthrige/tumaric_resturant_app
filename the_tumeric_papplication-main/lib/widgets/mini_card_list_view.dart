import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/catogary_model.dart';

import 'package:the_tumeric_papplication/models/food_detail_model.dart';
import 'package:the_tumeric_papplication/pages/List_of_catogary_page.dart';

import 'package:the_tumeric_papplication/pages/main_food_disc_page.dart';
import 'package:the_tumeric_papplication/widgets/item_mini_circlie_card.dart';

class MiniCardListView extends StatelessWidget {
  final List<CatogaryModel> catogarys;
  const MiniCardListView({super.key, required this.catogarys});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, // Adjust as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: catogarys.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final catogary = catogarys[index];
          return Padding(
            padding: const EdgeInsets.only(right: 17),
            child: ItemMiniCirclieCard(
              ontap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ListOfCatogaryPage(
                        catogaryId: catogary.catogaryId,
                        catogaryName: catogary.catogaryName,
                      );
                    },
                  ),
                );
              },

              imageUrl: catogary.imageUrl,
              imageTitle: catogary.catogaryName,
            ),
          );
        },
      ),
    );
  }
}
