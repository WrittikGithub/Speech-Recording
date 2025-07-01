import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/data/savereview_model.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_rview_bloc/save_review_bloc.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';

class ApproveAlertdialog extends StatelessWidget {
  final String taskTargetId;
  final String contentId;
  final String tcontentId;

  const ApproveAlertdialog(
      {super.key,
      required this.taskTargetId,
      required this.contentId,
      required this.tcontentId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: TextStyles.headline(
        text: 'Confromation',
        color: Appcolors.kgreenColor,
      ),
      content: const Text('Are you sure you want to approve this?'),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: TextStyles.body(
                  text: 'Close',
                  weight: FontWeight.bold,
                  color: Appcolors.kredColor),
            ),
            const Spacer(),
            BlocConsumer<SaveReviewBloc, SaveReviewState>(
              listener: (context, state) {
                if (state is SaveReviewSuccessState) {
                  // Fetch updated data
                  context.read<ReviewContentBloc>().add(
                      ReviewContentFetchingInitialEvent(
                          taskTargetId: taskTargetId));
                  Navigator.of(context).pop();
                }
              },
              builder: (context, state) {
                if (state is SaveReviewLoadingSate) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusStyles.kradius10(),
                        ),
                        backgroundColor: Appcolors.kgreenColor),
                    onPressed: () {},
                    child: Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Appcolors.kwhiteColor, size: 30),
                    ),
                  );
                }
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusStyles.kradius10(),
                      ),
                      backgroundColor: Appcolors.kgreenColor),
                  onPressed: () {
                    if (tcontentId.isNotEmpty) {
                      context.read<SaveReviewBloc>().add(
                          SaveRviewButtonclickEvent(
                              reviews: SaveReviewModel(
                                  reviewStatus: 'SAVED',
                                  taskTargetId: taskTargetId,
                                  contentId: contentId,
                                  tContentId: tcontentId)));
                    } else {
                      CustomSnackBar.show(
                          context: context,
                          title: 'Error!!',
                          message: 'Fill all fields',
                          contentType: ContentType.failure);
                    }
                  },
                  child: TextStyles.body(
                      text: 'Approve',
                      weight: FontWeight.bold,
                      color: Appcolors.kwhiteColor),
                );
              },
            ),
          ],
        )
      ],
    );
  }
}
