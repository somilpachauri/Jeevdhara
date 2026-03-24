

import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortChanged;

  const HomeAppBar({
    super.key,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(260); 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 12.0, left: 16.0, right: 16.0),
                child: Container(
                  width: 800, 
                  padding: const EdgeInsets.symmetric(vertical: 16), 
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.4), 
                    borderRadius: BorderRadius.circular(50), 
                  ),
                  child: const Center( 
                    child: Text(
                      "Community Feed",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, 
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: onSearchChanged,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: "Search by city, location...",
                          hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16),
                          prefixIcon: Icon(Icons.search, color: colorScheme.secondary),
                          filled: true,
                          fillColor: theme.cardTheme.color ?? colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30), 
                            borderSide: BorderSide.none
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.tune, color: colorScheme.secondary),
                        tooltip: "Sort Feed",
                        onSelected: onSortChanged,
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'date_desc', child: Text("Newest First", style: TextStyle(color: colorScheme.onSurface))),
                          PopupMenuItem(value: 'date_asc', child: Text("Oldest First", style: TextStyle(color: colorScheme.onSurface))),
                          PopupMenuItem(value: 'distance', child: Text("Closest to Me (GPS)", style: TextStyle(color: colorScheme.onSurface))),
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
    );
  }
}