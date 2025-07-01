import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';

import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'dart:async';

class TaskCard extends StatefulWidget {
  final String title;
  final String taskCode;
  final String taskPrefix;
  final String taskStatus;
  final int index;

  const TaskCard({
    super.key,
    required this.title,
    required this.taskCode,
    required this.taskPrefix,
    required this.index,
    required this.taskStatus,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _downloadCompleteController.dispose();
    _downloadCompleteTimer?.cancel();
    super.dispose();
  }

  Future<bool> _isTaskDownloaded(String taskCode) async {
    final dbHelper = ContentDatabaseHelper();
    final contents = await dbHelper.getContentsByTaskTargetId(taskCode);
    return contents.isNotEmpty;
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Regular download button and states
                    BlocConsumer<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
                      listener: (context, state) {
                        if (state is ContentDownloadSuccessState &&
                            state.contentTaskTargetId == widget.taskCode) {
                          // Show success notification
                          CustomSnackBar.show(
                              context: context,
                              title: 'Success',
                              message: 'Task downloaded Successfully',
                              contentType: ContentType.success);
                              
                          // Show download complete animation
                          _showDownloadCompleteAnimation();
                          
                          // Force rebuild to update icon
                          setState(() {});
                        }
                        if (state is ContentTaskTargetErrrorState &&
                            state.contentTaskTargetId == widget.taskCode) {
                          CustomSnackBar.show(
                              context: context,
                              title: 'Error !!',
                              message: 'Task download failed',
                              contentType: ContentType.failure);
                        }
                      },
                      builder: (context, state) {
                        // Check if this task is currently being downloaded
                        final isLoading = state is ContentDownloadingState &&
                            state.contentTaskTargetId == widget.taskCode;
                        
                        // Check if this task just completed downloading
                        final justCompleted = state is ContentDownloadSuccessState &&
                            state.contentTaskTargetId == widget.taskCode;

                        if (isLoading) {
                          // Show loading animation during download
                          return LoadingAnimationWidget.inkDrop(
                              color: Colors.black,
                              size: ResponsiveUtils.wp(6));
                        }
                        
                        // If download just completed, show refresh icon immediately without checking database
                        if (justCompleted) {
                          return GestureDetector(
                            onTap: () {
                              context.read<ContentTaskTargetIdBloc>().add(
                                ContentTaskDownloadingEvent(
                                  contentTaskTargetId: widget.taskCode
                                )
                              );
                            },
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.black,
                            ),
                          );
                        }
                        
                        // Otherwise, check database to determine if task is downloaded
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
                                context.read<ContentTaskTargetIdBloc>().add(
                                  ContentTaskDownloadingEvent(
                                    contentTaskTargetId: widget.taskCode
                                  )
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
