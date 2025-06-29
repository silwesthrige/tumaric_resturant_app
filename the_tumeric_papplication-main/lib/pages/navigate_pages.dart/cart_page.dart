import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/data/food_details_data.dart';
import 'package:the_tumeric_papplication/models/food_detail_model.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';
import 'package:the_tumeric_papplication/widgets/cart_add_card.dart';
import 'package:the_tumeric_papplication/widgets/check_out_button.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final foodDetails = FoodDetailsData();
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "My Cart",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: kmainBlack,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CaertAddCard(
                    imageUrl: foodDetails.foodDetailsList[0].imageUrl,
                    title: foodDetails.foodDetailsList[0].foodName,
                    disc: foodDetails.foodDetailsList[0].discription,
                    price: foodDetails.foodDetailsList[0].price,
                  ),
                  SizedBox(height: 15),
                  CaertAddCard(
                    imageUrl: foodDetails.foodDetailsList[0].imageUrl,
                    title: foodDetails.foodDetailsList[0].foodName,
                    disc: foodDetails.foodDetailsList[0].discription,
                    price: foodDetails.foodDetailsList[0].price,
                  ),
                  SizedBox(height: 15),
                  CaertAddCard(
                    imageUrl: foodDetails.foodDetailsList[0].imageUrl,
                    title: foodDetails.foodDetailsList[0].foodName,
                    disc: foodDetails.foodDetailsList[0].discription,
                    price: foodDetails.foodDetailsList[0].price,
                  ),
                  SizedBox(height: 15),
                  CaertAddCard(
                    imageUrl: foodDetails.foodDetailsList[0].imageUrl,
                    title: foodDetails.foodDetailsList[0].foodName,
                    disc: foodDetails.foodDetailsList[0].discription,
                    price: foodDetails.foodDetailsList[0].price,
                  ),
                  SizedBox(height: 15),
                  CaertAddCard(
                    imageUrl: foodDetails.foodDetailsList[0].imageUrl,
                    title: foodDetails.foodDetailsList[0].foodName,
                    disc: foodDetails.foodDetailsList[0].discription,
                    price: foodDetails.foodDetailsList[0].price,
                  ),
                  SizedBox(height: 15),
                  CaertAddCard(
                    imageUrl: foodDetails.foodDetailsList[0].imageUrl,
                    title: foodDetails.foodDetailsList[0].foodName,
                    disc: foodDetails.foodDetailsList[0].discription,
                    price: foodDetails.foodDetailsList[0].price,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 75,
              color: kmainWhite.withOpacity(0.7),
              padding: EdgeInsets.all(10),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CheckOutButton(),
                  SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Price : ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kmainText,
                        ),
                      ),
                      Text(
                        "\$ 120 ",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kmainBlack,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
