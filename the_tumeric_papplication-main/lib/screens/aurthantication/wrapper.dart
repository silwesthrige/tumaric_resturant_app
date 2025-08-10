import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/screens/aurthantication/aurthanticate.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    print(user);

    if (user == null) {
      return Aurthanticate();
    } else {
      return HomePage();
    }
  }
}
