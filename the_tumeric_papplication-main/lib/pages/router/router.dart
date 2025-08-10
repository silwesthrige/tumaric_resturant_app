import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_tumeric_papplication/models/user_model.dart';
import 'package:the_tumeric_papplication/pages/home_page.dart';
import 'package:the_tumeric_papplication/pages/navigate_pages.dart/offer_page.dart';
import 'package:the_tumeric_papplication/pages/sign_in_page.dart';
import 'package:the_tumeric_papplication/pages/sign_up_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/auth/signin',
      redirect: _handleRedirect,
      routes: [
        // Authentication routes
        GoRoute(path: '/auth', redirect: (context, state) => '/auth/signin'),
        GoRoute(
          path: '/auth/signin',
          name: 'signin',
          pageBuilder:
              (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: SignInPage(toggle: () => context.go('/auth/signup')),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),

        GoRoute(path: "/offer-page", builder: (context, state) => OfferPage()),
        GoRoute(
          path: '/auth/signup',
          name: 'signup',
          pageBuilder:
              (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: SignUpPage(toggle: () => context.go('/auth/signin')),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
        ),
        // Home route
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder:
              (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: const HomePage(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeInOut)),
                    ),
                    child: child,
                  );
                },
              ),
        ),

        //routes
        // GoRoute(path: "")
      ],
      errorPageBuilder:
          (context, state) => MaterialPage<void>(
            key: state.pageKey,
            child: Scaffold(
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
                    Text('Path: ${state.uri.path}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/auth/signin'),
                      child: const Text('Go to Sign In'),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // Handle authentication-based redirects
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final user = Provider.of<UserModel?>(context, listen: false);
    final isOnAuthPage = state.uri.path.startsWith('/auth');
    final isOnHomePage = state.uri.path == '/home';

    // If user is null (not authenticated)
    if (user == null || user.uID.isEmpty) {
      // If not on auth page, redirect to sign in
      if (!isOnAuthPage) {
        return '/auth/signin';
      }
    } else {
      // User is authenticated
      // If on auth page, redirect to home
      if (isOnAuthPage) {
        return '/home';
      }
    }

    // No redirect needed
    return null;
  }
}

// Extension to make navigation easier
extension GoRouterExtension on BuildContext {
  void goToSignIn() => go('/auth/signin');
  void goToSignUp() => go('/auth/signup');
  void goToHome() => go('/home');
}
