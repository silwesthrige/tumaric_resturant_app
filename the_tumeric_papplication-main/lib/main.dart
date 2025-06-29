import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/pages/sign_in_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: GoogleFonts.nunitoTextTheme()),
      title: "The Tumaric",
      home: HomePage(),
    );
  }
}
