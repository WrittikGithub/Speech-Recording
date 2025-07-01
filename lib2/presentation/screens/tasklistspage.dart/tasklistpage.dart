import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/core/urls.dart';

import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/submit_task_bloc/submit_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/taskdetailspage/taskpage.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_audioplaybutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';

class ScreenTaskListPage extends StatefulWidget {
  final String taskTargetID;
  final String taskTitle;
  const ScreenTaskListPage(
      {super.key, required this.taskTargetID, required this.taskTitle});

  @override
  State<ScreenTaskListPage> createState() => _ScreenTaskListPageState();
}

class _ScreenTaskListPageState extends State<ScreenTaskListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ContentTaskTargetIdBloc>().add(ContentTaskInitialFetchingEvent(
        contentTaskTargetId: widget.taskTargetID));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_back,
            size: 32,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextStyles.subheadline(text: widget.taskTitle),
            TextStyles.body(text: 'Task ID:${widget.taskTargetID}'),
            BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
              builder: (context, state) {
                if (state is ContentTaskTargetSuccessState) {
                  return TextStyles.body(
                      text: 'Total Contents:${state.contentlist.length}');
                }
                return TextStyles.body(text: 'Total Contents: -');
              },
            ),
          ],
        ),
      ),
      body: BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
        builder: (context, state) {
          if (state is ContentTasktargetIdLoadingState) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Appcolors.kpurplelightColor, size: 40),
            );
          }

          if (state is ContentTaskTargetErrrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ContentTaskTargetIdBloc>().add(
                          ContentTaskInitialFetchingEvent(
                              contentTaskTargetId: widget.taskTargetID));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ContentTaskTargetSuccessState) {
            return state.contentlist.isEmpty
                ? const Center(
                    child: Text('Tasklist is Empty'),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.wp(4),
                      vertical: ResponsiveUtils.wp(4),
                    ),
                    itemCount: state.contentlist.length,
                    itemBuilder: (context, index) {
                      final content = state.contentlist[index];
                      return GestureDetector(
                        onTap: () {
                          navigatePush(
                              context,
                              ScreenPendingTaskDetailPage(
                                  taskTargetID: widget.taskTargetID,
                                  taskTitle: widget.taskTitle,
                                  state: state,
                                  index: index));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Appcolors.kskybluecolor,
                                Appcolors.kskybluecolor.withOpacity(.4)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextStyles.body(
                                  text: 'SL:${index + 1}',
                                  color: Appcolors.kblackColor,
                                  weight: FontWeight.bold,
                                ),
                                ResponsiveText(
                                    'content ID:${content.contentId}',
                                    sizeFactor: .8,
                                    color: Appcolors.kgreyColor,
                                    weight: FontWeight.bold),
                                ResponsiveText(
                                    'Source Content:${content.sourceContent}',
                                    sizeFactor: .8,
                                    color: Appcolors.kblackColor,
                                    weight: FontWeight.bold),
                                const Divider(
                                  thickness: 1,
                                  color: Appcolors.kblackColor,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // content.targetContentUrl.isEmpty
                                    //     ? Material(
                                    //         shape: const CircleBorder(),
                                    //         clipBehavior: Clip.antiAlias,
                                    //         color: Appcolors.kgreyColor,
                                    //         child: Container(
                                    //           width: ResponsiveUtils.wp(9),
                                    //           height: ResponsiveUtils.wp(9),
                                    //           decoration: const BoxDecoration(
                                    //             shape: BoxShape.circle,
                                    //           ),
                                    //           child: Center(
                                    //             child: Icon(
                                    //               Icons.play_arrow,
                                    //               color: Appcolors.kwhiteColor,
                                    //               size: ResponsiveUtils.wp(7),
                                    //             ),
                                    //           ),
                                    //         ),
                                    //       )
                                    //     :
                                         UnifiedAudioPlayerButton(
                                            localPath:
                                                content.targetContentPath,
                                                 audioUrl:
                                                '${Endpoints.recordURL}${content.targetContentUrl}',
                                            contentId: content.contentId,
                                            size: ResponsiveUtils.wp(9),
                                          ),
                                    // : AudioPlayerButton(
                                    //     audioUrl:
                                    //         '${Endpoints.recordURL}${content.targetContent}',
                                    //     size: ResponsiveUtils.wp(9),
                                    //     contentId: content.contentId,
                                    //   ),
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadiusStyles.kradius5(),
                                          color: content
                                                  .targetDigitizationStatus
                                                  .isEmpty
                                              ? Appcolors.korangeColor
                                              : Appcolors.kgreenColor),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: ResponsiveUtils.wp(2.5),
                                            vertical: ResponsiveUtils.wp(1.5)),
                                        child: TextStyles.caption(
                                            text: content
                                                    .targetDigitizationStatus
                                                    .isEmpty
                                                ? 'Record'
                                                : content
                                                    .targetDigitizationStatus,
                                            color: Appcolors.kwhiteColor,
                                            weight: FontWeight.bold),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(17),
          color: Colors.transparent,
        ),
        child: BlocConsumer<SubmitTaskBloc, SubmitTaskState>(
          listener: (context, state) {
            if (state is SubmitTaskSuccessState) {
              CustomSnackBar.show(
                  context: context,
                  title: 'Success',
                  message: state.message,
                  contentType: ContentType.success);
            }
            if (state is SubmitTaskErrorState) {
              CustomSnackBar.show(
                  context: context,
                  title: 'Error!!',
                  message: state.message,
                  contentType: ContentType.failure);
            }
          },
          builder: (context, state) {
            if (state is SubmitTaskLoadingState) {
              return FloatingActionButton.extended(
                onPressed: () {},
                heroTag: "submitButton", // Unique heroTag
                backgroundColor: Appcolors.kwhiteColor.withOpacity(.4),
                elevation: 0,
                label: Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Appcolors.kwhiteColor, size: 30),
                ),
                icon: const Icon(
                  Icons.send,
                  color: Colors.blue,
                ),
              );
            }
            return FloatingActionButton.extended(
              onPressed: () {
                context.read<SubmitTaskBloc>().add(SubmitTaskButtonClickEvent(
                    taskTargetId: widget.taskTargetID));
              },
              heroTag: "submitButton",
              backgroundColor: Appcolors.kwhiteColor.withOpacity(.4),
              elevation: 0,
              label: const Text(
                "Submit",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(
                Icons.send,
                color: Colors.blue,
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
