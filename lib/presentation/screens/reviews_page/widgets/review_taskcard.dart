import 'dart:async';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/domain/databases/review_content_database_helper.dart';

import 'package:sdcp_rebuild/presentation/blocs/review_content_bloc/review_content_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/reviews_page/widgets/review_audio_button.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'package:sdcp_rebuild/presentation/widgets/simple_audio_player.dart';

class ReviewTaskcard extends StatefulWidget {
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

  @override
  State<ReviewTaskcard> createState() => _ReviewTaskcardState();
}

class _ReviewTaskcardState extends State<ReviewTaskcard> with SingleTickerProviderStateMixin {
  late AnimationController _downloadCompleteController;
  bool _showDownloadComplete = false;
  Timer? _downloadCompleteTimer;

  @override
  void initState() {
    super.initState();
    _downloadCompleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Periodically check if icon should be refresh
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _checkIconState();
      }
    });
  }

  @override
  void dispose() {
    _downloadCompleteController.dispose();
    _downloadCompleteTimer?.cancel();
    super.dispose();
  }

  Future<bool> _isTaskDownloaded(String taskCode) async {
    final dbHelper = ReviewContentDatabaseHelper();
    final contents = await dbHelper.getContentsByTargetTaskTargetId(taskCode);
    return contents.isNotEmpty;
  }

  Future<String?> _getFirstContentId(String taskCode) async {
    final dbHelper = ReviewContentDatabaseHelper();
    final contents = await dbHelper.getContentsByTargetTaskTargetId(taskCode);
    if (contents.isNotEmpty) {
      return contents.first.contentId;
    }
    return null;
  }

  Future<String?> _getContentPath(String taskCode) async {
    final dbHelper = ReviewContentDatabaseHelper();
    final contents = await dbHelper.getContentsByTargetTaskTargetId(taskCode);
    if (contents.isNotEmpty && contents.first.targetTargetContentPath.isNotEmpty) {
      return contents.first.targetTargetContentPath;
    }
    return null;
  }
  
  void _showDownloadCompleteAnimation() {
    setState(() {
      _showDownloadComplete = true;
    });
    _downloadCompleteController.forward(from: 0.0);
    
    // Hide the animation after 2 seconds
    _downloadCompleteTimer?.cancel();
    _downloadCompleteTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showDownloadComplete = false;
        });
      }
    });
  }

  void _checkIconState() async {
    final isDownloaded = await _isTaskDownloaded(widget.taskCode);
    if (isDownloaded && mounted) {
      setState(() {
        // Force refresh of the icon
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue[100]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(widget.title,
                    sizeFactor: .8,
                    color: Colors.black,
                    weight: FontWeight.bold),
                TextStyles.body(
                  text: widget.taskStatus,
                  color: Colors.black,
                ),
              ],
            ),
            const Divider(
              thickness: 1,
              color: Colors.grey,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextStyles.body(
                      text: 'Task Code',
                      color: Colors.black,
                    ),
                    ResponsiveSizedBox.height5,
                    ResponsiveText(widget.taskCode,
                        sizeFactor: .8,
                        color: Colors.black,
                        weight: FontWeight.bold),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextStyles.body(
                      text: 'Task-Prefix',
                      color: Colors.black,
                    ),
                    ResponsiveSizedBox.height5,
                    ResponsiveText(widget.taskPrefix,
                        sizeFactor: .8,
                        color: Colors.black,
                        weight: FontWeight.bold),
                  ],
                ),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        BlocConsumer<ReviewContentBloc, ReviewContentState>(
                          listener: (context, state) {
                            if (state is ReviewContentDownloadSuccessState &&
                                state.contentTaskTargetId == widget.taskCode) {
                              
                              // Schedule UI updates for the next frame to ensure they happen
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                // Show success notification
                                if (context.mounted) {
                                  CustomSnackBar.show(
                                      context: context,
                                      title: 'Success',
                                      message: 'Task downloaded Successfully',
                                      contentType: ContentType.success);
                                  
                                  // Show download complete animation
                                  _showDownloadCompleteAnimation();
                                  
                                  // Force rebuild
                                  setState(() {});
                                }
                              });
                            }
                            if (state is ReviewContentErrrorState &&
                                state.contentTaskTargetId == widget.taskCode) {
                              CustomSnackBar.show(
                                  context: context,
                                  title: 'Error !!',
                                  message: 'Task download failed',
                                  contentType: ContentType.failure);
                            }
                            if (state is ReviewContentAudioSuccessState &&
                                state.contentTaskTargetId == widget.taskCode) {
                              CustomSnackBar.show(
                                  context: context,
                                  title: 'Success',
                                  message: 'Audio playing',
                                  contentType: ContentType.success);
                            }
                            if (state is ReviewContentAudioErrorState &&
                                state.contentTaskTargetId == widget.taskCode) {
                              CustomSnackBar.show(
                                  context: context,
                                  title: 'Error',
                                  message: 'Failed to play audio',
                                  contentType: ContentType.failure);
                            }
                          },
                          builder: (context, state) {
                            final isLoading = state is ReviewContentDownloadingState &&
                                state.contentTaskTargetId == widget.taskCode;
                                
                            // Check if this task just completed downloading
                            final justCompleted = state is ReviewContentDownloadSuccessState &&
                                state.contentTaskTargetId == widget.taskCode;

                            if (isLoading) {
                              return LoadingAnimationWidget.inkDrop(
                                  color: Colors.black,
                                  size: ResponsiveUtils.wp(6));
                            }
                            
                            // If download just completed, show refresh icon immediately
                            if (justCompleted) {
                              return GestureDetector(
                                onTap: () {
                                  context.read<ReviewContentBloc>().add(
                                    ReviewContentDownloadingEvent(taskTargetId: widget.taskCode)
                                  );
                                },
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.black,
                                  size: ResponsiveUtils.wp(6),
                                ),
                              );
                            }
                            
                            return FutureBuilder<bool>(
                              future: _isTaskDownloaded(widget.taskCode),
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
                                      ReviewContentDownloadingEvent(taskTargetId: widget.taskCode)
                                    );
                                  },
                                  child: Icon(
                                    isDownloaded ? Icons.refresh : Icons.download,
                                    color: Colors.black,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        
                        // Download complete animation overlay
                        if (_showDownloadComplete)
                          AnimatedBuilder(
                            animation: _downloadCompleteController,
                            builder: (context, child) {
                              return Container(
                                width: ResponsiveUtils.wp(10),
                                height: ResponsiveUtils.wp(10),
                                decoration: BoxDecoration(
                                  color: Appcolors.kgreenColor.withOpacity(0.8 * _downloadCompleteController.value),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24 * _downloadCompleteController.value,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    FutureBuilder<bool>(
                      future: _isTaskDownloaded(widget.taskCode),
                      builder: (context, snapshot) {
                        final isDownloaded = snapshot.data ?? false;
                        
                        if (!isDownloaded) {
                          return const SizedBox.shrink(); // Don't show audio button if not downloaded
                        }
                        
                        return FutureBuilder<String?>(
                          future: _getFirstContentId(widget.taskCode),
                          builder: (context, contentIdSnapshot) {
                            if (contentIdSnapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            
                            if (!contentIdSnapshot.hasData || contentIdSnapshot.data == null) {
                              // Try to get the file path directly if contentId is not available
                              return FutureBuilder<String?>(
                                future: _getContentPath(widget.taskCode),
                                builder: (context, pathSnapshot) {
                                  if (pathSnapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  if (!pathSnapshot.hasData || pathSnapshot.data == null) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return SimpleAudioPlayer(
                                    audioPath: pathSnapshot.data!,
                                    size: ResponsiveUtils.wp(7),
                                    backgroundColor: Colors.black,
                                    iconColor: Colors.white,
                                  );
                                }
                              );
                            }
                            
                            return ReviewAudioButton(
                              taskCode: widget.taskCode,
                              contentId: contentIdSnapshot.data!,
                              backgroundColor: Colors.black,
                              iconColor: Colors.white,
                              size: ResponsiveUtils.wp(7),
                            );
                          }
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
