import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Needed for distance sorting
import 'firebase_options.dart';
import 'app_theme.dart';
import 'welcome_screen.dart';
import 'ai_scanner.dart';
import 'ngo_request_drive.dart';
import 'landowner_offer_land.dart';
import 'profile_screen.dart';

final ValueNotifier<int> themeNotifier = ValueNotifier(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const JeevdharaApp());
}

class JeevdharaApp extends StatelessWidget {
  const JeevdharaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeNotifier,
      builder: (context, themeIndex, _) {
        ThemeData activeTheme;
        if (themeIndex == 0)
          activeTheme = lightTheme;
        else if (themeIndex == 1)
          activeTheme = darkTheme;
        else
          activeTheme = originalGreenTheme;

        return MaterialApp(
          title: 'Jeevdhara',
          debugShowCheckedModeBanner: false,
          theme: activeTheme,
          home: const AuthGate(),
        );
      },
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
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) return const MainDashboard();
        return const WelcomeScreen();
      },
    );
  }
}

// --- UPDATED: HOME SCREEN ACCEPTS USER LOCATION ---
class HomeScreen extends StatefulWidget {
  final double? userLat;
  final double? userLng;
  const HomeScreen({super.key, this.userLat, this.userLng});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = "";
  String _sortOption = "date_desc"; // Default sorting

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
                      child: Text(
                        "Community Feed",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          // Search Bar
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: "Search by city, location...",
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: colorScheme.secondary,
                                ),
                                filled: true,
                                fillColor:
                                    theme.cardTheme.color ??
                                    colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // --- NEW: SORT BUTTON ---
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  theme.cardTheme.color ?? colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.tune,
                                color: colorScheme.secondary,
                              ),
                              tooltip: "Sort Feed",
                              onSelected: (value) =>
                                  setState(() => _sortOption = value),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'date_desc',
                                  child: Text(
                                    "Newest First",
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'date_asc',
                                  child: Text(
                                    "Oldest First",
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'distance',
                                  child: Text(
                                    "Closest to Me (GPS)",
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.park), text: "Drives"),
                        Tab(icon: Icon(Icons.landscape), text: "Land"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _FeedGrid(
              collectionPath: 'plantation_requests',
              icon: Icons.park,
              searchQuery: _searchQuery,
              sortOption: _sortOption,
              userLat: widget.userLat,
              userLng: widget.userLng,
            ),
            _FeedGrid(
              collectionPath: 'land_offers',
              icon: Icons.landscape,
              searchQuery: _searchQuery,
              sortOption: _sortOption,
              userLat: widget.userLat,
              userLng: widget.userLng,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedGrid extends StatelessWidget {
  final String collectionPath;
  final IconData icon;
  final String searchQuery;
  final String sortOption;
  final double? userLat;
  final double? userLng;

  const _FeedGrid({
    required this.collectionPath,
    required this.icon,
    required this.searchQuery,
    required this.sortOption,
    this.userLat,
    this.userLng,
  });

  Future<void> _joinDrive(BuildContext context, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('plantation_requests')
          .doc(docId)
          .update({
            'participants': FieldValue.arrayUnion([user.uid]),
          });
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed up! 🌿')),
        );
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isLand = collectionPath == 'land_offers';
    final accentColor = colorScheme.secondary;
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      // Initial fetch order doesn't matter as we sort it locally below
      stream: FirebaseFirestore.instance.collection(collectionPath).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(
            child: Text(
              "Error loading feed",
              style: TextStyle(color: colorScheme.onSurface),
            ),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        List<QueryDocumentSnapshot> docs = snapshot.data?.docs.toList() ?? [];

        // 1. Filter by Search Query
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (isLand) {
              return (data['location']?.toString().toLowerCase().contains(
                        query,
                      ) ??
                      false) ||
                  (data['areaSize']?.toString().toLowerCase().contains(query) ??
                      false);
            } else {
              return (data['city']?.toString().toLowerCase().contains(query) ??
                      false) ||
                  (data['description']?.toString().toLowerCase().contains(
                        query,
                      ) ??
                      false);
            }
          }).toList();
        }

        // 2. Apply Sorting Logic (Date or Distance)
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          if (sortOption == 'date_asc') {
            Timestamp tA = dataA['createdAt'] ?? Timestamp.now();
            Timestamp tB = dataB['createdAt'] ?? Timestamp.now();
            return tA.compareTo(tB);
          } else if (sortOption == 'distance' &&
              userLat != null &&
              userLng != null) {
            // Distance Calculation Sorting
            double latA = (dataA['latitude'] ?? 0.0) is int
                ? (dataA['latitude'] ?? 0).toDouble()
                : (dataA['latitude'] ?? 0.0);
            double lngA = (dataA['longitude'] ?? 0.0) is int
                ? (dataA['longitude'] ?? 0).toDouble()
                : (dataA['longitude'] ?? 0.0);
            double latB = (dataB['latitude'] ?? 0.0) is int
                ? (dataB['latitude'] ?? 0).toDouble()
                : (dataB['latitude'] ?? 0.0);
            double lngB = (dataB['longitude'] ?? 0.0) is int
                ? (dataB['longitude'] ?? 0).toDouble()
                : (dataB['longitude'] ?? 0.0);

            // Push posts with missing locations to the bottom
            if (latA == 0.0 && lngA == 0.0) return 1;
            if (latB == 0.0 && lngB == 0.0) return -1;

            double distA = Geolocator.distanceBetween(
              userLat!,
              userLng!,
              latA,
              lngA,
            );
            double distB = Geolocator.distanceBetween(
              userLat!,
              userLng!,
              latB,
              lngB,
            );
            return distA.compareTo(distB);
          }
          // Default: date_desc
          Timestamp tA = dataA['createdAt'] ?? Timestamp.now();
          Timestamp tB = dataB['createdAt'] ?? Timestamp.now();
          return tB.compareTo(tA);
        });

        if (docs.isEmpty)
          return Center(
            child: Text(
              searchQuery.isEmpty
                  ? "No activity here yet."
                  : "No results found.",
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          );

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: isLand ? 160 : 210,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            String dateString = "Date TBD";
            if (!isLand &&
                data.containsKey('driveDate') &&
                data['driveDate'] != null) {
              DateTime dt = (data['driveDate'] as Timestamp).toDate();
              dateString = "${dt.day}/${dt.month}/${dt.year}";
            }

            List<dynamic> participants = data['participants'] ?? [];
            int participantCount = participants.length;
            bool hasJoined = participants.contains(currentUserUid);

            // Distance Tag (If user is sorting by distance)
            String distanceTag = "";
            if (sortOption == 'distance' &&
                userLat != null &&
                userLng != null &&
                data['latitude'] != null) {
              double targetLat = data['latitude'] is int
                  ? data['latitude'].toDouble()
                  : data['latitude'];
              double targetLng = data['longitude'] is int
                  ? data['longitude'].toDouble()
                  : data['longitude'];
              double distInMeters = Geolocator.distanceBetween(
                userLat!,
                userLng!,
                targetLat,
                targetLng,
              );
              distanceTag =
                  " (${(distInMeters / 1000).toStringAsFixed(1)}km away)";
            }

            return Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accentColor, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isLand
                              ? "Available$distanceTag"
                              : "$dateString$distanceTag",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    isLand
                        ? "Land: ${data['areaSize']}"
                        : "Drive in ${data['city']}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isLand ? Icons.location_on : Icons.notes,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isLand
                              ? "${data['location']}"
                              : "${data['description'] ?? 'No description'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (!isLand) ...[
                    const SizedBox(height: 12),
                    Divider(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, size: 16, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              "$participantCount Joined",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: hasJoined
                                ? null
                                : () => _joinDrive(context, doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasJoined
                                  ? colorScheme.onSurface.withValues(alpha: 0.2)
                                  : accentColor,
                              foregroundColor: hasJoined
                                  ? colorScheme.onSurface
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: Text(hasJoined ? "Joined" : "Sign Up"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          userRole = data['role'];
          // This now works for NGO, Landowner, and Volunteer roles
          if (data['searchLatitude'] != null) {
            userLat = (data['searchLatitude'] is int)
                ? (data['searchLatitude'] as int).toDouble()
                : data['searchLatitude'];
          }
          if (data['searchLongitude'] != null) {
            userLng = (data['searchLongitude'] is int)
                ? (data['searchLongitude'] as int).toDouble()
                : data['searchLongitude'];
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jeevdhara'),
        actions: [
          if (isDesktop) ...[
            IconButton(
              icon: Icon(
                Icons.home,
                color: _currentIndex == 0
                    ? colorScheme.secondary
                    : colorScheme.onPrimary,
              ),
              tooltip: 'Home',
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                color: _currentIndex == 1
                    ? colorScheme.secondary
                    : colorScheme.onPrimary,
              ),
              tooltip: 'Profile',
              onPressed: () => setState(() => _currentIndex = 1),
            ),
            IconButton(
              icon: Icon(Icons.eco, color: colorScheme.onPrimary),
              tooltip: 'Scanner',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiScannerScreen(),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: colorScheme.onPrimary.withValues(alpha: 0.3),
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
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
                icon: Icon(themeIcon, color: colorScheme.onPrimary),
                tooltip: 'Toggle Theme',
                onPressed: () => themeNotifier.value = (themeIndex + 1) % 3,
              );
            },
          ),
          if (userRole == 'ngo')
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: colorScheme.onPrimary,
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
              icon: Icon(Icons.add_location_alt, color: colorScheme.onPrimary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LandownerOfferLand(),
                ),
              ),
            ),
        ],
      ),
      // Pass the extracted location coordinates directly to the HomeScreen for Geohashing
      body: _currentIndex == 0
          ? HomeScreen(userLat: userLat, userLng: userLng)
          : const ProfileScreen(),
      floatingActionButtonLocation: isDesktop
          ? null
          : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiScannerScreen(),
                ),
              ),
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
                      color: _currentIndex == 0
                          ? colorScheme.onPrimary
                          : colorScheme.onPrimary.withValues(alpha: 0.5),
                      onPressed: () => setState(() => _currentIndex = 0),
                    ),
                    const SizedBox(width: 48),
                    IconButton(
                      icon: const Icon(Icons.person, size: 30),
                      color: _currentIndex == 1
                          ? colorScheme.onPrimary
                          : colorScheme.onPrimary.withValues(alpha: 0.5),
                      onPressed: () => setState(() => _currentIndex = 1),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
