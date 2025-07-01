import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/core/colors.dart';



class CustomReadonlyUnderlineTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labeltext;
  final String? Function(String?)? validator;

  const CustomReadonlyUnderlineTextField({
    super.key,
    required this.controller,
    required this.labeltext,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: labeltext,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
              color: Appcolors.kpurpleColor.withOpacity(.7), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Appcolors.kpurplelightColor),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Appcolors.kredColor),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Appcolors.kredColor),
        ),
      ),
    );
  }
}
