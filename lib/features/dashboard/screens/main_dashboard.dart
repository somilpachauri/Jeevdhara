import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../main.dart'; 
import '../../home/screens/home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../scanner/screens/ai_scanner.dart';
import '../../community/screens/ngo_request_drive.dart';
import '../../community/screens/landowner_offer_land.dart';
import '../../community/screens/company_add_drive.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  String? userRole;
  double? userLat;
  double? userLng;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          userRole = data['role']; 
          if (data['searchLatitude'] != null) {
            userLat = (data['searchLatitude'] is int) ? (data['searchLatitude'] as int).toDouble() : data['searchLatitude'];
          }
          if (data['searchLongitude'] != null) {
            userLng = (data['searchLongitude'] is int) ? (data['searchLongitude'] as int).toDouble() : data['searchLongitude'];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final bool canUseScanner = userRole != 'company';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Jeevdhara',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDesktop) ...[
                        IconButton(
                          icon: Icon(Icons.home, color: _currentIndex == 0 ? colorScheme.secondary : colorScheme.onSurface),
                          tooltip: 'Home',
                          onPressed: () => setState(() => _currentIndex = 0),
                        ),
                        IconButton(
                          icon: Icon(Icons.person, color: _currentIndex == 1 ? colorScheme.secondary : colorScheme.onSurface),
                          tooltip: 'Profile',
                          onPressed: () => setState(() => _currentIndex = 1),
                        ),
                        if (canUseScanner)
                          IconButton(
                            icon: Icon(Icons.camera_alt_outlined, color: colorScheme.onSurface),
                            tooltip: 'AI Scanner',
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiScannerScreen())),
                          ),
                        Container(
                          width: 1, height: 24,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ],
                      ValueListenableBuilder<int>(
                        valueListenable: themeNotifier,
                        builder: (context, themeIndex, _) {
                          IconData themeIcon = themeIndex == 0 ? Icons.light_mode : (themeIndex == 1 ? Icons.dark_mode : Icons.eco);
                          return IconButton(
                            icon: Icon(themeIcon, color: colorScheme.onSurface),
                            tooltip: 'Toggle Theme',
                            onPressed: () => themeNotifier.value = (themeIndex + 1) % 3,
                          );
                        },
                      ),
                      if (userRole == 'ngo')
                        IconButton(
                          icon: Icon(Icons.add_box_outlined, color: colorScheme.onSurface),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NgoRequestDrive())),
                        ),
                      if (userRole == 'landowner')
                        IconButton(
                          icon: Icon(Icons.add_location_alt, color: colorScheme.onSurface),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LandownerOfferLand())),
                        ),
                      if (userRole == 'company')
                        IconButton(
                          icon: Icon(Icons.business_center, color: colorScheme.onSurface),
                          tooltip: 'Corporate Dashboard',
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CompanyAddDrive())),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _currentIndex == 0
                  ? HomeScreen(userLat: userLat, userLng: userLng)
                  : const ProfileScreen(),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: (isDesktop || !canUseScanner) ? null : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: (isDesktop || !canUseScanner)
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiScannerScreen())),
              child: const Icon(Icons.eco, size: 32),
            ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home, size: 30),
                      color: _currentIndex == 0 ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5),
                      onPressed: () => setState(() => _currentIndex = 0),
                    ),
                    const SizedBox(width: 48), 
                    IconButton(
                      icon: const Icon(Icons.person, size: 30),
                      color: _currentIndex == 1 ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5),
                      onPressed: () => setState(() => _currentIndex = 1),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}