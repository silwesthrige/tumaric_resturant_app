import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileDetailsTab extends StatelessWidget {
  const ProfileDetailsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(children: [const SizedBox(height: 16)]),
          ),

          // Profile Info Cards
          _buildProfileCard(
            icon: Icons.restaurant_menu,
            title: 'Favorite Cuisine',
            subtitle: 'Italian & Sri Lankan',
            color: const Color(0xFFE91E63),
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
            ),
          ),

          _buildProfileCard(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'shan@email.com',
            color: const Color(0xFF2196F3),
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            ),
          ),

          _buildProfileCard(
            icon: Icons.location_on_outlined,
            title: 'Campus',
            subtitle: 'NIBM Kurunegala',
            color: const Color(0xFF4CAF50),
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
            ),
          ),

          _buildProfileCard(
            icon: Icons.cake_outlined,
            title: 'Birthday',
            subtitle: '23 Jan 2005',
            color: const Color(0xFF9C27B0),
            gradient: const LinearGradient(
              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
            ),
          ),

          _buildProfileCard(
            icon: Icons.delivery_dining,
            title: 'Total Orders',
            subtitle: '47 Delicious Meals',
            color: const Color(0xFFFF9800),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFE65100)],
            ),
          ),

          _buildProfileCard(
            icon: Icons.star_outline,
            title: 'Member Since',
            subtitle: 'January 2024',
            color: const Color(0xFFFFEB3B),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEB3B), Color(0xFFF57F17)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withOpacity(0.05)],
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3192),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeedbacksTab extends StatelessWidget {
  const FeedbacksTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Love Our Food?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3192),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share your experience and help us\nserve you better!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.feedback_outlined, size: 24),
              label: const Text(
                'Leave Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.orange.withOpacity(0.3),
              ),
              onPressed: () {
                // You can showDialog or navigate to form
                _showFeedbackDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Feedback',
              style: TextStyle(
                color: Color(0xFF2E3192),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Thank you for choosing our food delivery service!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

class ContactUsTab extends StatelessWidget {
  const ContactUsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Get In Touch',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3192),
                  ),
                ),
                const Text(
                  'We\'re here to help you!',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),

          // Contact Options
          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'Get help via email',
            color: const Color(0xFF2196F3),
            onTap: () => launchUrl(Uri.parse('mailto:support@example.com')),
          ),

          _buildContactCard(
            icon: Icons.chat_outlined,
            title: 'WhatsApp Chat',
            subtitle: 'Quick support on WhatsApp',
            color: const Color(0xFF4CAF50),
            onTap: () => launchUrl(Uri.parse('https://wa.me/94717663824')),
          ),

          _buildContactCard(
            icon: Icons.group_outlined,
            title: 'Join Our Community',
            subtitle: 'Connect with other food lovers',
            color: const Color(0xFFFF9800),
            onTap:
                () => launchUrl(
                  Uri.parse('https://chat.whatsapp.com/K2xaKLOLApMD3Pwmvk1ce8'),
                ),
          ),

          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Call Us',
            subtitle: 'Speak directly with our team',
            color: const Color(0xFFE91E63),
            onTap: () => launchUrl(Uri.parse('tel:+94717663824')),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, color.withOpacity(0.05)],
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3192),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
