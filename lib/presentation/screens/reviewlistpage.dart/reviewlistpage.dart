import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/presentation/blocs/preview_score_bloc/preview_score_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/submit_review/submit_review_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/reviewdetailscreen/reviewdetailpage.dart';
import 'package:sdcp_rebuild/presentation/screens/reviewlistpage.dart/widgets/scorecard_alertdialog.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_audioplaybutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';

class ScreenReviewListPage extends StatefulWidget {
  final String taskTargetID;
  final String taskTitle;
  const ScreenReviewListPage(
      {super.key, required this.taskTargetID, required this.taskTitle});

  @override
  State<ScreenReviewListPage> createState() => _ScreenTaskListPageState();
}

class _ScreenTaskListPageState extends State<ScreenReviewListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReviewContentBloc>().add(
        ReviewContentFetchingInitialEvent(taskTargetId: widget.taskTargetID));
    context
        .read<PreviewScoreBloc>()
        .add(PreviewScoreButtonClickEvent(taskTargetId: widget.taskTargetID));
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
            BlocBuilder<ReviewContentBloc, ReviewContentState>(
              builder: (context, state) {
                if (state is ReviewContentSuccessState) {
                  return TextStyles.body(
                      text: 'Total Contents:${state.contentlist.length}');
                }
                return TextStyles.body(text: 'Total Contents: -');
              },
            ),
          ],
        ),
      ),
      body: BlocBuilder<ReviewContentBloc, ReviewContentState>(
        builder: (context, state) {
          if (state is ReviewContentLoadingState) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Appcolors.kpurplelightColor, size: 40),
            );
          }

          if (state is ReviewContentErrrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReviewContentBloc>().add(
                          ReviewContentFetchingInitialEvent(
                              taskTargetId: widget.taskTargetID));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ReviewContentSuccessState) {
            return state.contentlist.isEmpty
                ? const Center(
                    child: Text('Reviewlist is Empty'),
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
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ScreenReviewDetailPage(
                                  taskTargetID: widget.taskTargetID,
                                  taskTitle: widget.taskTitle,
                                  state: state,
                                  index: index)));
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
                                Row(
                                  children: [
                                    TextStyles.body(
                                      text: 'SL:${index + 1}',
                                      color: Appcolors.kblackColor,
                                      weight: FontWeight.bold,
                                    ),
                                    if (MinimumRecordingTimeUtils.hasMinimumTime(content.promptSpeechTime))
                                      MinimumRecordingTimeUtils.buildMinimumTimeWidget(content.promptSpeechTime) ?? const SizedBox.shrink(),
                                  ],
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
                                if (MinimumRecordingTimeUtils.hasMinimumTime(content.promptSpeechTime))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: MinimumRecordingTimeUtils.buildMinimumTimeWidget(content.promptSpeechTime) ?? const SizedBox.shrink(),
                                  ),
                                const Divider(
                                  thickness: 1,
                                  color: Appcolors.kblackColor,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    content.targetTargetContentUrl.isEmpty
                                        ? Material(
                                            shape: const CircleBorder(),
                                            clipBehavior: Clip.antiAlias,
                                            color: Appcolors.kgreyColor,
                                            child: Container(
                                              width: ResponsiveUtils.wp(9),
                                              height: ResponsiveUtils.wp(9),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.play_arrow,
                                                  color: Appcolors.kwhiteColor,
                                                  size: ResponsiveUtils.wp(7),
                                                ),
                                              ),
                                            ),
                                          )
                                        :UnifiedAudioPlayerButton(
                                            contentId: content.contentId,
                                            audioUrl:
                                                '${Endpoints.recordURL}${content.targetTargetContentUrl}',
                                                localPath: content.targetTargetContentPath,
                                            size: ResponsiveUtils.wp(9),
                                          ),
                                    Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadiusStyles.kradius5(),
                                          color: (content.targetReviewStatus ==
                                                      null ||
                                                  content.targetReviewStatus!
                                                      .isEmpty)
                                              ? Appcolors.korangeColor
                                              : (content.targetReviewStatus ==
                                                      'REJECTED')
                                                  ? Appcolors.kredColor
                                                  : Appcolors.kgreenColor),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: ResponsiveUtils.wp(2.5),
                                            vertical: ResponsiveUtils.wp(1.5)),
                                        child: TextStyles.caption(
                                            text: (content.targetReviewStatus ==
                                                        null ||
                                                    content.targetReviewStatus!
                                                        .isEmpty)
                                                ? 'INREVIEW'
                                                : content.targetReviewStatus ==
                                                        'REJECTED'
                                                    ? 'REJECTED'
                                                    : 'APPROVED',
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Appcolors.kgreenColor, width: 2),
              borderRadius: BorderRadius.circular(17),
              color: Colors.transparent,
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ScoreReportDialog(
                    taskTargetId: widget.taskTargetID,
                  ),
                );
              },
              heroTag: "scoreButton", // Unique heroTag
              backgroundColor: Appcolors.kwhiteColor.withOpacity(.4),
              elevation: 0,
              label: const Text(
                "Score",
                style: TextStyle(
                  color: Appcolors.kgreenColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(
                Icons.score,
                color: Appcolors.kgreenColor,
              ),
            ),
          ),
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(17),
              color: Colors.transparent,
            ),
            child: BlocConsumer<SubmitReviewBloc, SubmitReviewState>(
              listener: (context, state) {
              if (state is SubmitReviewSuccessState) {
                   CustomSnackBar.show(
                      context: context,
                      title: 'Success',
                      message: state.message,
                      contentType: ContentType.success);
              }
              if (state is SubmitReviewErrorState) {
                   CustomSnackBar.show(
                      context: context,
                      title: 'Error!!',
                      message: state.message,
                      contentType: ContentType.failure);
              }
              },
              builder: (context, state) {
                if (state is SubmitReviewLoadingState) {
                    return FloatingActionButton.extended(
                  onPressed: () {
                  
                  },
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
                     context.read<SubmitReviewBloc>().add(
                    SubmitReviewButtonClickEvent(
                        taskTargetId: widget.taskTargetID));
                  },
                  heroTag: "submitButton", // Unique heroTag
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
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
