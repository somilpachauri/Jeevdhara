import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/scanner/screens/ai_scanner.dart';
import 'features/community/screens/ngo_request_drive.dart';
import 'features/community/screens/landowner_offer_land.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/community/screens/company_add_drive.dart';
import 'features/auth/screens/auth_gate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final ValueNotifier<int> themeNotifier = ValueNotifier(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
        if (themeIndex == 0) {
          activeTheme = lightTheme;
        } else if (themeIndex == 1)
          activeTheme = darkTheme;
        else
          activeTheme = originalGreenTheme;

        return MaterialApp(
          title: 'Jeevdhara',
          debugShowCheckedModeBanner: false,
          theme: activeTheme.copyWith(
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}


