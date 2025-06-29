import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';
import 'package:the_tumeric_papplication/widgets/add_to_cart_button.dart';
import 'package:the_tumeric_papplication/widgets/half_full_indicatoe.dart';

class MainFoodDiscPage extends StatefulWidget {
  const MainFoodDiscPage({super.key});

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
            "Chicken Biriyani",
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
                            "https://images.rawpixel.com/image_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDI0LTA3L2FuZ3VzdGVvd19hX3Bob3RvX29mX2FfY2hpY2tlbl9oYW5kaV9iaXJ5YW5pX3NpZGVfdmlld19pc29sYXRlZF85ZmZjNjI3MC05M2IzLTQ3NDMtYjllYS05OGE2NzEwMjFkZThfMS5qcGc.jpg",
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Chicken Biriyani",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: kmainBlack.withOpacity(0.7),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: kMainOrange),
                          SizedBox(width: 5),
                          Text(
                            "4.2  -  20 min",
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
                        "Discriptiopn ishdhakjsd ksadjkajsd kjasdasd wadawda awdawdawd wadawdawd awdawdawd awdawdawd wadawdaw dawdawdwa dawdawdawd awdawdwad wadawdwad awdawdaw dawdawd",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: kmainText,
                        ),
                      ),
                      SizedBox(height: 20),

                      Row(children: [HalfFullIndicatoe()]),
                      SizedBox(height: 50),
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
