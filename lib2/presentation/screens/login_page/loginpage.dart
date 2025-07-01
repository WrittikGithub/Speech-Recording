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

import 'package:sdcp_rebuild/presentation/screens/mainpage/mainpage.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_editingtextfield.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_elevatedbutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';

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
                Appcolors.kpurpleColor.withOpacity(.8),
                Appcolors.kpurpleColor.withOpacity(0.3),
              ] else if (layer == 2) ...[
                Appcolors.kskybluecolor.withOpacity(.01),
                Appcolors.kwhiteColor,
              ] else ...[
                Appcolors.kpurplelightColor.withOpacity(.4),
                Appcolors.kwhiteColor,
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final loginbloc = context.read<LoginBloc>();
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            child: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              // Static wave layers
              for (int i = 1; i <= 3; i++) _buildWaveLayer(i),

              Positioned(
                bottom: ResponsiveUtils.hp(67),
                left: 0,
                right: 0,
                child: Image.asset(
                  Appconstants.logo,
                  height: ResponsiveUtils.hp(17),
                  width: ResponsiveUtils.wp(55),
                  fit: BoxFit.contain,
                ),
              ),

              // Login Form
              Positioned(
                  bottom: ResponsiveUtils.hp(20),
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(5)),
                    child: Form(
                      key: formKey,
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
                          ResponsiveSizedBox.height30,
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
                          ResponsiveSizedBox.height50,
                          BlocConsumer<LoginBloc, LoginState>(
                            listener: (context, state) {
                              if (state is LoginSuccessState) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ScreenMainPage()),
                                );
                              } else if (state is LoginErrorState) {
                                CustomSnackBar.show(
                                    context: context,
                                    title: 'Error!',
                                    message: state.message,
                                    contentType: ContentType.failure);
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
                                        backgroundColor: Appcolors.kpurpleColor
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
                              return CustomElevatedButton(
                                  backgroundcolor:
                                      Appcolors.kpurpleColor.withOpacity(.8),
                                  onpress: () {
                                    if (formKey.currentState!.validate()) {
                                      loginbloc.add(LoginButtonClickingEvent(
                                          username: usernamecontroller.text,
                                          password: passwordcontroller.text));
                                    } else {
                                      CustomSnackBar.show(
                                          context: context,
                                          title: 'Error!!',
                                          message: 'Fill all fields',
                                          contentType: ContentType.failure);
                                    }
                                  },
                                  text: 'Login');
                            },
                          )
                        ],
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
