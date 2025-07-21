import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';
import 'package:the_tumeric_papplication/widgets/add_to_cart_button.dart';
import 'package:the_tumeric_papplication/widgets/half_full_indicatoe.dart';

class MainFoodDiscPage extends StatefulWidget {
  final String title;
  final String disc;
  final String imageUrl;
  final double price;

  final double time;
  const MainFoodDiscPage({
    super.key,
    required this.title,
    required this.disc,
    required this.imageUrl,
    required this.price,

    required this.time,
  });

  @override
  State<MainFoodDiscPage> createState() => _MainFoodDiscPageState();
}

class _MainFoodDiscPageState extends State<MainFoodDiscPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            widget.title,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Container(
                        width: double.infinity,

                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: kmainBlack.withOpacity(0.4),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.lightBlue,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: kmainBlack.withOpacity(0.7),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.grey),
                          SizedBox(width: 5),
                          Text(
                            "${widget.time} min",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kmainText,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      Text(
                        widget.disc,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: kmainText,
                        ),
                      ),
                      SizedBox(height: 20),

                      Row(children: [HalfFullIndicatoe()]),
                      SizedBox(height: 50),
                      SizedBox(height: 160),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const AddToCartButton(), // ← your widget here
            ),
          ),
        ],
      ),
    );
  }
}
