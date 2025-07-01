import 'package:flutter/material.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';

class CustomContainer extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String subheading;

  const CustomContainer({
    super.key,
    required this.icon,
    required this.heading,
    required this.subheading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 211, 230, 246),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Appcolors.kpurpleColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextStyles.body(
                  text: heading,
                  weight: FontWeight.bold,
                  color: Appcolors.kpurpleColor),
              ResponsiveSizedBox.height5,
              TextStyles.caption(
                  text: subheading, color: Appcolors.kblackColor),
            ],
          ),
        ],
      ),
    );
  }
}
