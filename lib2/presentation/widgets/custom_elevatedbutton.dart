import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';

class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({
    super.key,
    required this.onpress,
    required this.text,
    required this.backgroundcolor,
  });
  final VoidCallback onpress;
  final String text;
  final Color backgroundcolor;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onpress,
        style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusStyles.kradius10(),
            ),
            backgroundColor: backgroundcolor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Appcolors.kwhiteColor),
          ),
        ),
      ),
    );
  }
}
