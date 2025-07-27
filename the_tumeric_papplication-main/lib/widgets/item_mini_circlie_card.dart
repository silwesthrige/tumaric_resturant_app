import 'package:flutter/material.dart';

class ItemMiniCirclieCard extends StatelessWidget {
  final String imageUrl;
  final String imageTitle;
  final VoidCallback? ontap;
  const ItemMiniCirclieCard({
    super.key,
    required this.imageUrl,
    required this.imageTitle,
    this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        child: Column(
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.9),
                    blurRadius: 8,
                    offset: Offset(1, 5),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5),
            Text(
              imageTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
