import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getUserToken() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString('USER_TOKEN')??'';
}
Future<String> getUserId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString('USER_ID')??'';
}

Future<String> getSignupApp() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString('SIGNUP_APP') ?? '0';
}




class GlobalState extends ChangeNotifier {
  static final GlobalState _instance = GlobalState._internal();
  
  factory GlobalState() {
    return _instance;
  }
  
  GlobalState._internal();
  
  String _username = '';
  bool _isInitialized = false;
  String _signupApp = '0';
  
  String get username => _username;
  bool get isInitialized => _isInitialized;
  String get signupApp => _signupApp;
  
  void setUsername(String newUsername) {
    _username = newUsername;
    _isInitialized = true;
    notifyListeners();
  }

  void setSignupApp(String value) {
    _signupApp = value;
    notifyListeners();
  }

  static bool isAudioDashboardMode() {
    return _audioMode ?? false;
  }

  static bool? _audioMode;

  static void setAudioDashboardMode(bool value) {
    _audioMode = value;
  }
}