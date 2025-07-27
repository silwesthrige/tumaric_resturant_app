import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';

import 'package:the_tumeric_papplication/services/auth.dart';
import 'package:the_tumeric_papplication/services/user_services.dart';

import 'package:the_tumeric_papplication/shared/custom_button.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';

class SignInPage extends StatefulWidget {
  final Function toggle;
  const SignInPage({super.key, required this.toggle});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthServices _auth = AuthServices();

  //form key
  final _formKey = GlobalKey<FormState>();

  String email = "";
  String password = "";
  String error = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) {
              //       return HomePage();
              //     },
              //   ),
              // );
            },
            child: Text(
              "Skip",
              style: TextStyle(
                color: kMainOrange,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
                      key: _formKey,
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
                              validator:
                                  (value) =>
                                      value?.isEmpty == true
                                          ? "Enter a valid Username"
                                          : null,
                              onChanged: (value) {
                                setState(() {
                                  email = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Email",
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
                              validator:
                                  (value) =>
                                      value!.length < 6
                                          ? "Enter a valid Password"
                                          : null,
                              onChanged: (value) {
                                setState(() {
                                  password = value;
                                });
                              },
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
                            GestureDetector(
                              onTap: () async {
                                if (_formKey.currentState!.validate()) {
                                  UserModel? result = await _auth
                                      .signInEmailAndPassword(email, password);
                                  if (result == null) {
                                    setState(() {
                                      error = "Could Not Sign In";
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(16),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    });
                                  } else {
                                    setState(() {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Login Successfully!"),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(16),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    });
                                  }
                                }
                              },
                              child: CustumButton(
                                buttonName: "Login",
                                buttonColor: kMainOrange,
                              ),
                            ),
                            SizedBox(height: 15),
                            // Text(
                            //   error,
                            //   style: TextStyle(
                            //     fontWeight: FontWeight.w700,
                            //     color: Colors.red,
                            //   ),
                            // ),
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
                                    widget.toggle();
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
