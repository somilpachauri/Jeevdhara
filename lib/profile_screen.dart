import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  bool _isSavingLocation = false;

  // --- UPDATED: RESTRICTED HACKATHON DATA ---
  final Map<String, List<String>> _stateCityMap = {
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala'],
    'Himachal Pradesh': ['Shimla', 'Solan', 'Dharamshala', 'Mandi'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Rishikesh'],
    'West Bengal': ['Kolkata', 'Siliguri', 'Asansol', 'Durgapur'],
  };

  String? _selectedState;
  String? _selectedCity;
  List<String> _availableCities = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          String? savedState = data['preferredState'];
          String? savedCity = data['preferredCity'];

          // Safely load saved data into the dropdowns
          if (savedState != null && _stateCityMap.containsKey(savedState)) {
            _selectedState = savedState;
            _availableCities = _stateCityMap[savedState]!;
            if (savedCity != null && _availableCities.contains(savedCity)) {
              _selectedCity = savedCity;
            }
          }
        });
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    final data = await UserService.fetchLeaderboard();
    if (mounted) {
      setState(() {
        _leaderboard = data;
        _isLoading = false;
      });
    }
  }

  // --- BULLETPROOF GPS FETCHING ---
  Future<void> _autoDetectLocation() async {
    setState(() => _isSavingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        String fetchedState = placemarks.first.administrativeArea ?? '';
        String fetchedCity = placemarks.first.locality ?? '';

        setState(() {
          // Dynamic Injection: Ensures the app handles real-world GPS results
          // even if they are slightly outside the hardcoded list
          if (!_stateCityMap.containsKey(fetchedState)) {
            _stateCityMap[fetchedState] = [fetchedCity];
          } else if (!_stateCityMap[fetchedState]!.contains(fetchedCity)) {
            _stateCityMap[fetchedState]!.add(fetchedCity);
          }

          _selectedState = fetchedState;
          _availableCities = _stateCityMap[fetchedState]!;
          _selectedCity = fetchedCity;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location auto-detected successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("GPS Error: $e")));
    } finally {
      setState(() => _isSavingLocation = false);
    }
  }

  Future<void> _saveProfileDetails() async {
    if (_selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a State and City.")),
      );
      return;
    }

    setState(() => _isSavingLocation = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'preferredState': _selectedState,
        'preferredCity': _selectedCity,
      }, SetOptions(merge: true));

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile location saved!")),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    } finally {
      setState(() => _isSavingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final username = user?.email?.split('@')[0] ?? "Volunteer";
    final myStats = UserService.getUserStats(_leaderboard, username);
    final userBadges = myStats['badges'] as List<dynamic>? ?? [];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.secondary,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- PROFILE HEADER ---
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: colorScheme.secondary.withValues(
                                alpha: 0.2,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?.displayName ?? username,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              user?.email ?? "email@example.com",
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- PROFILE DETAILS & LOCATION SELECTION ---
                      Text(
                        "Profile Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Dropdowns Row
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded:
                                        true, // FIXED: Prevents pixel overflow
                                    value: _selectedState,
                                    dropdownColor:
                                        theme.cardTheme.color ??
                                        colorScheme.surface,
                                    decoration: InputDecoration(
                                      labelText: 'State',
                                      filled: true,
                                      fillColor: colorScheme.onSurface
                                          .withValues(alpha: 0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: _stateCityMap.keys
                                        .map(
                                          (state) => DropdownMenuItem(
                                            value: state,
                                            child: Text(
                                              state,
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedState = value;
                                        _availableCities =
                                            _stateCityMap[value!]!;
                                        _selectedCity =
                                            null; // Reset city when state changes
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded:
                                        true, // FIXED: Prevents pixel overflow
                                    value: _selectedCity,
                                    dropdownColor:
                                        theme.cardTheme.color ??
                                        colorScheme.surface,
                                    decoration: InputDecoration(
                                      labelText: 'City',
                                      filled: true,
                                      fillColor: colorScheme.onSurface
                                          .withValues(alpha: 0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: _availableCities
                                        .map(
                                          (city) => DropdownMenuItem(
                                            value: city,
                                            child: Text(
                                              city,
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => _selectedCity = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isSavingLocation
                                        ? null
                                        : _autoDetectLocation,
                                    icon: const Icon(Icons.my_location),
                                    label: const Text("Auto-Detect GPS"),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      foregroundColor: colorScheme.secondary,
                                      side: BorderSide(
                                        color: colorScheme.secondary.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSavingLocation
                                        ? null
                                        : _saveProfileDetails,
                                    icon: _isSavingLocation
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: const Text("Save Location"),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- DYNAMIC BADGES ---
                      Text(
                        "Badges & Achievements",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (userBadges.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "No badges earned yet. Scan plants to rank up!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: userBadges.map((badge) {
                            if (badge == "Rookie Scout")
                              return _buildBadgeCard(
                                context,
                                Icons.eco,
                                "Scout",
                                colorScheme.secondary,
                              );
                            if (badge == "Biodiversity Guardian")
                              return _buildBadgeCard(
                                context,
                                Icons.local_fire_department,
                                "Guardian",
                                Colors.orange,
                              );
                            return _buildBadgeCard(
                              context,
                              Icons.star,
                              badge.toString(),
                              Colors.blue,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 40),

                      // --- LIVE LEADERBOARD ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Global Leaderboard",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadLeaderboard,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                        child: _leaderboard.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    "No data found from backend API.",
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: List.generate(_leaderboard.length, (
                                  index,
                                ) {
                                  final entry = _leaderboard[index];
                                  final name = entry[0];
                                  final points = entry[1]['points'];
                                  return Column(
                                    children: [
                                      _buildLeaderboardRow(
                                        context,
                                        index + 1,
                                        name,
                                        points,
                                        isGold: index == 0,
                                        isYou: name == username,
                                      ),
                                      if (index < _leaderboard.length - 1)
                                        Divider(
                                          height: 1,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.1),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                      ),
                      const SizedBox(height: 48),

                      // --- PROMINENT LOGOUT BUTTON ---
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async =>
                              await FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "Log Out",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(
    BuildContext context,
    int rank,
    String name,
    int points, {
    bool isGold = false,
    bool isYou = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isGold
            ? Colors.amber.withValues(alpha: 0.2)
            : colorScheme.onSurface.withValues(alpha: 0.05),
        child: Text(
          "#$rank",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isGold ? Colors.amber : colorScheme.onSurface,
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isYou ? FontWeight.bold : FontWeight.normal,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: Text(
        "$points pts",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
        ),
      ),
    );
  }
}
