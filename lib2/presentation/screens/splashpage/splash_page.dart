import 'package:flutter/material.dart';

import 'package:sdcp_rebuild/core/appconstants.dart';
import 'package:sdcp_rebuild/core/colors.dart';

import 'package:sdcp_rebuild/presentation/screens/login_page/loginpage.dart';
import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';



class AdvancedSplashScreen extends StatefulWidget {
  const AdvancedSplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
    
    checkUserlogin(context);
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

  // Future<void> navigate(context) async {
  //   await Future.delayed(const Duration(seconds: 3));
  //   navigatePush(context, const ScreenLoginPage());
  // }
  Future<void> checkUserlogin(context) async {
    final String usertoken = await getUserToken();
    if (usertoken.isEmpty) {
      await Future.delayed(const Duration(seconds: 3));
      navigatePushandRemoveuntil(context, const ScreenLoginPage());
    } else {
      navigatePushandRemoveuntil(context, const ScreenMainPage());
    }
  }
}
