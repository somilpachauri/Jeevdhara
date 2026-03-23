import 'package:flutter/material.dart';

class FeedCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLand;
  final bool isCompany;
  final String distanceText;
  final String dateString;
  final String areaString;
  final int participantCount;
  final bool hasJoined;
  final IconData icon;
  final VoidCallback onToggleJoin;

  const FeedCard({
    super.key,
    required this.data,
    required this.isLand,
    required this.isCompany,
    required this.distanceText,
    required this.dateString,
    required this.areaString,
    required this.participantCount,
    required this.hasJoined,
    required this.icon,
    required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Color Bar
            Container(
              height: 6,
              color: isCompany ? colorScheme.primary : accentColor,
            ),
            // Main Content Padding
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(colorScheme, accentColor),
                  const SizedBox(height: 16),
                  _buildTitle(colorScheme),
                  const SizedBox(height: 8),
                  _buildLocationOrDescription(colorScheme),
                  if (isCompany && (data['resourcesProvided'] ?? []).isNotEmpty)
                    _buildResources(data['resourcesProvided']),
                ],
              ),
            ),
            // Bottom Action Bar
            if (!isLand) _buildActionBar(colorScheme, accentColor),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER METHODS EXTRACTED FOR READABILITY ---
  
  Widget _buildHeader(ColorScheme colorScheme, Color accentColor) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: accentColor.withValues(alpha: 0.15),
          child: Icon(isCompany ? Icons.business : icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLand ? "Land Offer" : (isCompany ? "CSR Drive" : "Plantation Drive"),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              isLand ? "Available$distanceText" : "$dateString$distanceText",
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitle(ColorScheme colorScheme) {
    return Text(
      isLand ? "Area: $areaString" : (isCompany ? "${data['companyName']} in ${data['city']}" : "Drive in ${data['city']}"),
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
    );
  }

  Widget _buildLocationOrDescription(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isLand ? Icons.location_on : Icons.notes, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isLand ? "${data['location']}" : "${data['description'] ?? 'No description provided.'}",
            style: TextStyle(fontSize: 14, height: 1.4, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildResources(List<dynamic> resources) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: resources.map((res) => Chip(
          label: Text(res.toString(), style: const TextStyle(fontSize: 12, color: Colors.green)),
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
          avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
        )).toList(),
      ),
    );
  }

  Widget _buildActionBar(ColorScheme colorScheme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: colorScheme.onSurface.withValues(alpha: 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.people, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Text("$participantCount Joined", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
            ],
          ),
          ElevatedButton(
            onPressed: onToggleJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasJoined ? Colors.redAccent.withValues(alpha: 0.1) : accentColor,
              foregroundColor: hasJoined ? Colors.redAccent : Colors.white,
              elevation: hasJoined ? 0 : 2,
            ),
            child: Text(hasJoined ? "Leave Drive" : "Sign Up"),
          ),
        ],
      ),
    );
  }
}