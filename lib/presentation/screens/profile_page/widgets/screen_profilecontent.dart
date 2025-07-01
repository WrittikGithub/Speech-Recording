import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_bankdetails/fetch_bankdetails_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_profile_bloc/fetch_profile_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/update_profilebloc/updat_profile_bloc.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_elevatedbutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_readonly_textfield.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_textfield.dart';

class ScreenProfileContent extends StatefulWidget {
  const ScreenProfileContent({super.key});

  @override
  State<ScreenProfileContent> createState() => _ScreenProfileContentState();
}

class _ScreenProfileContentState extends State<ScreenProfileContent> {
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController createdatController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<FetchProfileBloc>().add(FetchProfileInitialEvent());
    context.read<FetchBankdetailsBloc>().add(FetchbnakdetailsInitialEvent());
  }

  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    createdatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FetchProfileBloc, FetchProfileState>(
        builder: (context, state) {
          if (state is FetchProfileLoadingState) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Appcolors.kpurpledoublelightColor, size: 40),
            );
          }
          if (state is FetchProfileErrorState) {
            return Center(child: Text(state.message));
          }
          if (state is FetchProfileSuccessState) {
            debugPrint(state.userdatas.userFullName);
            fullnameController.text = state.userdatas.userFullName ?? '';
            emailController.text = state.userdatas.userEmailAddress ?? '';
            usernameController.text = state.userdatas.userName ?? '';
            createdatController.text = state.userdatas.createdDate ?? '';
          }
          return ListView(
            padding: EdgeInsets.all(ResponsiveUtils.wp(7)),
            children: [
              ResponsiveSizedBox.height20,
              CustomUnderlineTextField(
                controller: fullnameController,
                labeltext: 'Full Name',
              ),
              ResponsiveSizedBox.height10,
              CustomUnderlineTextField(
                  controller: emailController, labeltext: 'Email Adress'),
              ResponsiveSizedBox.height10,
              // CustomReadonlyUnderlineTextField(
              //     controller: usernameController, labeltext: 'User Name'),
              CustomUnderlineTextField(
                controller: usernameController,
                labeltext: 'User Name',
              ),
              ResponsiveSizedBox.height10,
              CustomReadonlyUnderlineTextField(
                  controller: createdatController, labeltext: 'Created Date'),
              ResponsiveSizedBox.height50,
              BlocConsumer<UpdatProfileBloc, UpdatProfileState>(
                listener: (context, state) {
                      if (state is UpdateProfileSuccessState) {
                   CustomSnackBar.show(
                      context: context,
                      title: 'Success',
                      message: state.message,
                      contentType: ContentType.success);
              }
              if (state is UpdateProfileErrorState) {
                   CustomSnackBar.show(
                      context: context,
                      title: 'Error!!',
                      message: state.message,
                      contentType: ContentType.failure);
              }
                },
                builder: (context, state) {
                     if (state is UpdateProfileLoadingState) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadiusStyles.kradius10(),
                                          ),
                                          backgroundColor:
                                               Appcolors.kpurpleColor.withOpacity(.8)),
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 30, vertical: 15),
                                          child: Center(
                                            child: LoadingAnimationWidget
                                                .staggeredDotsWave(
                                                    color:
                                                        Appcolors.kwhiteColor,
                                                    size: 30),
                                          )),
                                    ),
                                  );
                                }
                  return CustomElevatedButton(
                      backgroundcolor: Appcolors.kpurpleColor.withOpacity(.8),
                      onpress: () {
                        context.read<UpdatProfileBloc>().add(
                            UpdateProfileButtonClickingEvent(
                                userfullName: fullnameController.text,
                                userEmail: emailController.text,
                                username: usernameController.text));
                      },
                      text: 'Update');
                },
              )
            ],
          );
        },
      ),
    );
  }
}
