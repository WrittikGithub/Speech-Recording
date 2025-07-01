
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




class GlobalState extends ChangeNotifier {
  static final GlobalState _instance = GlobalState._internal();
  
  factory GlobalState() {
    return _instance;
  }
  
  GlobalState._internal();
  
  String _username = '';
  bool _isInitialized = false;
  
  String get username => _username;
  bool get isInitialized => _isInitialized;
  
  void setUsername(String newUsername) {
    _username = newUsername;
    _isInitialized = true;
    notifyListeners();
  }
}