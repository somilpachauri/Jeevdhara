// lib/core/constants/api_constants.dart

import 'package:flutter/foundation.dart'; 

class ApiConstants {
  // Use a getter to return the correct URL based on platform
  static String get backendUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000'; // Chrome Web Localhost
    }
    // Android Emulator Localhost (Can't use 127.0.0.1 here)
    return 'http://10.0.2.2:8000'; 
  }
}