import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';

import 'package:sdcp_rebuild/presentation/screens/instructionalertpage/instructionalertpage.dart';
import 'package:sdcp_rebuild/presentation/screens/reviewdetailscreen/widgets/approve_alertdialog.dart';
import 'package:sdcp_rebuild/presentation/screens/reviewdetailscreen/widgets/rejection_alertdialog.dart';
import 'package:sdcp_rebuild/presentation/screens/reviewdetailscreen/widgets/review_commentpage.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_audioplaybutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_elevatedbutton.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_imagecontainer.dart';

class ScreenReviewDetailPage extends StatefulWidget {
  final String taskTargetID;
  final String taskTitle;
  final ReviewContentSuccessState state;
  final int index;

  const ScreenReviewDetailPage({
    super.key,
    required this.taskTargetID,
    required this.taskTitle,
    required this.state,
    required this.index,
  });

  @override
  State<ScreenReviewDetailPage> createState() => _MyScreenState();
}

class _MyScreenState extends State<ScreenReviewDetailPage> {
  late int currentIndex;
  bool isExpanded = false;
  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
  }

  void _nextContent() {
    if (currentIndex < widget.state.contentlist.length - 1) {
      setState(() {
        currentIndex++;
        isExpanded = false;
      });
    }
  }

  void _previousContent() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isExpanded = false;
      });
    }
  }

  void _toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress value
    final double progress =
        (currentIndex + 1) / widget.state.contentlist.length;
    // final content = widget.state.contentlist[currentIndex];

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
        body: BlocBuilder<ReviewContentBloc, ReviewContentState>(
          builder: (context, state) {
            if (state is ReviewContentLoadingState) {
              return Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Appcolors.kpurplelightColor, size: 40),
              );
            }
            if (state is ReviewContentSuccessState) {
              final content = state.contentlist[currentIndex];
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
                  child: Column(
                    children: [
                      ResponsiveSizedBox.height30,
                      // Stack to overlay navigation buttons on container
                      Stack(
                        children: [
                          // Main content container
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: isExpanded
                                ? ResponsiveUtils.hp(70) // Expanded height
                                : ResponsiveUtils.hp(50),
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
                                    TextStyles.body(
                                      text: 'SL: ${currentIndex + 1}',
                                      color: Appcolors.kblackColor,
                                      weight: FontWeight.bold,
                                    ),
                                    const Spacer(),
                                    ResponsiveText(
                                        'content ID:${content.contentId}',
                                        sizeFactor: .8,
                                        color: Appcolors.kgreyColor,
                                        weight: FontWeight.bold),
                                    IconButton(
                                      icon: Icon(
                                        isExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Appcolors.kblackColor,
                                      ),
                                      onPressed: _toggleExpansion,
                                    ),
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
                                            child: NetworkFirstImageWidget(
                                              networkUrl: widget
                                                  .state
                                                  .contentlist[currentIndex]
                                                  .contentReferenceUrl,
                                              localPath: widget
                                                  .state
                                                  .contentlist[currentIndex]
                                                  .contentReferencePath,
                                              fit: BoxFit.cover,
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
                          if (currentIndex > 0)
                            Positioned(
                              left: -10,
                              top: isExpanded
                                  ? ResponsiveUtils.hp(70) / 2 - 25
                                  : ResponsiveUtils.hp(45) / 2 - 25,
                              child: Container(
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
                              ),
                            ),
                          if (currentIndex <
                              widget.state.contentlist.length - 1)
                            Positioned(
                              right: -10,
                              top: isExpanded
                                  ? ResponsiveUtils.hp(70) / 2 - 25
                                  : ResponsiveUtils.hp(45) / 2 - 25,
                              child: Container(
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
                              ),
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
                                      return ReviewCommentpage(
                                        taskTargetId: widget.taskTargetID,
                                        contentId: content.contentId,
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.comment)),
                            (content.targetTargetContentUrl.isEmpty)
                                ? Material(
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    color: Appcolors.kgreyColor,
                                    child: Container(
                                      width: ResponsiveUtils.wp(11),
                                      height: ResponsiveUtils.wp(11),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: Appcolors.kwhiteColor,
                                          size: ResponsiveUtils.wp(9),
                                        ),
                                      ),
                                    ),
                                  )
                                : UnifiedAudioPlayerButton(
                                    size: 40,
                                    contentId: content.contentId,
                                    localPath: content.targetTargetContentPath,
                                    audioUrl:
                                        '${Endpoints.recordURL}${content.targetTargetContentUrl}'),
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
                                  size: 30,
                                  color: Appcolors.kredColor,
                                ))
                          ],
                        ),
                      ),
                      ResponsiveSizedBox.height50,
                      (content.targetReviewStatus == null ||
                              content.targetReviewStatus!.isEmpty)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CustomElevatedButton(
                                    onpress: () {
                                      log('targetcontent${content.targetContentId}');
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return ApproveAlertdialog(
                                              taskTargetId: widget.taskTargetID,
                                              contentId: content.contentId,
                                              tcontentId:
                                                  content.targetContentId,
                                            );
                                          });
                                    },
                                    text: 'APPROVE',
                                    backgroundcolor: Appcolors.kgreenColor,
                                  ),
                                ),
                                ResponsiveSizedBox.width10,
                                Expanded(
                                  child: CustomElevatedButton(
                                    onpress: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return RejectAlertDialog(
                                              taskTargetId: widget.taskTargetID,
                                              contentId: content.contentId,
                                              tcontentId:
                                                  content.targetContentId,
                                            );
                                          });
                                    },
                                    text: 'REJECT',
                                    backgroundcolor: Appcolors.kredColor,
                                  ),
                                ),
                              ],
                            )
                          : (content.targetReviewStatus == 'REJECTED')
                              ? CustomElevatedButton(
                                  onpress: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return ApproveAlertdialog(
                                            taskTargetId: widget.taskTargetID,
                                            contentId: content.contentId,
                                            tcontentId: content.targetContentId,
                                          );
                                        });
                                  },
                                  text: 'REJECTED',
                                  backgroundcolor: Appcolors.kredColor,
                                )
                              : CustomElevatedButton(
                                  onpress: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return RejectAlertDialog(
                                            taskTargetId: widget.taskTargetID,
                                            contentId: content.contentId,
                                            tcontentId: content.targetContentId,
                                          );
                                        });
                                  },
                                  text: 'APPROVED',
                                  backgroundcolor: Appcolors.kgreenColor,
                                ),
                      ResponsiveSizedBox.height20,
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ));
  }
}

