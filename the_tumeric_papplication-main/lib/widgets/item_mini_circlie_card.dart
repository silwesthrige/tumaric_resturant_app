import 'package:flutter/material.dart';

class ItemMiniCirclieCard extends StatelessWidget {
  final String imageUrl;
  final String imageTitle;
  const ItemMiniCirclieCard({
    super.key,
    required this.imageUrl,
    required this.imageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 5),
        Text(
          imageTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        
      ],
    );
  }
}
