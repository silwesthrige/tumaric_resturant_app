import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class CheckOutButton extends StatelessWidget {
  const CheckOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: 230,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: kmainWhite,
          border: Border.all(width: 2, color: kMainOrange),
        ),
        child: Center(
          child: Text(
            "Check Out",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kMainOrange,
            ),
          ),
        ),
      ),
    );
  }
}
