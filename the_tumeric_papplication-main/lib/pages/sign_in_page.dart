import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/pages/sign_up_page.dart';

import 'package:the_tumeric_papplication/shared/custom_button.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "assets/images/hotelLogo.png",
              width: 560,
              fit: BoxFit.contain,
            ),
            Container(
              width: double.infinity,
              height: 410,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                gradient: LinearGradient(
                  colors: [
                    Color(0XFF080D06).withOpacity(0.8),
                    Color(0XFF508239),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Form(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            SizedBox(height: 15),
                            Text(
                              "Login to your Account",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: "Username",
                                filled: true,
                                fillColor: Colors.white,
                                focusColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: "Password",

                                filled: true,
                                fillColor: Colors.white,
                                focusColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            CustumButton(
                              buttonName: "Login",
                              buttonColor: kMainOrange,
                            ),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                Text(
                                  "Don’t have an account?",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignUpPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    child: Text(
                                      "Sign up",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
