// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison

import 'dart:convert';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/bankdetails_model.dart';
import 'package:sdcp_rebuild/data/postbank_details_model.dart';
import 'package:sdcp_rebuild/presentation/blocs/fetch_bankdetails/fetch_bankdetails_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/image_picker_bloc/image_picker_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/post_bankdetails.bloc/post_bankdetails_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/profile_page/widgets/custom_imagepicker.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_elevatedbutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_textfield.dart';
import 'package:sdcp_rebuild/presentation/widgets/shared_preference.dart';

// ... other imports

class ScreenBankdetailsPage extends StatefulWidget {
  const ScreenBankdetailsPage({super.key});

  @override
  State<ScreenBankdetailsPage> createState() => _ScreenBankdetailsPageState();
}

class _ScreenBankdetailsPageState extends State<ScreenBankdetailsPage> {
  final TextEditingController accountholdernameController =
      TextEditingController();
  final TextEditingController accountnumberController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController banknameController = TextEditingController();
  final TextEditingController bankadressController = TextEditingController();
  final TextEditingController bankbranchController = TextEditingController();
  final TextEditingController pannumberController = TextEditingController();
  final TextEditingController adharnumberController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  XFile? imagepath;
  File? aadharimage;
  File? bankproofimage;
  String? panCopyBase64;
  String? accountProofBas64;
  Future<String> _convertImageTobase64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Widget _buildImageContainer({
    required String title,
    required File? localImage,
    required String? networkImageUrl,
    required Function() onTap,
    required Function(File) onImagePicked,
  }) {
    return Column(
      children: [
        TextStyles.caption(
          text: title,
          weight: FontWeight.bold,
          color: Appcolors.kblackColor,
        ),
        InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Appcolors.kgreyColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: localImage != null
                      ? Image.file(
                          localImage,
                          fit: BoxFit.cover,
                        )
                      : networkImageUrl != null
                          ? Image.network(
                              networkImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: Colors.white,
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            )
                          : const Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.white,
                            ),
                ),
              ),
              if (localImage != null || networkImageUrl != null)
                Positioned(
                  bottom: -5,
                  right: -5,
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () async {
                      try {
                        XFile? pickedFile =
                            await showBottomSheetWidget(context);
                        if (pickedFile != null) {
                          onImagePicked(File(pickedFile.path));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error picking image: $e')),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection(
      BuildContext context, BankdetailsModel? bankDetails) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildImageContainer(
          title: 'PAN Card',
          localImage: aadharimage,
          networkImageUrl: "${Endpoints.images}${bankDetails?.panCopy}",
          onTap: () async {
            try {
              XFile? pickedFile = await showBottomSheetWidget(context);
              if (pickedFile != null) {
                context.read<ImagePickerBloc>().add(
                      AadharImagePickingEvent(
                        aadharimage: File(pickedFile.path),
                      ),
                    );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error picking image: $e')),
              );
            }
          },
          onImagePicked: (File file) {
            context.read<ImagePickerBloc>().add(
                  AadharImagePickingEvent(aadharimage: file),
                );
          },
        ),
        _buildImageContainer(
          title: 'Bank Proof',
          localImage: bankproofimage,
          networkImageUrl: "${Endpoints.images}${bankDetails?.accountProof}",
          onTap: () async {
            try {
              XFile? pickedFile = await showBottomSheetWidget(context);
              if (pickedFile != null) {
                context.read<ImagePickerBloc>().add(
                      BankproofImagePickingEvent(
                        bankproofimage: File(pickedFile.path),
                      ),
                    );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error picking image: $e')),
              );
            }
          },
          onImagePicked: (File file) {
            context.read<ImagePickerBloc>().add(
                  BankproofImagePickingEvent(bankproofimage: file),
                );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final postbankdetailsbloc = context.read<PostBankdetailsBloc>();

    return MultiBlocListener(
      listeners: [
        BlocListener<ImagePickerBloc, ImagePickerState>(
          listener: (context, state) {
            if (state is AadharImagePickerSuccessState) {
              setState(() {
                aadharimage = state.aadharimage;
              });
            } else if (state is BankproofeImageSuccessState) {
              setState(() {
                bankproofimage = state.bankproofimage;
              });
            }
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<FetchBankdetailsBloc, FetchBankdetailsState>(
          builder: (context, state) {
            if (state is FetchBankdetailsLoadingState) {
              return Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Appcolors.kpurpledoublelightColor,
                  size: 40,
                ),
              );
            }

            if (state is FetchBankdetailsErrorState) {
              return Center(child: Text(state.message));
            }

            if (state is FetchBankdetailsSuccessState) {
              accountholdernameController.text =
                  state.bankdetails.beneficiaryName;
              accountnumberController.text =
                  state.bankdetails.bankAccountNumber;
              ifscController.text = state.bankdetails.ifsc;
              banknameController.text = state.bankdetails.bankName;
              bankadressController.text = state.bankdetails.bankAddress;
              bankbranchController.text = state.bankdetails.bankBranch;
              pannumberController.text = state.bankdetails.pan;
              adharnumberController.text = state.bankdetails.aadhar;
            }

            return Form(
              key: formKey,
              child: ListView(
                padding: EdgeInsets.all(ResponsiveUtils.wp(7)),
                children: [
                  ResponsiveSizedBox.height20,
                  CustomUnderlineTextField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Account holder name cannot be empty';
                      }
                      return null;
                    },
                    controller: accountholdernameController,
                    labeltext: 'Account Holder Name',
                  ),
                  ResponsiveSizedBox.height10,
                  CustomUnderlineTextField(
                    controller: accountnumberController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Account number cannot be empty';
                      }
                      return null;
                    },
                    labeltext: 'Account Number',
                  ),
                  ResponsiveSizedBox.height10,
                  CustomUnderlineTextField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'IFSC cannot be empty';
                      }
                      return null;
                    },
                    controller: ifscController,
                    labeltext: 'IFSC',
                  ),
                  ResponsiveSizedBox.height10,
                  CustomUnderlineTextField(
                    controller: banknameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bank name cannot be empty';
                      }
                      return null;
                    },
                    labeltext: 'Bank Name',
                  ),
                  ResponsiveSizedBox.height10,
                  CustomUnderlineTextField(
                    controller: bankadressController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bank Address cannot be empty';
                      }
                      return null;
                    },
                    labeltext: 'Bank Address',
                  ),
                  ResponsiveSizedBox.height10,
                  CustomUnderlineTextField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bank Branch cannot be empty';
                      }
                      return null;
                    },
                    controller: bankbranchController,
                    labeltext: 'Bank Branch',
                  ),
                  ResponsiveSizedBox.height10,
                  CustomUnderlineTextField(
                    controller: pannumberController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'PAN number cannot be empty';
                      }
                      return null;
                    },
                    labeltext: 'PAN Number',
                  ),
                  ResponsiveSizedBox.height10,
                  CustomUnderlineTextField(
                    controller: adharnumberController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Aadhar number cannot be empty';
                      }
                      return null;
                    },
                    labeltext: 'Aadhar Number',
                  ),
                  ResponsiveSizedBox.height10,
                  _buildImagesSection(
                    context,
                    state is FetchBankdetailsSuccessState
                        ? state.bankdetails
                        : null,
                  ),
                  ResponsiveSizedBox.height50,
                  BlocConsumer<PostBankdetailsBloc, PostBankdetailsState>(
                    listener: (context, state) {
                      if (state is PostBankdetailsSuccessState) {
                        CustomSnackBar.show(
                            context: context,
                            title: 'Success..',
                            message: state.message,
                            contentType: ContentType.success);
                      }
                      if (state is PostBankdetailsErrorState) {
                        CustomSnackBar.show(
                            context: context,
                            title: 'Error!!',
                            message: state.message,
                            contentType: ContentType.failure);
                      }
                    },
                    builder: (context, state) {
                      if (state is PostBankdetailsLoadingState) {
                        return ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusStyles.kradius10(),
                              ),
                              backgroundColor:
                                  Appcolors.kpurpleColor.withOpacity(.8)),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              child: Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                    color: Appcolors.kwhiteColor, size: 30),
                              )),
                        );
                      }
                      return CustomElevatedButton(
                        backgroundcolor: Appcolors.kpurpleColor.withOpacity(.8),
                        onpress: () async {
                          final userid = await getUserId();
                          if (formKey.currentState!.validate()) {
                            if (aadharimage != null) {
                              panCopyBase64 =
                                  await _convertImageTobase64(aadharimage!);
                            }
                            if (bankproofimage != null) {
                              accountProofBas64 =
                                  await _convertImageTobase64(bankproofimage!);
                            }

                            postbankdetailsbloc.add(
                              PostBankdetailsButtonClickEvent(
                                bankdetails: PostbankDetailsModel(
                                  beneficiaryName:
                                      accountholdernameController.text,
                                  bankAccountNumber:
                                      accountnumberController.text,
                                  ifsc: ifscController.text,
                                  bankName: banknameController.text,
                                  bankAddress: bankadressController.text,
                                  bankBranch: bankbranchController.text,
                                  pan: pannumberController.text,
                                  aadhar: adharnumberController.text,
                                  userId: userid,
                                  panCopy: panCopyBase64 ?? "",
                                  accountProof: accountProofBas64 ?? "",
                                ),
                              ),
                            );
                          } else {
                            CustomSnackBar.show(
                              context: context,
                              title: 'Error!!',
                              message: 'Fill all fields',
                              contentType: ContentType.failure,
                            );
                          }
                        },
                        text: 'Update',
                      );
                    },
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    accountholdernameController.dispose();
    accountnumberController.dispose();
    ifscController.dispose();
    banknameController.dispose();
    bankadressController.dispose();
    bankbranchController.dispose();
    pannumberController.dispose();
    adharnumberController.dispose();
    super.dispose();
  }
}
