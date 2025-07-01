import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/appconstants.dart';

import 'dart:math' as math;

import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/cubit/toggle_password_cubit.dart';

import 'package:sdcp_rebuild/presentation/blocs/login_bloc/login_bloc.dart';

import 'package:sdcp_rebuild/presentation/widgets/custom_editingtextfield.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_elevatedbutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/signup_page.dart';
import 'package:sdcp_rebuild/presentation/screens/home_routing.dart';
import 'package:sdcp_rebuild/presentation/screens/login_page/apple_email_form.dart';

class ScreenLoginPage extends StatefulWidget {
  const ScreenLoginPage({super.key});

  @override
  State<ScreenLoginPage> createState() => _ScreenProfilePageState();
}

class _ScreenProfilePageState extends State<ScreenLoginPage> {
  final TextEditingController usernamecontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  Widget _buildWaveLayer(int layer) {
    return ClipPath(
      clipper: StaticWaveClipper(layer),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.62,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              if (layer == 1) ...[
                Appcolors.kaccentColor.withOpacity(.8),
                Appcolors.kaccentColor.withOpacity(0.3),
              ] else if (layer == 2) ...[
                Appcolors.kaccentColor.withOpacity(.01),
                Appcolors.kwhiteColor,
              ] else ...[
                Appcolors.kaccentColor.withOpacity(.4),
                Appcolors.kwhiteColor,
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: textColor, size: 22),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final loginbloc = context.read<LoginBloc>();
    
    // Calculate dimensions to ensure proper spacing
    final double logoPosition = screenHeight * 0.25; // Position logo at 25% from top
    final double formPosition = screenHeight * 0.40; // Position form at 40% from top
    
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              // Static wave layers
              for (int i = 1; i <= 3; i++) _buildWaveLayer(i),

              // Logo positioned with fixed percentage from top
              Positioned(
                top: logoPosition,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    Appconstants.logo,
                    height: ResponsiveUtils.hp(17),
                    width: ResponsiveUtils.wp(55),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Login Form
              Positioned(
                  top: formPosition,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(5)),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomEditingTextField(
                                title: 'Username',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Username cannot be empty';
                                  }
                                  return null;
                                },
                                icon: Icons.person,
                                controller: usernamecontroller,
                                hintText: 'Enter Username'),
                            ResponsiveSizedBox.height20,
                            BlocBuilder<TogglepasswordCubit, bool>(
                              builder: (context, state) {
                                return CustomEditingTextField(
                                    title: 'Password',
                                    suffixIcon: togglePassword(),
                                    obscureText: state,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password cannot be empty';
                                      }
                                      return null;
                                    },
                                    icon: Icons.password,
                                    controller: passwordcontroller,
                                    hintText: 'Enter Password');
                              },
                            ),
                            ResponsiveSizedBox.height30,
                            BlocConsumer<LoginBloc, LoginState>(
                              listener: (context, state) {
                                print('Current login state: $state');
                                
                                if (state is LoginSuccessState || 
                                    state is LoginSuccessAppOneState || 
                                    state is GoogleSignInSuccessState || 
                                    state is AppleSignInSuccessState) {
                                  print('Login success, routing to appropriate dashboard');
                                  if (mounted) { 
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HomeRoutingScreen()),
                                    );
                                  }
                                } else if (state is LoginErrorState) {
                                  if (mounted) { 
                                    CustomSnackBar.show(
                                      context: context,
                                      title: 'Error!',
                                      message: state.message,
                                      contentType: ContentType.failure,
                                    );
                                  }
                                } else if (state is AppleSignInNeedsMoreInfoState) {
                                  // Show the email dialog when Apple doesn't provide email
                                  if (mounted) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) => AppleEmailFormDialog(
                                        appleUserId: state.appleUserId,
                                        displayName: state.displayName,
                                      ),
                                    );
                                  }
                                }
                              },
                              builder: (context, state) {
                                if (state is LoginLoadingState) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadiusStyles.kradius10(),
                                          ),
                                          backgroundColor: Appcolors.kaccentColor
                                              .withOpacity(.8)),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 30, vertical: 15),
                                          child: Center(
                                            child: LoadingAnimationWidget
                                                .staggeredDotsWave(
                                                    color: Appcolors.kwhiteColor,
                                                    size: 30),
                                          )),
                                    ),
                                  );
                                }
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomElevatedButton(
                                        backgroundcolor:
                                            Appcolors.kaccentColor.withOpacity(.8),
                                        onpress: () {
                                          if (formKey.currentState!.validate()) {
                                            loginbloc.add(LoginButtonClickingEvent(
                                                username: usernamecontroller.text,
                                                password: passwordcontroller.text));
                                          } else {
                                            if (mounted) { 
                                              CustomSnackBar.show(
                                                  context: context,
                                                  title: 'Error!!',
                                                  message: 'Fill all fields',
                                                  contentType: ContentType.failure);
                                            }
                                          }
                                        },
                                        text: 'Login'),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(
                                            color: Colors.grey,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(
                                            color: Colors.grey,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    _buildSocialLoginButton(
                                      text: 'Sign in with Google',
                                      icon: Icons.g_mobiledata_rounded,
                                      backgroundColor: Colors.white,
                                      textColor: Colors.black87,
                                      onPressed: () {
                                        loginbloc.add(GoogleSignInEvent());
                                      },
                                    ),
                                    // _buildSocialLoginButton(
                                    //   text: 'Sign in with Apple',
                                    //   icon: Icons.apple,
                                    //   backgroundColor: Colors.black,
                                    //   textColor: Colors.white,
                                    //   onPressed: () {
                                    //     loginbloc.add(AppleSignInEvent());
                                    //   },
                                    // ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: TextButton(
                                        onPressed: () {
                                          if (mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const SignupPage()),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          "Don't have an account? Signup",
                                          style: TextStyle(
                                            color: Appcolors.kaccentColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        )));
  }
}

class StaticWaveClipper extends CustomClipper<Path> {
  final int waveLayer;

  StaticWaveClipper(this.waveLayer);

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, 0);

    double x = 0;
    double y = 0;

    // Customize wave parameters for each layer
    double amplitude = waveLayer == 1
        ? 60
        : waveLayer == 2
            ? 45
            : 35;

    // Adjust frequency for 2-3 waves across screen
    double frequency = size.width /
        (waveLayer == 1
            ? 1.5
            : waveLayer == 2
                ? 2.0
                : 2.5);

    // Phase shift for each layer to create overlapping effect
    double phase = waveLayer == 1
        ? 0
        : waveLayer == 2
            ? math.pi / 2
            : math.pi;

    // Draw the wave path, starting at the top left and ending 40% above the bottom right
    while (x < size.width * 1.4) {
      y = amplitude * math.sin((x / frequency) + phase);
      path.lineTo(x, size.height * 0.6 + y - (waveLayer * 40));
      x += 1;
    }

    // Complete the path on the right
    path.lineTo(size.width, size.height * 0.6);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
