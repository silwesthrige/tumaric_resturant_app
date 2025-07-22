import 'package:flutter/material.dart';
import 'package:the_tumeric_papplication/models/user_model.dart'; // Adjust path
import 'package:the_tumeric_papplication/pages/profile_pages/profile_details_page.dart';
import 'package:the_tumeric_papplication/services/user_services.dart'; // Adjust path
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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Use the stream to listen for real-time updates or just get the first value
      final userStream = _userServices.getCurrentUserDetails();
      _currentUser = await userStream;
    } catch (e) {
      print("Error fetching user data: $e");
      // Handle error, e.g., show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header Section
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  _currentUser?.profileImageUrl != null
                                      ? NetworkImage(
                                        _currentUser!.profileImageUrl!,
                                      )
                                      : const AssetImage(
                                            'assets/images/profile.jpg',
                                          )
                                          as ImageProvider, // Default image
                              backgroundColor: Colors.white,
                              child:
                                  _currentUser?.profileImageUrl == null
                                      ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _currentUser?.name ??
                                  "User Name", // Default if null
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _currentUser?.email ??
                                  "user@example.com", // Default if null
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
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

                          // _buildMenuCard(
                          //   context,
                          //   icon: Icons.history,
                          //   title: 'Order History',
                          //   subtitle: 'View your past orders',
                          //   onTap: () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => const OrderHistoryPage(),
                          //     ),
                          //   ),
                          // ),

                          // _buildMenuCard(
                          //   context,
                          //   icon: Icons.star_outline,
                          //   title: 'Feedbacks',
                          //   subtitle: 'Share your experience with us',
                          //   onTap: () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => const FeedbacksPage(),
                          //     ),
                          //   ),
                          // ),

                          // _buildMenuCard(
                          //   context,
                          //   icon: Icons.contact_support_outlined,
                          //   title: 'Contact Us',
                          //   subtitle: 'Get in touch with support',
                          //   onTap: () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => const ContactUsPage(),
                          //     ),
                          //   ),
                          // ),

                          // _buildMenuCard(
                          //   context,
                          //   icon: Icons.settings_outlined,
                          //   title: 'Settings',
                          //   subtitle: 'App preferences and account settings',
                          //   onTap: () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => const SettingsPage(),
                          //     ),
                          //   ),
                          // ),

                          // _buildMenuCard(
                          //   context,
                          //   icon: Icons.help_outline,
                          //   title: 'Help & Support',
                          //   subtitle: 'FAQs and customer support',
                          //   onTap: () => Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //       builder: (context) => const HelpSupportPage(),
                          //     ),
                          //   ),
                          // ),
                          _buildMenuCard(
                            context,
                            icon: Icons.logout,
                            title: 'Logout',
                            subtitle: 'Sign out of your account',
                            onTap: () => _showLogoutDialog(context),
                            isLogout: true,
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
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
                  // Assuming you have a route named '/login' for your login page
                  Navigator.pushReplacementNamed(context, '/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully!')),
                  );
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
