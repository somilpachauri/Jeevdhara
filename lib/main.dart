import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'welcome_screen.dart';
import 'ai_scanner.dart';
import 'ngo_request_drive.dart';
import 'landowner_offer_land.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const JeevdharaApp());
}

class JeevdharaApp extends StatelessWidget {
  const JeevdharaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeevdhara',
      debugShowCheckedModeBanner: false,
      theme: jeevdharaTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: lightGreen,
            body: Center(child: CircularProgressIndicator(color: darkGreen)),
          );
        }
        if (snapshot.hasData) {
          return const MainDashboard();
        }
        return const WelcomeScreen();
      },
    );
  }
}

// --- TABBED HOME SCREEN: FINAL OVERFLOW FIX ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          // BUMPED TO 140 to eliminate the 9.0px overflow
          preferredSize: const Size.fromHeight(140),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Constrain the column
              children: [
                const Padding(
                  padding: EdgeInsets.only(
                    top: 20.0,
                    bottom: 8.0,
                  ), // Balanced padding
                  child: Text(
                    "Community Feed",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const TabBar(
                  // Added const for performance
                  indicatorColor: harvestGold,
                  labelColor: harvestGold,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(icon: Icon(Icons.park), text: "Drives"),
                    Tab(icon: Icon(Icons.landscape), text: "Land"),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildListStream('plantation_requests', Icons.park, darkGreen),
            _buildListStream('land_offers', Icons.landscape, darkBrown),
          ],
        ),
      ),
    );
  }

  Widget _buildListStream(
    String collectionPath,
    IconData icon,
    Color themeColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error loading feed",
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: harvestGold),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              "No activity here yet.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            bool isLand = collectionPath == 'land_offers';

            return Card(
              color: Colors.white.withValues(alpha: 0.95),
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: themeColor,
                  child: Icon(icon, color: Colors.white),
                ),
                title: Text(
                  isLand
                      ? "Land: ${data['areaSize']}"
                      : "Drive in ${data['city']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                subtitle: Text(
                  isLand
                      ? "Location: ${data['location']}"
                      : (data['description'] ?? "No description"),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}

// --- RESTORED ProfileScreen ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              user?.email ?? "User Email",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  void _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          userRole = doc.data()?['role'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        title: const Text('Jeevdhara'),
        backgroundColor: darkGreen,
        actions: [
          if (userRole == 'ngo')
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NgoRequestDrive(),
                ),
              ),
            ),
          if (userRole == 'landowner')
            IconButton(
              icon: const Icon(
                Icons.add_location_alt,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LandownerOfferLand(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _currentIndex == 0 ? const HomeScreen() : const ProfileScreen(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AiScannerScreen()),
        ),
        shape: const CircleBorder(),
        backgroundColor: darkBrown,
        elevation: 8,
        child: const Icon(Icons.eco, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        color: darkGreen,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, size: 30),
                color: _currentIndex == 0 ? harvestGold : Colors.white,
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: const Icon(Icons.person, size: 30),
                color: _currentIndex == 1 ? harvestGold : Colors.white,
                onPressed: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
