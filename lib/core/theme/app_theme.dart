import 'package:flutter/material.dart';

// ==========================================
// 1. ORIGINAL GREEN THEME
// ==========================================
const Color lightGreen = Color(0xFFE8F5E9);
const Color darkGreen = Color(0xFF2E7D32);
const Color harvestGold = Color(0xFFFBC02D);
const Color darkBrown = Color(0xFF5D4037);

final ThemeData originalGreenTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: darkGreen,
  scaffoldBackgroundColor: lightGreen,
  colorScheme: const ColorScheme.light(
    primary: darkGreen,
    secondary: darkBrown,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Colors.black87,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: darkGreen,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkGreen,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: darkGreen,
    unselectedLabelColor: darkGreen.withValues(alpha: 0.5),
    indicatorColor: darkGreen,
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(color: darkGreen),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: darkBrown,
    foregroundColor: Colors.white,
  ),
);

// ==========================================
// 2. "STORMY MORNING" LIGHT THEME
// ==========================================
const Color stormBg = Color(0xFFBDDDFC);
const Color stormSurface = Color(0xFFFFFFFF);
const Color stormPrimary = Color(0xFF384959);
const Color stormAccent = Color(0xFF88BDF2);
const Color stormText = Color(0xFF1A1D1A);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: stormPrimary,
  scaffoldBackgroundColor: stormBg,
  colorScheme: const ColorScheme.light(
    primary: stormPrimary,
    secondary: stormAccent,
    surface: stormSurface,
    onPrimary: Colors.white,
    onSurface: stormText,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: stormPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: stormSurface,
    elevation: 2,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: stormPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: stormPrimary,
    unselectedLabelColor: stormPrimary.withValues(alpha: 0.5),
    indicatorColor: stormPrimary,
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(color: stormPrimary),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: stormAccent,
    foregroundColor: Colors.white,
  ),
);

// ==========================================
// 3. "REACT DEV" DARK THEME (From Screenshot)
// ==========================================
const Color reactBg = Color(0xFF23272F); // Dark slate background
const Color reactSurface = Color(0xFF343A46); // Slightly lighter for cards
const Color reactPrimary = Color(
  0xFF23272F,
); // Matches background for clean look
const Color reactAccent = Color(0xFF149ECA); // Vibrant Cyan
const Color reactText = Color(0xFFF6F7F9); // Crisp off-white

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: reactPrimary,
  scaffoldBackgroundColor: reactBg,
  colorScheme: const ColorScheme.dark(
    primary: reactPrimary,
    secondary: reactAccent,
    surface: reactSurface,
    onPrimary: Colors.white,
    onSurface: reactText,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: reactBg, // Flat modern look
    foregroundColor: reactText,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: reactSurface,
    elevation: 0, // Flat design similar to modern web
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ), // Slightly softer edges
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: reactAccent,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: reactAccent,
    unselectedLabelColor: Colors.white38,
    indicatorColor: reactAccent,
  ),
  bottomAppBarTheme: const BottomAppBarThemeData(color: reactSurface),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: reactAccent,
    foregroundColor: Colors.white,
  ),
);
