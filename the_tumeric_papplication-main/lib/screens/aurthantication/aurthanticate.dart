import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/pages/sign_in_page.dart';
import 'package:the_tumeric_papplication/pages/sign_up_page.dart';

class Aurthanticate extends StatefulWidget {
  const Aurthanticate({super.key});

  @override
  State<Aurthanticate> createState() => _AurthanticateState();
}

class _AurthanticateState extends State<Aurthanticate> {
  bool signInPage = true;

  //toggle page
  void switchpage() {
    setState(() {
      signInPage = !signInPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (signInPage == true) {
      return SignInPage(toggle: switchpage);
    } else {
      return SignUpPage(toggle: switchpage);
    }
  }
}
