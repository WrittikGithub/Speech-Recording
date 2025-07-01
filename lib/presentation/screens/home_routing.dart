import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeRoutingScreen extends StatefulWidget {
  const HomeRoutingScreen({super.key});

  @override
  State<HomeRoutingScreen> createState() => _HomeRoutingScreenState();
}

class _HomeRoutingScreenState extends State<HomeRoutingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineHomeScreen();
    });
  }

  Future<void> _determineHomeScreen() async {
    print('[HomeRouting] Determining home screen...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      // CRITICAL FIX: Check for authentication token first
      final userToken = prefs.getString('USER_TOKEN') ?? '';
      final userId = prefs.getString('USER_ID') ?? '';
      
      print('[HomeRouting] UserToken exists: ${userToken.isNotEmpty}');
      print('[HomeRouting] UserId exists: ${userId.isNotEmpty}');
      
      // If no valid authentication data, go to login
      if (userToken.isEmpty || userId.isEmpty) {
        print('[HomeRouting] No valid authentication found, navigating to login');
        
        if (!mounted) {
          print('[HomeRouting] Context not mounted, aborting navigation');
          return;
        }
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
          (route) => false,
        );
        return;
      }
      
      // User is authenticated, check signup_app for dashboard type
      // Use getString instead of getInt for consistency with how it's stored
      final signupApp = prefs.getString('SIGNUP_APP') ?? '0';
      
      print('[HomeRouting] User authenticated, SIGNUP_APP: $signupApp');

      if (!mounted) {
        print('[HomeRouting] Context not mounted, aborting navigation');
        return;
      }

      Widget targetScreen = signupApp == '1' 
          ? const ScreenMainPage(initialIndex: 0)
          : const ScreenMainPage();

      print('[HomeRouting] Navigating to ${targetScreen.runtimeType}');
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => targetScreen),
        (route) => false,
      );
    } catch (e) {
      print('[HomeRouting] Error: $e');
      
      // Only navigate to login if there's a legitimate error
      // Don't clear user data here - let the user remain logged in
      if (!mounted) {
        return;
      }
      
      // Try to check if we have basic auth data even if there was an error
      try {
        final prefs = await SharedPreferences.getInstance();
        final userToken = prefs.getString('USER_TOKEN') ?? '';
        
        if (userToken.isNotEmpty) {
          // User has token, try to navigate to main page anyway
          print('[HomeRouting] Error occurred but user has token, navigating to main page');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ScreenMainPage()),
            (route) => false,
          );
        } else {
          // No token, go to login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
            (route) => false,
          );
        }
      } catch (fallbackError) {
        print('[HomeRouting] Fallback error: $fallbackError');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}