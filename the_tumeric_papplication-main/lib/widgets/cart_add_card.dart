import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class CaertAddCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String disc;
  final double price;
  final VoidCallback? onDelete; // Add this optional callback

  const CaertAddCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.disc,
    required this.price,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: kmainWhite,
        boxShadow: [
          BoxShadow(
            blurRadius: 2,
            color: kmainBlack.withOpacity(0.3),
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(imageUrl, width: 140, fit: BoxFit.contain),
            ),
            SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 160,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      color: kmainBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 160,
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    disc,
                    style: TextStyle(
                      fontSize: 16,
                      color: kmainText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  child: Text(
                    "\$ ${price.toStringAsFixed(2)}", // Use actual price here
                    style: TextStyle(
                      fontSize: 18,
                      color: kmainGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 5),
            GestureDetector(
              onTap: onDelete, // Call delete callback if provided
              child: Icon(
                Icons.close,
                color: kmainBlack,
                size: 20,
                shadows: [
                  Shadow(
                    color: kmainBlack,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
