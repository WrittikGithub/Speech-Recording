import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/domain/databases/review_content_database_helper.dart';

import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';

import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';

class ReviewTaskcard extends StatelessWidget {
  final String title;
  final String taskCode;
  final String taskPrefix;
  final String taskStatus;

  final int index;

  const ReviewTaskcard({
    super.key,
    required this.title,
    required this.taskCode,
    required this.taskPrefix,
    required this.index,
    required this.taskStatus,
  });

  Future<bool> _isTaskDownloaded(String taskCode) async {
    final dbHelper = ReviewContentDatabaseHelper();
    final contents = await dbHelper.getContentsByTargetTaskTargetId(taskCode);
    return contents.isNotEmpty;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:
            index.isOdd ? Appcolors.kpurplelightColor : Appcolors.kskybluecolor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(title,
                    sizeFactor: .8,
                    color: index.isOdd
                        ? Appcolors.kwhiteColor
                        : Appcolors.kblackColor,
                    weight: FontWeight.bold),
                TextStyles.body(
                  text: taskStatus,
                  color: index.isOdd
                      ? Appcolors.kwhiteColor
                      : Appcolors.kblackColor,
                ),
              ],
            ),
            Divider(
              thickness: 1,
              color:
                  index.isOdd ? Appcolors.kwhiteColor : Appcolors.kblackColor,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextStyles.body(
                      text: 'Task Code',
                      color: index.isOdd
                          ? Appcolors.kwhiteColor
                          : Appcolors.kblackColor,
                    ),
                    ResponsiveSizedBox.height5,
                    ResponsiveText(taskCode,
                        sizeFactor: .8,
                        color: index.isOdd
                            ? Appcolors.kwhiteColor
                            : Appcolors.kblackColor,
                        weight: FontWeight.bold),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextStyles.body(
                      text: 'Task-Prefix',
                      color: index.isOdd
                          ? Appcolors.kwhiteColor
                          : Appcolors.kblackColor,
                    ),
                    ResponsiveSizedBox.height5,
                    ResponsiveText(taskPrefix,
                        sizeFactor: .8,
                        color: index.isOdd
                            ? Appcolors.kwhiteColor
                            : Appcolors.kblackColor,
                        weight: FontWeight.bold),
                  ],
                ),
                BlocConsumer<ReviewContentBloc, ReviewContentState>(
                  listener: (context, state) {
                    if (state is ReviewContentDownloadSuccessState &&
                        state.contentTaskTargetId == taskCode) {
                      CustomSnackBar.show(
                          context: context,
                          title: 'Success',
                          message: 'Task downloaded Successfully',
                          contentType: ContentType.success);
                    }
                    if (state is ReviewContentErrrorState &&
                        state.contentTaskTargetId == taskCode) {
                      CustomSnackBar.show(
                          context: context,
                          title: 'Error !!',
                          message: 'Task download failed',
                          contentType: ContentType.failure);
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is ReviewContentDownloadingState &&
                        state.contentTaskTargetId == taskCode;

                    if (isLoading) {
                      return LoadingAnimationWidget.inkDrop(
                          color: Appcolors.kblackColor,
                          size: ResponsiveUtils.wp(6));
                    }
                        return FutureBuilder<bool>(
                      future: _isTaskDownloaded(taskCode),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        final isDownloaded = snapshot.data ?? false;

                        return GestureDetector(
                          onTap: () {
                            context.read<ReviewContentBloc>().add(
                              ReviewContentDownloadingEvent(taskTargetId: taskCode)
                            );
                          },
                          child: Icon(
                            isDownloaded ? Icons.refresh : Icons.download,
                            color: index.isOdd ? Appcolors.kwhiteColor : Appcolors.kblackColor,
                          ),
                        );
                      },
                    );
                    // return GestureDetector(
                    //     onTap: () {
                    //       context.read<ReviewContentBloc>().add(
                    //           ReviewContentDownloadingEvent(taskTargetId: taskCode)); 
                           
                    //     },
                    //     child: Icon(Icons.download));
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
