

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/screens/auth_gate.dart';
import '../logic/profile_repository.dart';
import '../../../core/utils/location_service.dart';
import '../logic/leaderboard_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final LocationService _locationService = LocationService();
  final LeaderboardRepository _leaderboardRepository = LeaderboardRepository();

  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  bool _isSavingLocation = false;

  String? _userRole;
  String? _companyName;
  int _corporateDrivesHosted = 0;
  int _totalCorporateVolunteers = 0;

  final Map<String, List<String>> _stateCityMap = {
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala'],
    'Himachal Pradesh': ['Shimla', 'Solan', 'Dharamshala', 'Mandi'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Rishikesh'],
    'West Bengal': ['Kolkata', 'Siliguri', 'Asansol', 'Durgapur'],
    'Uttar Pradesh': ['Agra', 'Lucknow', 'Kanpur', 'Varanasi', 'Noida'],
  };

  String? _selectedState;
  String? _selectedCity;
  List<String> _availableCities = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userData = await _profileRepository.fetchUserData();
      if (userData != null) {
        setState(() {
          _userRole = userData['role'];
          _companyName = userData['companyName'];

          String? savedState = userData['preferredState'];
          String? savedCity = userData['preferredCity'];

          if (savedState != null && _stateCityMap.containsKey(savedState)) {
            _selectedState = savedState;
            _availableCities = _stateCityMap[savedState]!;
            if (savedCity != null && _availableCities.contains(savedCity)) {
              _selectedCity = savedCity;
            }
          }
        });

        if (_userRole == 'company') {
          final impact = await _profileRepository.fetchCorporateImpact();
          setState(() {
            _corporateDrivesHosted = impact['drives'] ?? 0;
            _totalCorporateVolunteers = impact['volunteers'] ?? 0;
          });
        } else {
          final data = await _leaderboardRepository.fetchLeaderboard();
          setState(() {
            _leaderboard = data;
          });
        }
      }
    } catch (e) {
      _showSnackBar("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isSavingLocation = true);
    try {
      final result = await _locationService.getCurrentLocationDetails();
      
      String fetchedCity = result.city;
      String fetchedState = "";
      
      _stateCityMap.forEach((state, cities) {
        if(cities.contains(fetchedCity)) fetchedState = state;
      });

      if (fetchedState.isNotEmpty) {
        setState(() {
          _selectedState = fetchedState;
          _availableCities = _stateCityMap[fetchedState]!;
          _selectedCity = fetchedCity;
        });
        _showSnackBar("Location auto-detected successfully!");
      } else {
        _showSnackBar("Detected location not supported in hackathon map.");
      }
    } catch (e) {
      _showSnackBar("GPS Error: $e");
    } finally {
      setState(() => _isSavingLocation = false);
    }
  }

  Future<void> _saveProfileDetails() async {
    if (_selectedState == null || _selectedCity == null) return;
    setState(() => _isSavingLocation = true);
    try {
      await _profileRepository.saveProfileLocation(_selectedState!, _selectedCity!);
      _showSnackBar("Profile location saved!");
    } catch (e) {
      _showSnackBar("Error saving: $e");
    } finally {
      setState(() => _isSavingLocation = false);
    }
  }

  Future<void> _handleLogout() async {
    await _profileRepository.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final username = user?.email?.split('@')[0] ?? "Volunteer";
    final myStats = _leaderboardRepository.getUserStats(_leaderboard, username);
    final userBadges = myStats['badges'] as List<dynamic>? ?? [];

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.secondary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: _userRole == 'company'
                                  ? colorScheme.primary.withValues(alpha: 0.2)
                                  : colorScheme.secondary.withValues(alpha: 0.2),
                              child: Icon(
                                _userRole == 'company' ? Icons.business : Icons.person,
                                size: 50,
                                color: _userRole == 'company' ? colorScheme.primary : colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _companyName ?? user?.displayName ?? username,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _userRole == 'company' ? "Corporate CSR Partner" : (user?.email ?? ""),
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        "Region Preferences",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _selectedState,
                                    dropdownColor: theme.cardTheme.color ?? colorScheme.surface,
                                    decoration: InputDecoration(
                                      labelText: 'State',
                                      filled: true,
                                      fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: _stateCityMap.keys.map((state) => DropdownMenuItem(
                                      value: state,
                                      child: Text(state, style: TextStyle(color: colorScheme.onSurface)),
                                    )).toList(),
                                    onChanged: (value) => setState(() {
                                      _selectedState = value;
                                      _availableCities = _stateCityMap[value!]!;
                                      _selectedCity = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _selectedCity,
                                    dropdownColor: theme.cardTheme.color ?? colorScheme.surface,
                                    decoration: InputDecoration(
                                      labelText: 'City',
                                      filled: true,
                                      fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: _availableCities.map((city) => DropdownMenuItem(
                                      value: city,
                                      child: Text(city, style: TextStyle(color: colorScheme.onSurface)),
                                    )).toList(),
                                    onChanged: (value) => setState(() => _selectedCity = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isSavingLocation ? null : _autoDetectLocation,
                                    icon: const Icon(Icons.my_location),
                                    label: const Text("Auto GPS"),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      foregroundColor: colorScheme.secondary,
                                      side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.5)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSavingLocation ? null : _saveProfileDetails,
                                    icon: _isSavingLocation
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.save),
                                    label: const Text("Save"),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_userRole == 'company') ...[
                        Text(
                          "CSR & Carbon Impact",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.energy_savings_leaf, color: Colors.white, size: 30),
                                  SizedBox(width: 12),
                                  Text("Estimated Impact", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildCorporateStat("Drives Hosted", "$_corporateDrivesHosted"),
                                  _buildCorporateStat("CO2 Offset", "${_corporateDrivesHosted * 150} kg"),
                                  _buildCorporateStat("Volunteers", "$_totalCorporateVolunteers"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          "Badges & Achievements",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        if (userBadges.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "No badges earned yet. Scan plants to rank up!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 24, runSpacing: 16,
                            children: userBadges.map((badge) {
                              if (badge == "Rookie Scout") return _buildBadgeCard(context, Icons.eco, "Scout", colorScheme.secondary);
                              if (badge == "Biodiversity Guardian") return _buildBadgeCard(context, Icons.local_fire_department, "Guardian", Colors.orange);
                              return _buildBadgeCard(context, Icons.star, badge.toString(), Colors.blue);
                            }).toList(),
                          ),
                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Global Leaderboard",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProfileData),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color ?? colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
                          ),
                          child: _leaderboard.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Center(child: Text("No data found.", style: TextStyle(color: colorScheme.onSurface))),
                                )
                              : Column(
                                  children: List.generate(_leaderboard.length, (index) {
                                    final entry = _leaderboard[index];
                                    return Column(
                                      children: [
                                        _buildLeaderboardRow(
                                          context,
                                          index + 1,
                                          entry[0],
                                          entry[1]['points'],
                                          isGold: index == 0,
                                          isYou: entry[0] == username,
                                        ),
                                        if (index < _leaderboard.length - 1)
                                          Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                                      ],
                                    );
                                  }),
                                ),
                        ),
                      ],
                      const SizedBox(height: 48),

                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text("Log Out", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCorporateStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildBadgeCard(BuildContext context, IconData icon, String label, Color color) {
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
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildLeaderboardRow(BuildContext context, int rank, String name, int points, {bool isGold = false, bool isYou = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isGold ? Colors.amber.withValues(alpha: 0.2) : colorScheme.onSurface.withValues(alpha: 0.05),
        child: Text("#$rank", style: TextStyle(fontWeight: FontWeight.bold, color: isGold ? Colors.amber : colorScheme.onSurface)),
      ),
      title: Text(name, style: TextStyle(fontWeight: isYou ? FontWeight.bold : FontWeight.normal, color: colorScheme.onSurface)),
      trailing: Text("$points pts", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
    );
  }
}