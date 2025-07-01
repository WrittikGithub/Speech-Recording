// Configuration for Apple Sign-In
class AppleSignInConfig {
  // Package name/Bundle ID of your app (required for Android)
  static const String packageName = 'com.langlex.speech';
  
  // Standard Android redirect URL from the sign_in_with_apple example
  static const String redirectUri = 'https://flutter-sign-in-with-apple-example.glitch.me/callbacks/sign_in_with_apple';
  
  // Backend API endpoints
  static const String appleAuthBackendUrl = 'https://lexspeech-api.langlex.ai/api/social_login';
  static const String appleCompleteRegistrationUrl = 'https://lexspeech-api.langlex.ai/api/complete_apple_registration';
} 