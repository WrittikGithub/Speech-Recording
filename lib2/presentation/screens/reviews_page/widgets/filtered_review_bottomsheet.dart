import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/data/language_model.dart';
import 'package:sdcp_rebuild/presentation/blocs/reviewassignments_bloc/reviews_assignmentsinterview_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/userlanguage_bloc/user_language_bloc.dart';

class FilterReviewBottomSheet extends StatefulWidget {
  const FilterReviewBottomSheet({super.key});

  @override
  State<FilterReviewBottomSheet> createState() =>
      _FilterReviewBottomSheetState();
}

class _FilterReviewBottomSheetState extends State<FilterReviewBottomSheet> {
  String? selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              TextStyles.headline(
                text: 'Filter Tasks',
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close))
            ],
          ),
          ResponsiveSizedBox.height20,
          BlocBuilder<UserLanguageBloc, UserLanguageState>(
            builder: (context, state) {
              if (state is UserLanguageSuccessState) {
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(3)),
                  decoration: BoxDecoration(
                      border: Border.all(color: Appcolors.kgreyColor),
                      borderRadius: BorderRadius.circular(8)),
                  child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Language'),
                      value: selectedLanguage,
                      underline: const SizedBox(),
                      items: state.userlangauges.map((LanguageModel language) {
                        return DropdownMenuItem<String>(
                          value: language.languageName,
                          child: Text(language.languageName),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedLanguage = value;
                        });
                      }),
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const ListTile(
                  title: Text('No languages available'),
                ),
              );
            },
          ),
          ResponsiveSizedBox.height20,
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusStyles.kradius10(),
                      ),
                      backgroundColor: Appcolors.kredColor),
                  onPressed: () {
                    setState(() {
                      selectedLanguage = null;
                    });
                    context
                        .read<ReviewsAssignmentsinterviewBloc>()
                        .add(ReviewsAssignmentsInitialFetchingEvent());
                    Navigator.pop(context);
                  },
                  child: TextStyles.body(
                      text: 'Reset',
                      weight: FontWeight.bold,
                      color: Appcolors.kwhiteColor),
                ),
                // child: OutlinedButton(
                //     onPressed: () {
                //       setState(() {
                //         selectedLanguage = null;

                //       });
                //       context
                //           .read<ReviewsAssignmentsinterviewBloc>()
                //           .add(ReviewsAssignmentsInitialFetchingEvent());
                //       Navigator.pop(context);
                //     },
                //     child: const Text('Reset')),
              ),
              ResponsiveSizedBox.width20,
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusStyles.kradius10(),
                      ),
                      backgroundColor: Appcolors.kgreenColor),
                  onPressed: () {
                    context.read<ReviewsAssignmentsinterviewBloc>().add(
                        ReviewsAssignmentsFilteringEvent(
                            language: selectedLanguage));
                    Navigator.pop(context);
                  },
                  child: TextStyles.body(
                      text: 'Apply',
                      weight: FontWeight.bold,
                      color: Appcolors.kwhiteColor),
                ),
                // child: ElevatedButton(
                //     onPressed: () {
                //       context.read<ReviewsAssignmentsinterviewBloc>().add(
                //            ReviewsAssignmentsFilteringEvent(language: selectedLanguage)
                //           );
                //       Navigator.pop(context);
                //     },
                //     child: const Text('Apply'))
              )
            ],
          )
        ],
      ),
    );
  }
}
