import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class HalfFullIndicatoe extends StatefulWidget {
  const HalfFullIndicatoe({super.key});

  @override
  State<HalfFullIndicatoe> createState() => _HalfFullIndicatoeState();
}

class _HalfFullIndicatoeState extends State<HalfFullIndicatoe> {
  // Track which option is selected: true = Full, false = Regular
  bool isFullSelected = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Full indicator
        GestureDetector(
          onTap: () {
            setState(() {
              isFullSelected = true;
            });
          },
          child: Container(
            width: 75,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: isFullSelected ? kmainGreen : kmainWhite,
              border: Border.all(width: 0.5),
            ),
            child: Center(
              child: Text(
                "Full",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isFullSelected ? kmainWhite : kmainBlack,
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: 10),

        // Regular indicator
        GestureDetector(
          onTap: () {
            setState(() {
              isFullSelected = false;
            });
          },
          child: Container(
            width: 75,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: isFullSelected ? kmainWhite : kmainGreen,
              border: Border.all(width: 0.5),
            ),
            child: Center(
              child: Text(
                "Regular",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isFullSelected ? kmainBlack : kmainWhite,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
