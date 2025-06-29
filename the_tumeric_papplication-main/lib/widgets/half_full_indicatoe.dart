import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class HalfFullIndicatoe extends StatefulWidget {
  const HalfFullIndicatoe({super.key});

  @override
  State<HalfFullIndicatoe> createState() => _HalfFullIndicatoeState();
}

class _HalfFullIndicatoeState extends State<HalfFullIndicatoe> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Container(
            width: 75,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: kmainGreen,
              border: Border.all(width: 0.5),
            ),
            child: Center(
              child: Text(
                "Full",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kmainWhite,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 75,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(width: 0.5),
              color: kmainWhite,
            ),
            child: Center(
              child: Text(
                "Regular",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kmainBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
