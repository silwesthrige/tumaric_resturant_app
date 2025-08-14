import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_tumeric_papplication/main.dart';
import 'package:the_tumeric_papplication/models/user_model.dart'; // Adjust path
import 'package:the_tumeric_papplication/pages/profile_pages/contact_us_page.dart';
import 'package:the_tumeric_papplication/pages/profile_pages/feedback_page.dart';
import 'package:the_tumeric_papplication/pages/profile_pages/orders_page.dart';
import 'package:the_tumeric_papplication/pages/profile_pages/profile_details_page.dart';
import 'package:the_tumeric_papplication/pages/profile_pages/resturant_page.dart';
import 'package:the_tumeric_papplication/services/user_services.dart'; // Adjust path
import 'package:the_tumeric_papplication/test/notification_test.widget.dart';
import 'package:the_tumeric_papplication/utils/colors.dart';
import 'package:the_tumeric_papplication/widgets/profile_page_tabs.dart';
import 'package:the_tumeric_papplication/widgets/profile_picture_widget.dart'; // Import the profile picture widget
import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Alias to avoid conflict

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserServices _userServices = UserServices();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is logged in with Firebase Auth
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _isLoggedIn = true;
        });
        await _fetchUserData();
      } else {
        setState(() {
          _isLoggedIn = false;
        });
      }
    } catch (e) {
      print("Error checking login status: $e");
      setState(() {
        _isLoggedIn = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      // Use the stream to listen for real-time updates or just get the first value
      final userStream = _userServices.getCurrentUserDetails();
      final userModel = await userStream;
      if (mounted) {
        setState(() {
          _currentUser = userModel;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      // Handle error, e.g., show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile data: $e')),
        );
      }
    }
  }

  // Callback function when profile picture is updated
  void _onProfileImageUpdated(String newImageUrl) {
    if (mounted && _currentUser != null) {
      setState(() {
        _currentUser = _currentUser!.copyWith(profileImageUrl: newImageUrl);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Profile'),
        automaticallyImplyLeading: false,

        backgroundColor: kMainOrange,
        foregroundColor: kmainWhite,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : _isLoggedIn
              ? _buildLoggedInProfile()
              : _buildLoginPrompt(),
    );
  }

  Widget _buildLoggedInProfile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 17,
                  color: kMainOrange,
                  offset: Offset(0, 2),
                  blurStyle: BlurStyle.solid,
                ),
              ],
              color: kMainOrange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  // Profile Picture Widget with edit functionality
                  ProfilePictureWidget(
                    currentUser: _currentUser,
                    onImageUpdated: _onProfileImageUpdated,
                  ),

                  const SizedBox(height: 15),
                  Text(
                    _currentUser?.name ?? "User Name", // Default if null
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _currentUser?.email ??
                        "user@example.com", // Default if null
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Verified Customer',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile Details',
                  subtitle: 'Manage your personal information',
                  onTap: () async {
                    // Navigate and wait for result (if details were updated)
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfileDetailsPage(
                              currentUser:
                                  _currentUser, // Pass current user data
                            ),
                      ),
                    );
                    if (result == true) {
                      _fetchUserData(); // Refresh data if updated
                    }
                  },
                ),

                _buildMenuCard(
                  context,
                  icon: Icons.history,
                  title: 'Order History',
                  subtitle: 'View your past orders',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrdersPage()),
                      ),
                ),

                _buildMenuCard(
                  context,
                  icon: Icons.star_outline,
                  title: 'Feedbacks',
                  subtitle: 'Share your experience with us',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbacksPage(),
                        ),
                      ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.history,
                  title: 'Contact Us',
                  subtitle: 'Contact Our Resturant',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactUsPage(),
                        ),
                      ),
                ),

                _buildMenuCard(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  onTap: () => _showLogoutDialog(context),
                  isLogout: true,
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.history,
                  title: 'Check Notify',
                  subtitle: 'Contact Our Resturant',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationTestPage(),
                        ),
                      ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Login illustration
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: kMainOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline, size: 80, color: kMainOrange),
            ),

            const SizedBox(height: 30),

            // Title
            const Text(
              'Welcome to Turmeric!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // Subtitle
            const Text(
              'Please log in to access your profile and enjoy personalized features.',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to login page
                  context.goToSignIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 8),
                    Text(
                      'Please Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Register option
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to register page (adjust route name as needed)
                    GoRouter.of(context).push("/auth/signup");
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(15),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isLogout
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isLogout ? Colors.red : Colors.orange,
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isLogout ? Colors.red : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey.shade400,
            size: 16,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                try {
                  await fb_auth.FirebaseAuth.instance.signOut();
                  // Update the login status
                  setState(() {
                    _isLoggedIn = false;
                    _currentUser = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully!')),
                  );
                  context.goToSignIn();
                } catch (e) {
                  print("Error during logout: $e");
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