//  BlocBuilder<ReviewContentBloc, ReviewContentState>(
//         builder: (context, state) {
//           if (state is ReviewContentLoadingState) {
//                 return Center(
//               child: LoadingAnimationWidget.staggeredDotsWave(
//                   color: Appcolors.kpurplelightColor, size: 40),
//             );
//           }
//           if (state is ReviewContentSuccessState) {
//             final content = state.contentlist[currentIndex];
//             // final double progress =
//             //     (currentIndex + 1) / state.contentlist.length;
//             return SingleChildScrollView(
//               padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
//               child: Stack(
//                 children: [
//                   Column(children: [
//                     ResponsiveSizedBox.height30,
//                     Container(
//                       padding: const EdgeInsets.all(15),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(8),
//                         gradient: LinearGradient(
//                           colors: [
//                             Appcolors.kskybluecolor,
//                             Appcolors.kskybluecolor.withOpacity(.4)
//                           ],
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                         ),
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               TextStyles.body(
//                                 text: 'SL: ${currentIndex + 1}',
//                                 color: Appcolors.kblackColor,
//                                 weight: FontWeight.bold,
//                               ),
//                               ResponsiveText('content ID:${content.contentId}',
//                                   sizeFactor: .8,
//                                   color: Appcolors.kgreyColor,
//                                   weight: FontWeight.bold),
//                             ],
//                           ),
//                           ResponsiveSizedBox.height10,
//                           const Divider(
//                             thickness: 1,
//                             color: Appcolors.kblackColor,
//                           ),
//                           ResponsiveSizedBox.height10,
//                           SingleChildScrollView(
//                             child: Column(
//                               children: [
//                                 SizedBox(
//                                   height: ResponsiveUtils.hp(20),
//                                   width: ResponsiveUtils.wp(50),
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.network(
//                                       widget.state.contentlist[currentIndex]
//                                               .contentReference ??
//                                           '',
//                                       fit: BoxFit.cover,
//                                       loadingBuilder:
//                                           (context, child, loadingProgress) {
//                                         if (loadingProgress == null)
//                                           return child;
//                                         return Center(
//                                           child: CircularProgressIndicator(
//                                             value: loadingProgress
//                                                         .expectedTotalBytes !=
//                                                     null
//                                                 ? loadingProgress
//                                                         .cumulativeBytesLoaded /
//                                                     loadingProgress
//                                                         .expectedTotalBytes!
//                                                 : null,
//                                           ),
//                                         );
//                                       },
//                                       errorBuilder:
//                                           (context, error, stackTrace) {
//                                         return const Icon(
//                                           Icons.error,
//                                           color: Colors.red,
//                                           size: 50,
//                                         );
//                                       },
//                                     ),
//                                   ),
//                                 ),
//                                 ResponsiveSizedBox.height10,
//                                 Text(
//                                   content.sourceContent,
//                                   style: const TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w600),
//                                   maxLines: null,
//                                   overflow: TextOverflow.visible,
//                                   softWrap: true,
//                                 ),
//                               ],
//                             ),
//                           )
//                         ],
//                       ),
//                     ),
//                     ResponsiveSizedBox.height50,
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(5),
//                         border: Border.all(color: Colors.grey),
//                       ),
//                       child: Row(
                    
//                       ),
//                     ),
                  
//                   ]),

//                   // Navigation Icons
//                   Positioned(
//                     left: 0,
//                     right: 0,
//                     bottom: ResponsiveUtils.hp(62),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         // Previous Button
//                         if (currentIndex > 0)
//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Appcolors.kgreyColor.withOpacity(.3),
//                             ),
//                             child: IconButton(
//                               onPressed: _previousContent,
//                               icon: const Icon(Icons.chevron_left),
//                               iconSize: 40,
//                               color: Appcolors.kblackColor,
//                             ),
//                           )
//                         else
//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Appcolors.kgreyColor.withOpacity(.1),
//                             ),
//                             width: 50,
//                             height: 50,
//                           ),

//                         // Next Button
//                         if (currentIndex < widget.state.contentlist.length - 1)
//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Appcolors.kgreyColor.withOpacity(.3),
//                             ),
//                             child: IconButton(
//                               onPressed: _nextContent,
//                               icon: const Icon(Icons.chevron_right),
//                               iconSize: 40,
//                               color: Appcolors.kblackColor,
//                             ),
//                           )
//                         else
//                           Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: Appcolors.kgreyColor.withOpacity(.1),
//                             ),
//                             width: 50,
//                             height: 50,
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }
//           return SizedBox.shrink();
//         },
//       ),
//////////-----------////////////////////////////
// class _MyScreenState extends State<ScreenReviewDetailPage> {
//   late int currentIndex;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     currentIndex = widget.index;
//   }

//   Future<void> _nextContent() async {
//     if (currentIndex < widget.state.contentlist.length - 1 && !_isLoading) {
//       setState(() {
//         _isLoading = true;
//       });
      
//       // Add a small delay to ensure proper cleanup
//       await Future.delayed(const Duration(milliseconds: 100));
      
//       if (mounted) {
//         setState(() {
//           currentIndex++;
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _previousContent() async {
//     if (currentIndex > 0 && !_isLoading) {
//       setState(() {
//         _isLoading = true;
//       });
      
//       // Add a small delay to ensure proper cleanup
//       await Future.delayed(const Duration(milliseconds: 100));
      
//       if (mounted) {
//         setState(() {
//           currentIndex--;
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double progress = (currentIndex + 1) / widget.state.contentlist.length;
//     final content = widget.state.contentlist[currentIndex];

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(
//             CupertinoIcons.chevron_back,
//             size: 32,
//           ),
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//         ),
//         title: Column(
//           children: [
//             TextStyles.subheadline(text: widget.taskTitle),
//             TextStyles.body(text: 'Task ID:${widget.taskTargetID}'),
//           ],
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(6.0),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10),
//             child: LinearProgressIndicator(
//               minHeight: 6,
//               value: progress,
//               backgroundColor: Colors.grey[200],
//               valueColor: const AlwaysStoppedAnimation<Color>(
//                   Appcolors.kpurplelightColor),
//             ),
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
//         child: Stack(
//           children: [
//             ListView(
//               children: [
//                 ResponsiveSizedBox.height30,
//                 Container(
//                   padding: const EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                     borderRadius: BorderRadius.circular(8),
//                     gradient: LinearGradient(
//                       colors: [
//                         Appcolors.kskybluecolor,
//                         Appcolors.kskybluecolor.withOpacity(.4)
//                       ],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ),
//                   ),
//                   child: _isLoading 
//                       ? Center(
//                           child: Padding(
//                             padding: const EdgeInsets.all(20.0),
//                             child: CircularProgressIndicator(
//                               color: Appcolors.kpurplelightColor,
//                             ),
//                           ),
//                         )
//                       : Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 TextStyles.body(
//                                   text: 'SL:${currentIndex + 1}',
//                                   color: Appcolors.kblackColor,
//                                   weight: FontWeight.bold,
//                                 ),
//                                 ResponsiveText(
//                                   'content ID:${content.contentId}',
//                                   sizeFactor: .8,
//                                   color: Appcolors.kgreyColor,
//                                   weight: FontWeight.bold
//                                 ),
//                               ],
//                             ),
//                             ResponsiveSizedBox.height10,
//                             const Divider(
//                               thickness: 1,
//                               color: Appcolors.kblackColor,
//                             ),
//                             ResponsiveSizedBox.height10,
//                             SizedBox(
//                               height: ResponsiveUtils.hp(20),
//                               width: ResponsiveUtils.wp(50),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.network(
//                                   content.contentReference ?? '',
//                                   fit: BoxFit.cover,
//                                   loadingBuilder: (context, child, loadingProgress) {
//                                     if (loadingProgress == null) return child;
//                                     return Center(
//                                       child: CircularProgressIndicator(
//                                         value: loadingProgress.expectedTotalBytes != null
//                                             ? loadingProgress.cumulativeBytesLoaded /
//                                                 loadingProgress.expectedTotalBytes!
//                                             : null,
//                                       ),
//                                     );
//                                   },
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return const Icon(
//                                       Icons.error,
//                                       color: Colors.red,
//                                       size: 50,
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                             ResponsiveSizedBox.height10,
//                             Text(
//                               content.sourceContent,
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600
//                               ),
//                               maxLines: null,
//                               overflow: TextOverflow.visible,
//                               softWrap: true,
//                             ),
//                           ],
//                         ),
//                 ),
//                 ResponsiveSizedBox.height20,
//                 if (!_isLoading)
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(5),
//                       border: Border.all(color: Colors.grey),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         IconButton(
//                           onPressed: () {},
//                           icon: const Icon(Icons.message)
//                         ),
//                         (content.targetContent.isEmpty)
//                             ? Material(
//                                 shape: const CircleBorder(),
//                                 clipBehavior: Clip.antiAlias,
//                                 color: Appcolors.kgreyColor,
//                                 child: Container(
//                                   width: ResponsiveUtils.wp(9),
//                                   height: ResponsiveUtils.wp(9),
//                                   decoration: const BoxDecoration(
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: Center(
//                                     child: Icon(
//                                       Icons.play_arrow,
//                                       color: Appcolors.kwhiteColor,
//                                       size: ResponsiveUtils.wp(7),
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             : AudioPlayerButton(
//                                 audioUrl:
//                                     '${Endpoints.recordURL}${content.targetContent}',
//                                 contentId: content.contentId,
//                               ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),

//             // Navigation Icons
//             if (!_isLoading)
//               Positioned(
//                 left: 0,
//                 right: 0,
//                 bottom: ResponsiveUtils.hp(62),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     if (currentIndex > 0)
//                       Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Appcolors.kgreyColor.withOpacity(.3),
//                         ),
//                         child: IconButton(
//                           onPressed: _previousContent,
//                           icon: const Icon(Icons.chevron_left),
//                           iconSize: 40,
//                           color: Appcolors.kblackColor,
//                         ),
//                       ),

//                     if (currentIndex < widget.state.contentlist.length - 1)
//                       Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Appcolors.kgreyColor.withOpacity(.3),
//                         ),
//                         child: IconButton(
//                           onPressed: _nextContent,
//                           icon: const Icon(Icons.chevron_right),
//                           iconSize: 40,
//                           color: Appcolors.kblackColor,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }