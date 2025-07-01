// import 'package:flutter/material.dart';
// import 'package:sdcp_rebuild/presentation/screens/home_routing.dart';
// import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';
// import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';

// import 'package:sdcp_rebuild/core/appconstants.dart';
// import 'package:sdcp_rebuild/core/colors.dart';

// import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
// // import 'package:sdcp_rebuild/presentation/screens/debug_audio.dart';

// class AdvancedSplashScreen extends StatefulWidget {
//   const AdvancedSplashScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _AdvancedSplashScreenState createState() => _AdvancedSplashScreenState();
// }

// class _AdvancedSplashScreenState extends State<AdvancedSplashScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//   late AnimationController _rotationController;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );

//     _animation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     );

//     _rotationController = AnimationController(
//       duration: const Duration(seconds: 10),
//       vsync: this,
//     )..repeat();

//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween(begin: 1.0, end: 1.2).animate(_pulseController);

//     _controller.forward();
    
//     checkUserlogin(context);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _rotationController.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Appcolors.kwhiteColor,
//       body: Center(
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             // Background rotating circle
//             RotationTransition(
//               turns: _rotationController,
//               child: Container(
//                 width: 250,
//                 height: 250,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     colors: [
//                       Appcolors.kpurplelightColor,
//                       Appcolors.kskybluecolor.withOpacity(.7)
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             // Pulsing effect
//             ScaleTransition(
//               scale: _pulseAnimation,
//               child: Container(
//                 width: 220,
//                 height: 220,
//                 decoration: const BoxDecoration(
//                     shape: BoxShape.circle, color: Appcolors.kpurplelightColor),
//               ),
//             ),
//             // Logo with fade and scale effect
//             ScaleTransition(
//               scale: _animation,
//               child: FadeTransition(
//                 opacity: _animation,
//                 child: Image.asset(
//                   Appconstants.logo,
//                   width: 150,
//                   height: 150,
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 20,
//               right: 20,
//               child: Opacity(
//                 opacity: 0.7,
//                 child: ElevatedButton(
//                   onPressed: () => _navigateToDebugAudio(context),
//                   child: Text("Debug Audio"),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> checkUserlogin(BuildContext context) async {
//     try {
//       final String usertoken = await getUserToken();
//       print('User token from SharedPreferences: $usertoken');
      
//       if (usertoken.isEmpty) {
//         print('No token found, navigating to login page...');
//         await Future.delayed(const Duration(seconds: 3));
//         navigatePushandRemoveuntil(context, const ScreenLoginPage());
//       } else {
//         print('Token found, routing to appropriate dashboard');
//         navigatePushandRemoveuntil(context, const HomeRoutingScreen());
//       }
//     } catch (e) {
//       print('Error in checkUserlogin: $e');
//       // If there's any error, navigate to login page as fallback
//       await Future.delayed(const Duration(seconds: 3));
//       navigatePushandRemoveuntil(context, const ScreenLoginPage());
//     }
//   }

//   void _navigateToDebugAudio(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => DebugAudioPage()),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/core/appconstants.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';
import 'package:sdcp_rebuild/presentation/screens/home_routing.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvancedSplashScreen extends StatefulWidget {
  const AdvancedSplashScreen({super.key});

  @override
  _AdvancedSplashScreenState createState() => _AdvancedSplashScreenState();
}

class _AdvancedSplashScreenState extends State<AdvancedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween(begin: 1.0, end: 1.2).animate(_pulseController);

    _controller.forward();
    
    // FIXED: Check user authentication before navigating
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkUserAuthentication();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.kwhiteColor,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background rotating circle
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Appcolors.kpurplelightColor,
                      Appcolors.kskybluecolor.withOpacity(.7)
                    ],
                  ),
                ),
              ),
            ),
            // Pulsing effect
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Appcolors.kpurplelightColor),
              ),
            ),
            // Logo with fade and scale effect
            ScaleTransition(
              scale: _animation,
              child: FadeTransition(
                opacity: _animation,
                child: Image.asset(
                  Appconstants.logo,
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Proper authentication check
  Future<void> _checkUserAuthentication() async {
    print("[SplashScreen] Checking user authentication...");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('USER_TOKEN') ?? '';
      final userId = prefs.getString('USER_ID') ?? '';
      
      print("[SplashScreen] UserToken exists: ${userToken.isNotEmpty}");
      print("[SplashScreen] UserId exists: ${userId.isNotEmpty}");
      
      if (!mounted) return;
      
      if (userToken.isNotEmpty && userId.isNotEmpty) {
        // User is logged in, navigate to HomeRoutingScreen which will determine the correct dashboard
        print("[SplashScreen] User authenticated, navigating to HomeRoutingScreen");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeRoutingScreen()),
          (route) => false,
        );
      } else {
        // User not logged in, go to login page
        print("[SplashScreen] User not authenticated, navigating to login");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print("[SplashScreen] Error checking authentication: $e");
      // On error, default to login page for safety
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ScreenLoginPage()),
          (route) => false,
        );
      }
    }
  }

  // Legacy method kept for reference but not used
  Future<void> checkUserlogin(context) async {
    final String usertoken = await getUserToken();
    if (usertoken.isEmpty) {
      await Future.delayed(const Duration(seconds: 3));
      navigatePushandRemoveuntil(context, const ScreenLoginPage());
    } else {
      navigatePushandRemoveuntil(context, const HomeRoutingScreen());
    }
  }
}
