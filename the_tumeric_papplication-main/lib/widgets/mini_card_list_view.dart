import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/data/mini_card_data.dart';
import 'package:the_tumeric_papplication/widgets/item_mini_circlie_card.dart';

class MiniCardListView extends StatelessWidget {
  const MiniCardListView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: miniCardList.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final card = miniCardList[index];
          return Padding(
            padding: const EdgeInsets.only(right: 17),
            child: ItemMiniCirclieCard(
              imageUrl: card.imageUrl,
              imageTitle: card.imageTitle,
            ),
          );
        },
      ),
    );
  }
}
