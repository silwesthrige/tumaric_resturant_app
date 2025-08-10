import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/Home_page_bottum.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/cartpage.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/offer_page.dart';

import 'package:the_tumeric_papplication/pages/navigate_pages.dart/profile_page_new.dart';
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
            backgroundColor: Colors.white, // Modern clean background
            selectedItemColor: Color(
              0xFFF4A300,
            ), // Turmeric orange for active items
            unselectedItemColor:
                Colors.grey.shade500, // Soft gray for inactive icons
            selectedFontSize: 12,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            elevation: 8, // Adds slight shadow for depth
            onTap: (index) {
              setState(() {
                myCurrentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded),
                label: "Cart",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_fire_department_rounded),
                label: "Offers",
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
