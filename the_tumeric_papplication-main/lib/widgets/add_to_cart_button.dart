import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class AddToCartButton extends StatelessWidget {
  const AddToCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: kmainWhite,
              boxShadow: [
                BoxShadow(
                  blurRadius: 5,
                  color: kmainBlack.withOpacity(0.6),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.add_shopping_cart_sharp,
              size: 30,
              color: kmainGreen,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            width: 280,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: kMainOrange,
              boxShadow: [
                BoxShadow(
                  blurRadius: 5,
                  color: kmainBlack.withOpacity(0.6),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "Add to Favorite",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kmainWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
