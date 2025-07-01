import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/core/urls.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'dart:io';

import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_task_bloc/save_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/commentpage/commentpage.dart';
import 'package:sdcp_rebuild/presentation/screens/instructionalertpage/instructionalertpage.dart';
import 'package:sdcp_rebuild/presentation/screens/taskdetailspage/widgets/record_audiopage.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_imagecontainer.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_record_bloc/audio_record_bloc.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/presentation/widgets/simple_audio_player.dart';
// The GlobalAudioPlayer and SharedAudioPathProvider classes are defined in record_audiopage.dart

class ScreenPendingTaskDetailPage extends StatefulWidget {
  final String taskTargetID;
  final String taskTitle;
  final ContentTaskTargetSuccessState state;
  final int index;

  const ScreenPendingTaskDetailPage({
    super.key,
    required this.taskTargetID,
    required this.taskTitle,
    required this.state,
    required this.index,
  });

  @override
  State<ScreenPendingTaskDetailPage> createState() => _MyScreenState();
}

class _MyScreenState extends State<ScreenPendingTaskDetailPage> {
  late int currentIndex;
  bool isExpanded = false;
  final Map<String, bool> _audioAvailabilityCache = {};
  late AudioRecordBloc _audioRecordBloc;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
    _audioRecordBloc = AudioRecordBloc();
  }

  @override
  void dispose() {
    _audioRecordBloc.close();
    super.dispose();
  }

  // Add this method to show confirmation dialog for navigation
  Future<bool> _showNavigationConfirmationDialog(bool isNext) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Recording'),
          content: Text('Do you want to discard this recording and move to ${isNext ? "next" : "previous"} segment?'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK, discard it'),
              onPressed: () {
                Navigator.of(context).pop(true); // true means discard and navigate
              },
            ),
            TextButton(
              child: const Text('No, save it'),
              onPressed: () {
                Navigator.of(context).pop(false); // false means save and then navigate
              },
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Update the _hasOngoingRecording method with correct state types
  bool _hasOngoingRecording() {
    final audioRecorderState = _audioRecordBloc.state;
    return audioRecorderState is AudioRecording || audioRecorderState is AudioRecordingStopped;
  }

  // Update the navigation methods with correct event types
  Future<void> _nextContent() async {
    if (currentIndex < widget.state.contentlist.length - 1) {
      if (_hasOngoingRecording()) {
        final shouldDiscard = await _showNavigationConfirmationDialog(true);
        if (!shouldDiscard) {
          // Save the recording before navigating
          _audioRecordBloc.add(StopRecording());
          return;
        } else {
          // Discard the recording
          _audioRecordBloc.add(ResetRecording());
        }
      }
      setState(() {
        currentIndex++;
        isExpanded = false;
      });
    }
  }

  Future<void> _previousContent() async {
    if (currentIndex > 0) {
      if (_hasOngoingRecording()) {
        final shouldDiscard = await _showNavigationConfirmationDialog(false);
        if (!shouldDiscard) {
          // Save the recording before navigating
          _audioRecordBloc.add(StopRecording());
          return;
        } else {
          // Discard the recording
          _audioRecordBloc.add(ResetRecording());
        }
      }
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
    //final content = widget.state.contentlist[currentIndex];

    return BlocProvider.value(
      value: _audioRecordBloc,
      child: Scaffold(
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
        body: BlocListener<SaveTaskBloc, SaveTaskState>(
          listener: (context, state) {
            if (state is SaveTaskSuccessState) {
              print("💾 [taskpage] SaveTaskSuccessState received, serverUrl: ${state.serverUrl}");
              
              // Clear the cache for this content to force a refresh
              final contentId = widget.state.contentlist[currentIndex].contentId;
              _audioAvailabilityCache.remove(contentId);
              
              // Most direct update: Find our content model and directly update status
              try {
                // Get the current content from the current widget state
                if (widget.state.contentlist.length > currentIndex) {
                  final contentList = widget.state.contentlist;
                  final currentContent = contentList[currentIndex];
                  
                  // Force UI rebuild with setState, making sure the audio button is updated
                  setState(() {
                    print("💾 [taskpage] Forcing UI rebuild to reflect 'SAVED' status");
                    
                    // Immediately set the cache to true to prevent flicker
                    _audioAvailabilityCache[contentId] = true;
                  });
                  
                  // Immediately trigger a reload to get fresh data
                  Future.microtask(() {
                    if (mounted) {
                      context.read<ContentTaskTargetIdBloc>().add(
                        ContentTaskTargetIdLoadingEvent(
                          contentTaskTargetId: widget.taskTargetID
                        )
                      );
                    }
                  });
                }
              } catch (e) {
                print("❌ [taskpage] Error during direct content update: $e");
              }
              
              // Also try content bloc update
              try {
                final contentBlocState = context.read<ContentTaskTargetIdBloc>().state;
                if (contentBlocState is ContentTaskTargetSuccessState) {
                  context.read<ContentTaskTargetIdBloc>().add(
                    ContentTaskTargetIdUpdateStatusEvent(
                      contentId: widget.state.contentlist[currentIndex].contentId,
                      taskTargetId: widget.taskTargetID,
                      newStatus: "SAVED"
                    )
                  );
                }
              } catch (e) {
                print("❌ [taskpage] Error updating through bloc: $e");
              }
              
              // Show success notification
              // customAwesomeSnackbar(
              //   context,
              //   ContentType.success,
              //   "Upload Complete",
              //   "Successfully uploaded"
              // );
            } else if (state is SaveTaskRefreshNeededState) {
              print("🔄 [taskpage] SaveTaskRefreshNeededState received, serverUrl: ${state.serverUrl}");
              
              // Clear the cache for this content to force a refresh
              final contentId = widget.state.contentlist[currentIndex].contentId;
              _audioAvailabilityCache.remove(contentId);
              
              // Force UI rebuild with setState to immediately update audio button
              setState(() {
                print("🔄 [taskpage] Forcing UI refresh for content $contentId");
                // Immediately set the cache to true to prevent flicker
                _audioAvailabilityCache[contentId] = true;
              });
              
              // Trigger a reload to get fresh data
              if (mounted) {
                Future.microtask(() {
                  context.read<ContentTaskTargetIdBloc>().add(
                    ContentTaskTargetIdLoadingEvent(
                      contentTaskTargetId: widget.taskTargetID
                    )
                  );
                });
              }
            } else if (state is SaveTaskErrorState) {
              // Show error notification
              customAwesomeSnackbar(
                context,
                ContentType.failure,
                "Upload Error",
                state.message
              );
            }
          },
          child: BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
            builder: (context, state) {
              if (state is ContentTasktargetIdLoadingState) {
                return Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Appcolors.kpurplelightColor, size: 40),
                );
              }
              if (state is ContentTaskTargetSuccessState) {
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
                                  : ResponsiveUtils.hp(50), // Original height
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
                                          MinimumRecordingTimeUtils.buildMinimumTimeWidget(
                                            content.promptSpeechTime, 
                                            contentId: content.contentId,
                                          ) ?? const SizedBox.shrink(),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          ResponsiveText(
                                            'content ID:${content.contentId}',
                                            sizeFactor: .8,
                                            color: Appcolors.kgreyColor,
                                            weight: FontWeight.bold,
                                          ),
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
                                                networkUrl:
                                                    content.contentReferenceUrl,
                                                localPath:
                                                    content.contentReferencePath,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          ResponsiveSizedBox.height10,
                                          Text(
                                            content.sourceContent,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Navigation Buttons - Adjusted positions
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
                                        return CommentSheet(
                                          taskTargetId: widget.taskTargetID,
                                          contentId: content.contentId,
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.comment)),
                              FutureBuilder<String?>(
                                future: _getAudioPathForContent(content.contentId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Appcolors.kpurpleColor,
                                      ),
                                    );
                                  }
                                  
                                  final audioPath = snapshot.data;
                                  if (audioPath != null && audioPath.isNotEmpty) {
                                    return SimpleAudioPlayer(
                                      audioPath: audioPath,
                                      size: 40,
                                      backgroundColor: Appcolors.kpurpleColor,
                                      iconColor: Colors.white,
                                    );
                                  } else {
                                    // Show placeholder for no audio
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    );
                                  }
                                }
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
                        AudioRecorderWidget(
                          tasktargetId: widget.taskTargetID,
                          contentId: content.contentId,
                          onSubmit: (Map<String, dynamic> data) {
                            final base64Audio = data['audio'] as String;
                            
                            // Store the path in our cache for immediate use
                            if (data.containsKey('localPath')) {
                              final String localPath = data['localPath'] as String;
                              _audioAvailabilityCache[content.contentId] = true;
                              
                              // Force refresh of UI after submission
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  setState(() {
                                    print("Forcing UI refresh after audio submission");
                                  });
                                }
                              });
                            }
                            
                            // Submit the recording
                            context.read<SaveTaskBloc>().add(
                              SaveTaskButtonclickingEvent(
                                saveData: SubmitTaskModel(
                                  contentId: content.contentId,
                                  taskTargetId: content.taskTargetId,
                                  targetContent: base64Audio,
                                  isForceOnline: true
                                )
                              )
                            );
                          },
                        ),
                        ResponsiveSizedBox.height20,
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAudioContent(BuildContext context, dynamic content) {
    // Get the current state of SaveTaskBloc
    final saveTaskState = context.watch<SaveTaskBloc>().state;
    
    // More specific checks for audio availability
    final bool hasJustUploaded = saveTaskState is SaveTaskSuccessState &&
                               saveTaskState.serverUrl != null &&
                               saveTaskState.serverUrl!.isNotEmpty;
                               
    final bool hasExistingAudio = content.targetContentUrl != null && 
                              content.targetContentUrl.isNotEmpty &&
                              content.targetContentUrl.contains('/');
    
    // Force a cache refresh
    if (hasJustUploaded) {
      print("Force clearing audio cache for content ${content.contentId}");
      _audioAvailabilityCache.remove(content.contentId);
    }
                               
    // IMPORTANT: Check both database and GlobalAudioPlayer before deciding UI state
    return FutureBuilder<bool>(
      future: _checkForAvailableAudio(content.contentId),
      builder: (context, snapshot) {
        // Determine if we should show player based on ALL sources of truth
        final hasAudioInDb = snapshot.data ?? false;
        
        // CRITICAL FIX: Also check if GlobalAudioPlayer has a path for this content
        final audioPathInGlobalPlayer = GlobalAudioPlayer.getAudioPath(content.contentId);
        final hasAudioInGlobalPlayer = audioPathInGlobalPlayer != null && audioPathInGlobalPlayer.isNotEmpty;
        
        // More rigorous check for should show player - add the GlobalAudioPlayer check
        final shouldShowPlayer = hasJustUploaded || hasExistingAudio || hasAudioInDb || hasAudioInGlobalPlayer || content.targetDigitizationStatus == "SAVED";
        
        print('Content ${content.contentId}: DB=$hasAudioInDb, GlobalPlayer=$hasAudioInGlobalPlayer, Existing=$hasExistingAudio, Uploaded=$hasJustUploaded, ShowPlayer=$shouldShowPlayer');
        
        // If we should show player, return UnifiedAudioPlayerButton
        if (shouldShowPlayer) {
          // Get the most up-to-date URL or path
          String audioUrl = '';
          String localPath = '';
          
          // Check for local path in GlobalAudioPlayer first (most recent recordings)
          if (hasAudioInGlobalPlayer) {
            localPath = audioPathInGlobalPlayer;
            print('Using GlobalAudioPlayer path: $localPath');
          }
          
          // Then check other sources for URL
          if (hasJustUploaded && saveTaskState.serverUrl != null) {
            audioUrl = saveTaskState.serverUrl!;
            print('Using just uploaded URL: $audioUrl');
          } else if (hasExistingAudio) {
            audioUrl = '${Endpoints.recordURL}${content.targetContentUrl}';
            print('Using existing URL: $audioUrl');
          }
          
          return Column(
            children: [
              // Only show the player if content is saved or should show player is true
              SimpleAudioPlayer(
                // Force widget recreate with a timestamp in the key
                key: ValueKey('audio_player_${content.contentId}_${DateTime.now().millisecondsSinceEpoch}'),
                audioPath: localPath,
                size: 35,
                backgroundColor: Appcolors.kpurpleColor,
                iconColor: Colors.white,
              ),
              const SizedBox(height: 20),
              AudioRecorderWidget(
                tasktargetId: widget.taskTargetID,
                contentId: content.contentId,
                onSubmit: (Map<String, dynamic> data) {
                  final base64Audio = data['audio'] as String;
                  
                  // Store the path in our cache for immediate use
                  if (data.containsKey('localPath')) {
                    final String localPath = data['localPath'] as String;
                    _audioAvailabilityCache[content.contentId] = true;
                    
                    // Force refresh of UI after submission
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        setState(() {
                          print("Forcing UI refresh after audio submission");
                        });
                      }
                    });
                  }
                  
                  // Submit the recording
                  context.read<SaveTaskBloc>().add(
                    SaveTaskButtonclickingEvent(
                      saveData: SubmitTaskModel(
                        contentId: content.contentId,
                        taskTargetId: content.taskTargetId,
                        targetContent: base64Audio,
                        isForceOnline: true
                      )
                    )
                  );
                },
              ),
            ],
          );
        }
        
        // If still loading, show a small spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        
        // Otherwise, return just the AudioRecorderWidget
        return AudioRecorderWidget(
          tasktargetId: widget.taskTargetID,
          contentId: content.contentId,
          onSubmit: (Map<String, dynamic> data) {
            final base64Audio = data['audio'] as String;
            
            // Store the path in our cache for immediate use
            if (data.containsKey('localPath')) {
              final String localPath = data['localPath'] as String;
              _audioAvailabilityCache[content.contentId] = true;
              
              // Force refresh of UI after submission
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  setState(() {
                    print("Forcing UI refresh after audio submission");
                  });
                }
              });
            }
            
            // Submit the recording
            context.read<SaveTaskBloc>().add(
              SaveTaskButtonclickingEvent(
                saveData: SubmitTaskModel(
                  contentId: content.contentId,
                  taskTargetId: content.taskTargetId,
                  targetContent: base64Audio,
                  isForceOnline: true
                )
              )
            );
          },
        );
      },
    );
  }

  // Add new method that checks all possible sources for audio
  Future<bool> _checkForAvailableAudio(String contentId) async {
    // Check cache first
    if (_audioAvailabilityCache.containsKey(contentId)) {
      print('Using cached audio status for $contentId: ${_audioAvailabilityCache[contentId]}');
      return _audioAvailabilityCache[contentId]!;
    }
    
    try {
      // First check GlobalAudioPlayer - fastest and most immediate source
      final globalPath = GlobalAudioPlayer.getAudioPath(contentId);
      if (globalPath != null && globalPath.isNotEmpty) {
        // Verify the file exists
        final globalFile = File(globalPath);
        if (await globalFile.exists()) {
          final fileSize = await globalFile.length();
          print('Found valid audio in GlobalAudioPlayer: $globalPath (size: $fileSize bytes)');
          
          // If file is valid, make sure it's registered everywhere for consistency
          final dbHelper = ContentDatabaseHelper();
          await dbHelper.updateContent(
            contentId: contentId,
            audioPath: globalPath,
            base64Audio: '',
            serverUrl: null
          );
          
          // Update database status to SAVED to ensure UI reflects recorded status
          await dbHelper.updateContentStatus(
            contentId: contentId,
            status: "SAVED"
          );
          
          // Also ensure SharedAudioPathProvider has this path
          SharedAudioPathProvider.setAudioPaths(contentId, globalPath, null);
          
          _audioAvailabilityCache[contentId] = true;
          return true;
        }
      }
      
      // Check SharedAudioPathProvider next
      final sharedPaths = SharedAudioPathProvider.getAudioPaths(contentId);
      if (sharedPaths != null && sharedPaths['localPath']?.isNotEmpty == true) {
        final localFile = File(sharedPaths['localPath']!);
        if (await localFile.exists()) {
          final fileSize = await localFile.length();
          print('Found valid audio in SharedAudioPathProvider: ${sharedPaths['localPath']} (size: $fileSize bytes)');
          
          // Update GlobalAudioPlayer for consistency
          GlobalAudioPlayer.setCurrentAudio(contentId, sharedPaths['localPath']!);
          
          _audioAvailabilityCache[contentId] = true;
          return true;
        }
      }
      
      // Check database as last resort
      final dbHelper = ContentDatabaseHelper();
      final paths = await dbHelper.getAudioPathsForContent(contentId);
      
      // Check if we have audio in database
      final hasServerUrl = paths != null && 
                       paths.containsKey('serverUrl') && 
                       paths['serverUrl'] != null && 
                       paths['serverUrl']?.isNotEmpty == true &&
                       paths['serverUrl']!.contains('/'); // Must contain a slash to be valid
                       
      final hasLocalPath = paths != null && 
                       paths.containsKey('localPath') && 
                       paths['localPath'] != null && 
                       paths['localPath']?.isNotEmpty == true;
                       
      // If we have a local path, verify the file exists
      bool localFileExists = false;
      if (hasLocalPath) {
        final localFile = File(paths['localPath']!);
        localFileExists = await localFile.exists();
        
        if (localFileExists) {
          final fileSize = await localFile.length();
          print('Local file exists with size: $fileSize bytes');
          
          // Update our caches for fast future access
          GlobalAudioPlayer.setCurrentAudio(contentId, paths['localPath']!);
          SharedAudioPathProvider.setAudioPaths(contentId, paths['localPath']!, paths['serverUrl']);
        }
      }
      
      print('Database check for content $contentId: ' 'serverUrl=${paths?['serverUrl']}, ' 'localPath=${paths?['localPath']}, ' 'localFileExists=$localFileExists');
      
      final result = hasServerUrl || (hasLocalPath && localFileExists);
      
      // Cache the result
      _audioAvailabilityCache[contentId] = result;
      
      return result;
    } catch (e) {
      print('Error checking for available audio: $e');
      _audioAvailabilityCache[contentId] = false;
      return false;
    }
  }

  // Add the customAwesomeSnackbar method to your _MyScreenState class
  void customAwesomeSnackbar(
    BuildContext context, 
    ContentType contentType, 
    String title, 
    String message
  ) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  // Add new method to get audio path for content
  Future<String?> _getAudioPathForContent(String contentId) async {
    try {
      // First check GlobalAudioPlayer - fastest and most immediate source
      final globalPath = GlobalAudioPlayer.getAudioPath(contentId);
      if (globalPath != null && globalPath.isNotEmpty) {
        final globalFile = File(globalPath);
        if (await globalFile.exists()) {
          final fileSize = await globalFile.length();
          if (fileSize > 100) {
            print('Using GlobalAudioPlayer path for blue button: $globalPath (size: $fileSize bytes)');
            return globalPath;
          }
        }
      }
      
      // Check SharedAudioPathProvider next
      final sharedPaths = SharedAudioPathProvider.getAudioPaths(contentId);
      if (sharedPaths != null && sharedPaths.containsKey('localPath') && sharedPaths['localPath']!.isNotEmpty) {
        final file = File(sharedPaths['localPath']!);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 100) {
            print('Using SharedAudioPathProvider path for blue button: ${sharedPaths['localPath']}');
            return sharedPaths['localPath'];
          }
        }
      }
      
      // Check database as a last resort
      final dbHelper = ContentDatabaseHelper();
      final paths = await dbHelper.getAudioPathsForContent(contentId);
      
      if (paths != null && paths.containsKey('localPath') && paths['localPath']!.isNotEmpty) {
        final file = File(paths['localPath']!);
        if (await file.exists()) {
          final fileSize = await file.length();
          if (fileSize > 100) {
            print('Using database path for blue button: ${paths['localPath']}');
            
            // Cache this path for future use
            SharedAudioPathProvider.setAudioPaths(contentId, paths['localPath']!, paths['serverUrl']);
            GlobalAudioPlayer.setCurrentAudio(contentId, paths['localPath']!);
            
            return paths['localPath'];
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting audio path: $e');
      return null;
    }
  }
}
