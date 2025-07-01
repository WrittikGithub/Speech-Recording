import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/core/urls.dart';


import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';

import 'package:sdcp_rebuild/presentation/screens/commentpage/commentpage.dart';
import 'package:sdcp_rebuild/presentation/screens/instructionalertpage/instructionalertpage.dart';

import 'package:sdcp_rebuild/presentation/widgets/custom_audioplaybutton.dart';

class ScreenCompletedTaskDetailPage extends StatefulWidget {
  final String taskTargetID;
  final String taskTitle;
  final ContentTaskTargetSuccessState state;
  final int index;

  const ScreenCompletedTaskDetailPage({
    super.key,
    required this.taskTargetID,
    required this.taskTitle,
    required this.state,
    required this.index,
  });

  @override
  State<ScreenCompletedTaskDetailPage> createState() => _MyScreenState();
}

class _MyScreenState extends State<ScreenCompletedTaskDetailPage> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
  }

  void _nextContent() {
    if (currentIndex < widget.state.contentlist.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  void _previousContent() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress value
    final double progress =
        (currentIndex + 1) / widget.state.contentlist.length;
    //final content = widget.state.contentlist[currentIndex];

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
            children: [
              TextStyles.subheadline(text: widget.taskTitle),
              TextStyles.body(text: 'Task ID:${widget.taskTargetID}'),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Appcolors.kpurplelightColor),
              ),
            ),
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
            if (state is ContentTaskTargetSuccessState) {
              final content = state.contentlist[currentIndex];
              return Padding(
                padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
                child: Column(
                  children: [
                    ResponsiveSizedBox.height30,
                    // Stack to overlay navigation buttons on container
                    Stack(
                      children: [
                        // Main content container
                        Container(
                          height: ResponsiveUtils.hp(45),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Appcolors.kskybluecolor,
                                Appcolors.kskybluecolor.withOpacity(.4)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      TextStyles.body(
                                        text: 'SL: ${currentIndex + 1}',
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
                                ],
                              ),
                              ResponsiveSizedBox.height10,
                              const Divider(
                                thickness: 1,
                                color: Appcolors.kblackColor,
                              ),
                              ResponsiveSizedBox.height10,
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: ResponsiveUtils.wp(50),
                                        height: ResponsiveUtils.hp(30),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            widget
                                                    .state
                                                    .contentlist[currentIndex]
                                                    .contentReferenceUrl ??
                                                '',
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                                size: 50,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      ResponsiveSizedBox.height10,
                                      Text(
                                        content.sourceContent,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Navigation Buttons
                        Positioned(
                          left: -10,
                          top: ResponsiveUtils.hp(50) / 2 -
                              25, // Center vertically
                          child: currentIndex > 0
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Appcolors.kgreyColor.withOpacity(.3),
                                  ),
                                  child: IconButton(
                                    onPressed: _previousContent,
                                    icon: const Icon(Icons.chevron_left),
                                    iconSize: 40,
                                    color: Appcolors.kblackColor,
                                  ),
                                )
                              : const SizedBox(width: 50, height: 50),
                        ),
                        Positioned(
                          right: -10,
                          top: ResponsiveUtils.hp(50) / 2 -
                              25, // Center vertically
                          child: currentIndex <
                                  widget.state.contentlist.length - 1
                              ? Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Appcolors.kgreyColor.withOpacity(.3),
                                  ),
                                  child: IconButton(
                                    onPressed: _nextContent,
                                    icon: const Icon(Icons.chevron_right),
                                    iconSize: 40,
                                    color: Appcolors.kblackColor,
                                  ),
                                )
                              : const SizedBox(width: 50, height: 50),
                        ),
                      ],
                    ),
                    ResponsiveSizedBox.height50,
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) {
                                    return CommentSheet(
                                      taskTargetId: widget.taskTargetID,
                                      contentId: content.contentId,
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.comment)),
                          UnifiedAudioPlayerButton(
                            contentId: content.contentId,
                            audioUrl: '${Endpoints.recordURL}${content.targetContentUrl}',
                            size: 35,
                            isSaved: true,
                          ),
                          IconButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return InstructionAlertDialog(
                                        contentId: content.contentId,
                                      );
                                    });
                              },
                              icon: const Icon(
                                Icons.info,
                                color: Appcolors.kredColor,
                                size: 30,
                              ))
                        ],
                      ),
                    ),
                    ResponsiveSizedBox.height20,
              
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ));
  }
}
