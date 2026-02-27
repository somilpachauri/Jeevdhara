import 'package:flutter/material.dart';
import 'main.dart'; // Needed to access themeNotifier
import 'volunteer_login.dart';
import 'landowner_login.dart';
import 'ngo_login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // --- APPBAR WITH THEME TOGGLE ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: themeNotifier,
            builder: (context, themeIndex, _) {
              IconData themeIcon;
              if (themeIndex == 0)
                themeIcon = Icons.light_mode;
              else if (themeIndex == 1)
                themeIcon = Icons.dark_mode;
              else
                themeIcon = Icons.eco;

              return IconButton(
                icon: Icon(themeIcon, color: colorScheme.onSurface),
                tooltip: 'Toggle Theme',
                onPressed: () => themeNotifier.value = (themeIndex + 1) % 3,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // FIXED: ConstrainedBox prevents UI from stretching too wide on Web/Desktop
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.eco, size: 80, color: colorScheme.secondary),
                const SizedBox(height: 24),
                Text(
                  "Welcome to Jeevdhara",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose your role to help protect life on land.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),

                _buildRoleButton(
                  context,
                  title: "Volunteer",
                  subtitle:
                      "Join tree planting drives and monitor biodiversity.",
                  icon: Icons.volunteer_activism,
                  targetScreen: const VolunteerLogin(),
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context,
                  title: "Landowner",
                  subtitle:
                      "Offer your land for upcoming reforestation projects.",
                  icon: Icons.landscape,
                  targetScreen: const LandownerLogin(),
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context,
                  title: "NGO",
                  subtitle: "Organize planting drives and manage volunteers.",
                  icon: Icons.groups,
                  targetScreen: const NGOLogin(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget targetScreen,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          // FIXED: Uses card color for high contrast against dark background
          color: theme.cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: colorScheme.secondary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
