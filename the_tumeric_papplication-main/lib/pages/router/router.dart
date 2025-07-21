import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/offer_page.dart';
import 'package:the_tumeric_papplication/pages/profile_pages/profile_details_page.dart';

class RouterClass {
  final router = GoRouter(
    initialLocation: "/",
    errorPageBuilder: (context, state) {
      return const MaterialPage<dynamic>(
        child: Scaffold(body: Center(child: Text("this page is not found!!"))),
      );
    },
    routes: [
      // Home Page
      GoRoute(
        path: "/",
        name: "Home Page",
        builder: (context, state) {
          return HomePage();
        },
      ),

      //offer page
      GoRoute(
        path: "/offer-page",
        name: "offer Page",
        builder: (context, state) => OfferPage(),
      ),

      GoRoute(
        path: "/profile-details",
        name: "Profile Details Page",
        builder: (context, state) {
          return ProfileDetailsPage();
        },
      ),
    ],
  );
}
