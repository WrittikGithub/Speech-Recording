import 'package:flutter/material.dart';

import 'package:sdcp_rebuild/core/colors.dart';

class CustomEditingTextField extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool? obscureText;

  const CustomEditingTextField({
    super.key,
    required this.title,
    required this.icon,
    required this.controller,
    required this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text, this.suffixIcon, this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kpurplelightColor.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Appcolors.kpurplelightColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Appcolors.kwhiteColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: controller,
                  obscureText: obscureText??false,
                  decoration: InputDecoration(
                    suffixIcon: suffixIcon,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  keyboardType: keyboardType,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
