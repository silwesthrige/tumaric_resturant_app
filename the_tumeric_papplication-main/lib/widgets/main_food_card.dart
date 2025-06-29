import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class MainFoodCard extends StatelessWidget {
  const MainFoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,

      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: kmainBlack.withOpacity(0.25),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
        borderRadius: BorderRadius.circular(15),
        color: kmainWhite,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                "https://i.ytimg.com/vi/b-2ghz1_8UE/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLB72h6t3XUsWtBkwf3NuvTW8IlQaA",
                fit: BoxFit.contain,
                width: 175,
              ),
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Chicken Biriyani Kuruma",
                    overflow: TextOverflow.clip,
                    maxLines: 2,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  "     \$ 13.0",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.favorite_border, color: kMainOrange),
                Icon(Icons.add_shopping_cart, color: kMainOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
