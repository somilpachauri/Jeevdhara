import 'package:flutter/material.dart';

// Your Emerald Harvest Twilight Palette
const Color lightGreen = Color(0xFF397234); // Main background
const Color darkGreen = Color(0xFF283F23); // App bar & Bottom Nav
const Color darkBrown = Color(0xFF3F2617); // FAB
const Color harvestGold = Color(0xFFACBD5E);

ThemeData jeevdharaTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: lightGreen,

  appBarTheme: const AppBarTheme(
    backgroundColor: darkGreen,
    foregroundColor: Colors.white, // White text
    elevation: 0,
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: darkBrown,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: darkGreen,
    selectedItemColor: harvestGold,
    unselectedItemColor: Colors.white70,
    type: BottomNavigationBarType.fixed,
  ),
);
