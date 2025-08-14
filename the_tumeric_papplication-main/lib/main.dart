import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_tumeric_papplication/firebase_options.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/notifications/message_opener.dart';
import 'package:the_tumeric_papplication/notifications/notification_page.dart';
import 'package:the_tumeric_papplication/notifications/notification_services.dart';
import 'package:the_tumeric_papplication/notifications/push_notifications.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/offer_page.dart';
import 'package:the_tumeric_papplication/pages/sign_in_page.dart';
import 'package:the_tumeric_papplication/pages/sign_up_page.dart';
import 'package:the_tumeric_papplication/screens/aurthantication/wrapper.dart';
import 'package:the_tumeric_papplication/services/order_services.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:the_tumeric_papplication/services/auth.dart';

// Navigator key - similar to your friend's approach
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Initialize the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification services
  await NotificationServices.init();
  tz.initializeTimeZones();

  // Initialize push notification service
  await PushNotificationsService.init();

  // Listen for incoming messages in background
  FirebaseMessaging.onBackgroundMessage(
    PushNotificationsService.onBackgroundMessage,
  );

  // On background notification tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    if (message.notification != null) {
      print("Background Notification Tapped");
      await PushNotificationsService.onBackgroundNotificationTapped(
        message,
        navigatorKey,
      );
    }
  });

  // On foreground notification tapped
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    await PushNotificationsService.onForeroundNotificationTapped(
      message,
      navigatorKey,
    );
  });

  // For handling in terminated state
  final RemoteMessage? message =
      await FirebaseMessaging.instance.getInitialMessage();
  if (message != null) {
    print("Launched from terminated state");
    Future.delayed(const Duration(seconds: 2), () {
      // You can add your message handling route here
      navigatorKey.currentState!.pushNamed("/offer-page", arguments: message);
    });
  }

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      initialData: null,
      value: AuthServices().user,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: GoogleFonts.poppins().fontFamily,
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        title: "The Turmeric",
        // Use Wrapper as home - it handles authentication routing
        home: const Wrapper(),
        // Define all your routes here
        routes: {
          '/auth/signin':
              (context) => SignInPage(
                toggle:
                    () => Navigator.of(
                      context,
                    ).pushReplacementNamed('/auth/signup'),
              ),
          '/auth/signup':
              (context) => SignUpPage(
                toggle:
                    () => Navigator.of(
                      context,
                    ).pushReplacementNamed('/auth/signin'),
              ),
          '/home': (context) => const HomePage(),
          '/offer-page': (context) => OfferPage(),
          '/wrapper': (context) => const Wrapper(),
          '/message': (context) => MessageOpener(),
          '/notifications': (context) => const NotificationsPage(),
        },
        // Handle unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Page not found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Route: ${settings.name}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () =>
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/wrapper',
                                    (route) => false,
                                  ),
                          child: const Text('Go Home'),
                        ),
                      ],
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }
}

// Extension to make navigation easier (similar to your GoRouter extension)
extension NavigationExtension on BuildContext {
  void goToSignIn() => Navigator.of(
    this,
  ).pushNamedAndRemoveUntil('/auth/signin', (route) => false);

  void goToSignUp() => Navigator.of(
    this,
  ).pushNamedAndRemoveUntil('/auth/signup', (route) => false);

  void goToHome() =>
      Navigator.of(this).pushNamedAndRemoveUntil('/home', (route) => false);

  void goToWrapper() =>
      Navigator.of(this).pushNamedAndRemoveUntil('/wrapper', (route) => false);

  void goToOfferPage() => Navigator.of(this).pushNamed('/offer-page');
  void goToNotifications() => Navigator.of(this).pushNamed('/notifications');

  // Add more navigation methods as needed
}
