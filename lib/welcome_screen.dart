import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'volunteer_login.dart';
import 'landowner_login.dart';
import 'ngo_login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreen, // Your earthy light green background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or Top Icon
              const Icon(Icons.eco, size: 80, color: Colors.white),
              const SizedBox(height: 24),

              // Welcome Text
              const Text(
                'Welcome to Jeevdhara',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your role to help protect life on land.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Role Selection Buttons
              _buildRoleCard(
                context,
                title: 'Volunteer',
                description:
                    'Join tree planting drives and monitor local biodiversity.',
                icon: Icons.volunteer_activism,
                onTap: () {
                  // Navigate to Volunteer Login
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VolunteerLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                title: 'Landowner',
                description:
                    'Offer your land for upcoming reforestation projects.',
                icon: Icons.landscape,
                onTap: () {
                  // Navigate to Landowner Login
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LandownerLogin(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                title: 'NGO',
                description: 'Organize planting drives and manage volunteers.',
                icon: Icons.groups,
                onTap: () {
                  // Navigate to NGO Login
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NGOLogin()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A reusable widget for the role cards to keep code clean
  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: darkGreen, // Your dark green palette color
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 40,
            color: harvestGold,
          ), // Golden accent for the icons
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
    );
  }
}
