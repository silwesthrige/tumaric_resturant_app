import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/pages/router/router.dart';

import 'package:the_tumeric_papplication/services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      initialData: UserModel(uID: ""),
      value: AuthServices().user,
      child: Consumer<UserModel?>(
        builder: (context, user, child) {
          // Create router with access to user state
          final router = AppRouter.createRouter();

          return MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: GoogleFonts.poppins().fontFamily,
              // Add some additional theme customizations
              primarySwatch: Colors.orange,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            title: "The Turmeric",
          );
        },
      ),
    );
  }
}
