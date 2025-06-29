import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class Search_Bar extends StatelessWidget {
  const Search_Bar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: kmainWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 26, color: Colors.grey[700]),

          SizedBox(width: 20),

          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
