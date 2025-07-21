import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/Home_page_bottum.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/cart_page.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/cartpage.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/offer_page.dart';

import 'package:the_tumeric_papplication/pages/navigate_pages.dart/profile_page.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int myCurrentIndex = 0;

  List pages = [HomePageBottum(), CartPage(), OfferPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 30,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: myCurrentIndex,

            backgroundColor: kmainGreen,
            selectedItemColor: kMainOrange,
            unselectedItemColor: kmainWhite,
            selectedFontSize: 12,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            onTap: (index) {
              setState(() {
                myCurrentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
                label: "Cart",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_fire_department_rounded),
                label: "offers",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),

      body: pages[myCurrentIndex],
    );
  }
}
