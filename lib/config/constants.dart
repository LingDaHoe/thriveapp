class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://api.thriveapp.com';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
  
  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration transitionDuration = Duration(milliseconds: 300);
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Cache
  static const Duration cacheDuration = Duration(days: 7);
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';
  
  // Success Messages
  static const String profileUpdateSuccess = 'Profile updated successfully.';
  static const String settingsUpdateSuccess = 'Settings updated successfully.';
  
  // App Info
  static const String appName = 'Thrive';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A wellness app for elderly users.';
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration locationTimeout = Duration(seconds: 10);
  
  // Limits
  static const int maxEmergencyContacts = 3;
  static const int maxProfileImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxMessageLength = 1000;
  
  // Default Values
  static const String defaultLanguage = 'en';
  static const double defaultFontSize = 16.0;
  static const bool defaultDarkMode = false;
  static const bool defaultNotifications = true;
} 