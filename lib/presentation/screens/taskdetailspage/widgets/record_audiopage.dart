import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_record_bloc/audio_record_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_task_bloc/save_task_bloc.dart';
import 'package:sdcp_rebuild/data/content_model.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_waveform.dart';
import 'package:sdcp_rebuild/presentation/widgets/simple_audio_player.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';
import 'package:sdcp_rebuild/core/shared_audio_path_provider.dart';

class AudioRecorderWidget extends StatefulWidget {
  final String tasktargetId;
  final String contentId;
  final Function(Map<String, dynamic>) onSubmit;

  const AudioRecorderWidget({
    super.key,
    required this.tasktargetId,
    required this.contentId,
    required this.onSubmit,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  @override
  void initState() {
    super.initState();
    // Initialize by fetching current content status
    // context.read<ContentTaskTargetIdBloc>().add(
    //   ContentTaskInitialFetchingEvent(
    //     contentTaskTargetId: widget.tasktargetId
    //   )
    // );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
      listener: (context, taskState) {
        if (taskState is ContentTaskTargetSuccessState) {
          ContentModel? currentContentModel;
          try {
            currentContentModel = taskState.contentlist.firstWhere(
              (content) => content.contentId == widget.contentId,
            );
          } catch (e) {
            print("ℹ️ [AudioRecorderWidget] Content ${widget.contentId} not found in updated list.");
            currentContentModel = null;
          }

          if (currentContentModel != null) {
            final status = currentContentModel.targetDigitizationStatus;
            final isProcessed = status == "SAVED_LOCALLY" ||
                                status == "SAVED_ON_SERVER" ||
                                status == "SAVED";

            // Check AudioRecordBloc's state directly
            final audioState = context.read<AudioRecordBloc>().state;
            if (isProcessed && (audioState is AudioRecordingStopped || audioState is AudioPlaying)) {
              print("🔄 [AudioRecorderWidget] Content ${widget.contentId} (status: $status) processed externally. Resetting UI.");
              context.read<AudioRecordBloc>().add(ResetToInitialState());
            }
          }
        }
      },
      child: BlocBuilder<AudioRecordBloc, AudioRecordState>(
        builder: (context, state) {
          if (state is AudioRecording) {
            // Recording in progress UI
            return Column(
              children: [
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AudioWaveform(
                    samples: state.waveformData,
                    color: Appcolors.kredColor,
                    isRecording: true,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.pause, color: Appcolors.kprimaryColor),
                        iconSize: 30,
                        onPressed: () {
                          context.read<AudioRecordBloc>().add(PauseRecording());
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.stop, color: Appcolors.kredColor),
                        iconSize: 30,
                        onPressed: () {
                          context.read<AudioRecordBloc>().add(StopRecording());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is AudioRecordingStopped) {
            // Recording stopped/complete UI
            return Column(
              children: [
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AudioWaveform(
                    samples: state.waveformData,
                    color: Appcolors.kpurpleColor,
                    isRecording: false,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SimpleAudioPlayer(
                        audioPath: state.filePath,
                        size: 40,
                        backgroundColor: Appcolors.kpurpleColor,
                        iconColor: Colors.white,
                        onInit: () {
                          final String capturedPath = state.filePath;
                          if (capturedPath.isNotEmpty) {
                            print("🎵 Initializing SimpleAudioPlayer with path: $capturedPath");
                            GlobalAudioPlayer.setCurrentAudio(widget.contentId, capturedPath);
                            SharedAudioPathProvider.setAudioPaths(widget.contentId, capturedPath, null);
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        iconSize: 30,
                        onPressed: () {
                          context.read<AudioRecordBloc>().add(ResetRecording());
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        iconSize: 30,
                        onPressed: () => _submitRecording(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is AudioPlaying) {
            // Playing state
            return Column(
              children: [
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AudioWaveform(
                    samples: (state as dynamic).waveformData,
                    color: Appcolors.kpurpleColor,
                    isRecording: false,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SimpleAudioPlayer(
                        audioPath: (state as dynamic).path,
                        size: 40,
                        backgroundColor: Appcolors.kpurpleColor,
                        iconColor: Colors.white,
                        onInit: () {
                          final String capturedPath = (state as dynamic).path;
                          if (capturedPath.isNotEmpty) {
                            print("🎵 Initializing SimpleAudioPlayer with path: $capturedPath (playing)");
                            GlobalAudioPlayer.setCurrentAudio(widget.contentId, capturedPath);
                            SharedAudioPathProvider.setAudioPaths(widget.contentId, capturedPath, null);
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        iconSize: 30,
                        onPressed: () {
                          context.read<AudioRecordBloc>().add(ResetRecording());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Default/initial UI - the "Tap to Record" with red button like in the first image
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // Check the content status to determine the text
                  BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
                    builder: (context, state) {
                      if (state is ContentTaskTargetSuccessState) {
                        try {
                          final currentContent = state.contentlist.firstWhere(
                            (content) => content.contentId == widget.contentId,
                          );

                          // Determine the text based on the status
                          String displayText = currentContent.targetDigitizationStatus == "SAVED_LOCALLY" || 
                                               currentContent.targetDigitizationStatus == "SAVED" 
                                               ? "Re-record" 
                                               : "Tap to Record";

                          return Text(displayText); // Change the text here
                        } catch (e) {
                          return const Text('Tap to Record'); // Default text if not found
                        }
                      }
                      return const Text('Tap to Record'); // Default text if state is not success
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status Icon
                      BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
                        buildWhen: (previous, current) {
                          if (previous is ContentTaskTargetSuccessState && current is ContentTaskTargetSuccessState) {
                            ContentModel? prevContent;
                            ContentModel? currContent;
                            try {
                              prevContent = previous.contentlist.firstWhere((c) => c.contentId == widget.contentId);
                            } catch (_) {
                              // prevContent remains null if not found or if previous.contentlist is not as expected
                            }
                            try {
                              currContent = current.contentlist.firstWhere((c) => c.contentId == widget.contentId);
                            } catch (_) {
                              // currContent remains null if not found or if current.contentlist is not as expected
                            }
                            // Only rebuild if the relevant content's status changed or if it appeared/disappeared
                            return prevContent?.targetDigitizationStatus != currContent?.targetDigitizationStatus || (prevContent == null && currContent != null) || (prevContent != null && currContent == null);
                          }
                          return previous != current; // Default rebuild for other state transitions (e.g., loading to success)
                        },
                        builder: (context, state) {
                          if (state is ContentTaskTargetSuccessState) {
                            try {
                              final currentContent = state.contentlist.firstWhere(
                                (content) => content.contentId == widget.contentId,
                              );
                              
                              IconData statusIcon;
                              Color iconColor;
                              String statusText;

                              switch (currentContent.targetDigitizationStatus) {
                                case "SAVED_LOCALLY":
                                  statusIcon = Icons.cloud_upload_outlined;
                                  iconColor = Colors.amber;
                                  statusText = "";
                                  break;
                                case "SAVED_ON_SERVER":
                                case "SAVED":
                                  statusIcon = Icons.cloud_done;
                                  iconColor = Colors.green;
                                  statusText = "";
                                  break;
                                default:
                                  statusIcon = Icons.cloud_off_outlined;
                                  iconColor = Colors.grey;
                                  statusText = "";
                              }

                              return Container(
                                width: 24,
                                height: 40,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, color: iconColor, size: 24),
                                    if (statusText.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: iconColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              );
                            } catch (e) {
                              return const SizedBox(width: 24, height: 40);
                            }
                          }
                          return const SizedBox(width: 24, height: 40);
                        },
                      ),
                      const SizedBox(width: 20),
                      // Record Button
                      IconButton(
                        icon: const Icon(
                          Icons.mic,
                          color: Appcolors.kredColor,
                          size: 35,
                        ),
                        onPressed: () {
                          context.read<AudioRecordBloc>().add(StartRecording());
                        },
                      ),
                      const SizedBox(width: 20),
                      // Sync Button
                      BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
                        buildWhen: (previous, current) {
                          if (previous is ContentTaskTargetSuccessState && current is ContentTaskTargetSuccessState) {
                            ContentModel? prevContent;
                            ContentModel? currContent;
                            try {
                              prevContent = previous.contentlist.firstWhere((c) => c.contentId == widget.contentId);
                            } catch (_) {
                              // prevContent remains null
                            }
                            try {
                              currContent = current.contentlist.firstWhere((c) => c.contentId == widget.contentId);
                            } catch (_) {
                              // currContent remains null
                            }
                            // Only rebuild if the relevant content's status changed (specifically to/from SAVED_LOCALLY) or if it appeared/disappeared
                            bool prevCanSync = prevContent?.targetDigitizationStatus == "SAVED_LOCALLY";
                            bool currCanSync = currContent?.targetDigitizationStatus == "SAVED_LOCALLY";
                            return prevCanSync != currCanSync || (prevContent == null && currContent != null) || (prevContent != null && currContent == null);
                          }
                          return previous != current; // Default rebuild
                        },
                        builder: (context, state) {
                          if (state is ContentTaskTargetSuccessState) {
                            try {
                              final currentContent = state.contentlist.firstWhere(
                                (content) => content.contentId == widget.contentId,
                              );
                              
                              if (currentContent.targetDigitizationStatus == "SAVED_LOCALLY") {
                                return IconButton(
                                  icon: const Icon(Icons.sync, size: 18),
                                  onPressed: () async {
                                    var connectivityResult = await (Connectivity().checkConnectivity());
                                    bool isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
                                                    connectivityResult.contains(ConnectivityResult.wifi);

                                    if (!isOnline) {
                                      if (!context.mounted) return;
                                      CustomSnackBar.show(
                                        context: context,
                                        title: 'Offline',
                                        message: 'Cannot sync. Please check your internet connection.',
                                        contentType: ContentType.warning
                                      );
                                      return;
                                    }

                                    final dbHelper = ContentDatabaseHelper();
                                    final paths = await dbHelper.getAudioPathsForContent(widget.contentId);
                                    final localPath = paths?['localPath'];

                                    if (localPath == null || localPath.isEmpty) {
                                      if (!context.mounted) return;
                                      CustomSnackBar.show(
                                        context: context,
                                        title: 'Error',
                                        message: 'Local audio file not found. Cannot sync.',
                                        contentType: ContentType.failure
                                      );
                                      return;
                                    }

                                    final file = File(localPath);
                                    if (!await file.exists()) {
                                      if (!context.mounted) return;
                                      CustomSnackBar.show(
                                        context: context,
                                        title: 'Error',
                                        message: 'Local audio file not found. Cannot sync.',
                                        contentType: ContentType.failure
                                      );
                                      return;
                                    }

                                    final fileBytes = await file.readAsBytes();
                                    final base64String = base64Encode(fileBytes);

                                    final saveData = SubmitTaskModel(
                                      contentId: widget.contentId,
                                      targetContent: base64String,
                                      isForceOnline: true,
                                      taskTargetId: widget.tasktargetId,
                                    );

                                    if (!context.mounted) return;
                                    CustomSnackBar.show(
                                      context: context,
                                      title: 'Syncing...',
                                      message: 'Uploading content ${widget.contentId} to server.',
                                      contentType: ContentType.help
                                    );

                                    context.read<SaveTaskBloc>().add(
                                      SaveTaskButtonclickingEvent(saveData: saveData)
                                    );

                                    // Update the database status
                                    await dbHelper.updateContentStatus(
                                      contentId: widget.contentId,
                                      status: "SAVED_ON_SERVER"
                                    );

                                    // Refresh the UI
                                    if (context.mounted) {
                                      context.read<ContentTaskTargetIdBloc>().add(
                                        ContentTaskTargetIdLoadingEvent(
                                          contentTaskTargetId: widget.tasktargetId
                                        )
                                      );
                                    }
                                  },
                                );
                              } else {
                                return const SizedBox(width: 48);
                              }
                            } catch (e) {
                              print("Error in sync button builder: $e");
                              return const SizedBox(width: 48);
                            }
                          }
                          return const SizedBox(width: 48);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _submitRecording(BuildContext context) async {
    final audioRecordBloc = context.read<AudioRecordBloc>();
    final contentTaskBloc = context.read<ContentTaskTargetIdBloc>();
    final recorderState = audioRecordBloc.state;

    if (recorderState is AudioRecordingStopped) {
      try {
        print("🎯 [_submitRecording] Starting submission for contentId: ${widget.contentId}");
        
        final file = File(recorderState.filePath);
        if (!await file.exists()) {
          throw Exception("Recording file not found at ${recorderState.filePath}");
        }

        final fileBytes = await file.readAsBytes();
        final base64String = base64Encode(fileBytes);
        
        final ContentDatabaseHelper dbHelper = ContentDatabaseHelper();
        final String permanentPath = await dbHelper.moveRecordingToPermanentStorage(recorderState.filePath);
        
        print("🎯 [_submitRecording] Moved recording to permanent path: $permanentPath");
        
        SharedAudioPathProvider.setAudioPaths(widget.contentId, permanentPath, null);
        GlobalAudioPlayer.setCurrentAudio(widget.contentId, permanentPath);
        
        // 1. Always save locally first
        await dbHelper.updateContent(
          contentId: widget.contentId,
          audioPath: permanentPath,
          base64Audio: base64String,
          serverUrl: null 
        );
        
        await dbHelper.updateContentStatus(
          contentId: widget.contentId,
          status: "SAVED_LOCALLY"
        );

        // Update BLoC state to SAVED_LOCALLY
        if (context.mounted) {
          contentTaskBloc.add(
            ContentTaskTargetIdUpdateStatusEvent(
              contentId: widget.contentId,
              taskTargetId: widget.tasktargetId,
              newStatus: "SAVED_LOCALLY"
            )
          );
        }
        print("🎯 [_submitRecording] Local save complete. Status set to SAVED_LOCALLY for contentId: ${widget.contentId}.");

        // 2. Check network connectivity
        var connectivityResult = await (Connectivity().checkConnectivity());
        bool isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
                        connectivityResult.contains(ConnectivityResult.wifi);

        if (isOnline) {
          print("🎯 [_submitRecording] Device is ONLINE. Attempting server submission for ${widget.contentId}.");
          // 3. If ONLINE, attempt to submit to server
          try {
            await widget.onSubmit({
              'audio': base64String,
              'isOffline': false, 
              'localPath': permanentPath,
              'contentId': widget.contentId
            });
            print("🎯 [_submitRecording] onSubmit call (server submission) successful for ${widget.contentId}.");
            
            await dbHelper.updateContentStatus(
              contentId: widget.contentId,
              status: "SAVED_ON_SERVER"
            );
            if (context.mounted) {
              contentTaskBloc.add(
                ContentTaskTargetIdUpdateStatusEvent(
                  contentId: widget.contentId,
                  taskTargetId: widget.tasktargetId,
                  newStatus: "SAVED_ON_SERVER"
                )
              );
            }
            print("🎯 [_submitRecording] Status updated to SAVED_ON_SERVER for ${widget.contentId}.");

          } catch (e) {
            print("❌ [_submitRecording] Error during onSubmit (server submission) for ${widget.contentId}: $e");
            if (context.mounted) {
              customAwesomeSnackbar(
                context,
                ContentType.warning,
                "Server Upload Failed",
                "Could not save to server: ${e.toString()}. Saved locally."
              );
            }
          }
        } else {
          // 4. If OFFLINE, inform user it's saved locally
          print("🎯 [_submitRecording] Device is OFFLINE. Recording saved locally for ${widget.contentId}.");
          if (context.mounted) {
            //  customAwesomeSnackbar(
            //     context,
            //     ContentType.success,
            //     "Saved Locally",
            //     "Recording saved locally. Please sync when online."
            //   );
          }
        }
        
        if (context.mounted) {
          audioRecordBloc.add(ResetToInitialState());
        }
        
      } catch (e) {
        print("❌ [_submitRecording] General error during submission for ${widget.contentId}: $e");
        if (context.mounted) {
          customAwesomeSnackbar(
            context,
            ContentType.failure,
            "Error",
            "Submission process failed: ${e.toString()}"
          );
        }
      }
    }
  }

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

  // Add this method to handle recording
  void _startRecording(BuildContext context) {
    context.read<AudioRecordBloc>().add(StartRecording());
  }

  // Add this method to handle stopping recording
  void _stopRecording(BuildContext context) {
    context.read<AudioRecordBloc>().add(StopRecording());
  }

  // Add this method to verify the database was updated
  Future<void> _verifyDatabaseUpdate(String contentId) async {
    try {
      final dbHelper = ContentDatabaseHelper();
      
      // Use getAudioPathsForContent instead of getContentById
      final contentPaths = await dbHelper.getAudioPathsForContent(contentId);
      
      print('Database verification: contentPaths=$contentPaths');
      
      // Check if we have a server URL in the paths
      if (contentPaths != null && 
          contentPaths.containsKey('serverUrl') && 
          contentPaths['serverUrl'] != null && 
          contentPaths['serverUrl']?.isNotEmpty == true) {
        
        if (mounted) {
          // Force rebuild of the entire task page
          context.read<ContentTaskTargetIdBloc>().add(
            ContentTaskInitialFetchingEvent(
              contentTaskTargetId: widget.tasktargetId
            )
          );
        }
      }
    } catch (e) {
      print('Error verifying database update: $e');
    }
  }
}

// class AudioUploadHelper {
//   /// Converts an audio file to base64 string
//   static Future<String> convertAudioToBase64(String filePath) async {
//     try {
//       // Read the file
//       File audioFile = File(filePath);

//       // Check if file exists
//       if (!await audioFile.exists()) {
//         throw Exception('Audio file does not exist');
//       }

//       // Read file bytes
//       List<int> audioBytes = await audioFile.readAsBytes();

//       // Convert to base64
//       String base64Audio = base64Encode(audioBytes);

//       return base64Audio;
//     } catch (e) {
//       print('Error converting audio to base64: $e');
//       rethrow;
//     }
//   }

//   /// Optional: Get file size for additional validation
//   static Future<int> getAudioFileSize(String filePath) async {
//     File audioFile = File(filePath);
//     return await audioFile.length();
//   }
// }
class AudioUploadHelper {
  static Future<AudioUploadResult> storeAudioFormats(String filePath) async {
    try {
      // Check file existence
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist: $filePath');
      }
      
      // Get file bytes
      final List<int> audioBytes = await file.readAsBytes();

      // Convert to base64
      final String base64Audio = base64Encode(audioBytes);
      
      print("CRITICAL DEBUG: Creating AudioUploadResult with isOffline=false");
      
      // Return result - make sure this is passed all the way to your UI
      return AudioUploadResult(
        base64String: base64Audio,
        isOffline: false,  // This MUST be respected by the UI
        originalPath: filePath,
        wavPath: filePath,
      );
    } catch (e) {
      print('Error in storeAudioFormats: $e');
      rethrow;
    }
  }

  /// Get base64 string from stored base64 file
  static Future<String> getBase64FromFile(String base64FilePath) async {
    try {
      final file = File(base64FilePath);
      if (!await file.exists()) {
        throw Exception('Base64 file does not exist');
      }
      return await file.readAsString();
    } catch (e) {
      print('Error reading base64 file: $e');
      rethrow;
    }
  }

  /// Optional: Get file sizes for validation
  static Future<AudioFileSizes> getAudioFileSizes(
    String wavPath, 
    String base64Path
  ) async {
    final wavSize = await File(wavPath).length();
    final base64Size = await File(base64Path).length();
    
    return AudioFileSizes(
      wavSize: wavSize,
      base64Size: base64Size,
    );
  }
}

// Class to hold both file paths and base64 string
class AudioStorageResult {
  final String wavPath;
  final String base64Path;
  final String base64String;

  AudioStorageResult({
    required this.wavPath,
    required this.base64Path,
    required this.base64String,
  });
}

// Optional class for file sizes
class AudioFileSizes {
  final int wavSize;
  final int base64Size;

  AudioFileSizes({
    required this.wavSize,
    required this.base64Size,
  });
}

// Make sure you have this class defined
class AudioUploadResult {
  final String base64String;
  final bool isOffline;
  final String originalPath;
  final String wavPath;
  
  AudioUploadResult({
    required this.base64String, 
    required this.isOffline, 
    required this.originalPath, 
    required this.wavPath,
  });
}

// Add a new SharedAudioPathProvider class at the bottom of the file
class SharedAudioPathProvider {
  static final SharedAudioPathProvider _instance = SharedAudioPathProvider._internal();
  static final Map<String, Map<String, String>> _audioPaths = {};
  
  factory SharedAudioPathProvider() {
    return _instance;
  }
  
  SharedAudioPathProvider._internal();
  
  static void setAudioPaths(String contentId, String localPath, String? serverUrl) {
    _audioPaths[contentId] = {
      'localPath': localPath,
      'serverUrl': serverUrl ?? '',
    };
    print("👉 SharedAudioPathProvider: Set paths for $contentId: localPath=$localPath, serverUrl=${serverUrl ?? 'null'}");
  }
  
  static Map<String, String>? getAudioPaths(String contentId) {
    return _audioPaths[contentId];
  }
}

// Add a new GlobalAudioPlayer class at the bottom of the file
class GlobalAudioPlayer {
  static final GlobalAudioPlayer _instance = GlobalAudioPlayer._internal();
  static AudioRecordBloc? _audioBloc;
  static final Map<String, String> _currentAudioPaths = {};
  static bool _isPlaying = false;
  
  factory GlobalAudioPlayer() {
    return _instance;
  }
  
  GlobalAudioPlayer._internal();
  
  static void setAudioBloc(AudioRecordBloc bloc) {
    _audioBloc = bloc;
  }
  
  static void setCurrentAudio(String contentId, String audioPath) {
    _currentAudioPaths[contentId] = audioPath;
    print("🔈 GlobalAudioPlayer: Set audio for $contentId: $audioPath");
  }
  
  static String? getAudioPath(String contentId) {
    return _currentAudioPaths[contentId];
  }
  
  static Future<void> playContentAudio(BuildContext context, String contentId) async {
    final path = _currentAudioPaths[contentId];
    if (path == null || path.isEmpty) {
      print("🔈 GlobalAudioPlayer: No path found for content $contentId");
      _showErrorSnackbar(context, "No audio available");
      return;
    }
    
    print("🔈 GlobalAudioPlayer: Attempting to play audio from $path");
    
    // First check if file exists
    try {
      final file = File(path);
      if (!await file.exists()) {
        print("🔈 GlobalAudioPlayer: File doesn't exist: $path");
        _showErrorSnackbar(context, "Audio file not found");
        return;
      }
      
      final fileSize = await file.length();
      print("🔈 GlobalAudioPlayer: File size: $fileSize bytes");
      
      if (fileSize < 100) {
        print("🔈 GlobalAudioPlayer: File too small: $fileSize bytes");
        _showErrorSnackbar(context, "Audio file appears to be corrupted");
        return;
      }
    } catch (e) {
      print("🔈 GlobalAudioPlayer: Error checking file: $e");
      _showErrorSnackbar(context, "Error accessing audio file");
      return;
    }
    
    // Use AudioPlayerService for playback
    final success = await AudioPlayerService.playAudio(path, onComplete: () {
      print("🔈 GlobalAudioPlayer: Playback finished");
      _isPlaying = false;
    });
    
    if (success) {
      print("🔈 GlobalAudioPlayer: Audio started playing successfully");
      _isPlaying = true;
    } else {
      print("🔈 GlobalAudioPlayer: Failed to play with AudioPlayerService, trying AudioRecordBloc");
      _tryPlayWithBloc(path, context);
    }
  }
  
  static void _tryPlayWithBloc(String path, BuildContext context) {
    try {
      if (_audioBloc == null) {
        try {
          _audioBloc = BlocProvider.of<AudioRecordBloc>(context);
          print("🔈 GlobalAudioPlayer: Got AudioRecordBloc from context");
        } catch (e) {
          print("🔈 GlobalAudioPlayer: Error getting bloc from context: $e");
          _showErrorSnackbar(context, "Error playing audio");
          return;
        }
      }
      
      if (_audioBloc != null) {
        // _audioBloc!.add(PlayLocalFile(path)); // Commented out due to missing definition/event
        print("🔈 GlobalAudioPlayer: Playing with AudioRecordBloc -- (Note: actual playback dispatch is commented out)");
        _isPlaying = true;
        // print("🔈 GlobalAudioPlayer: Playing with AudioRecordBloc");
      } else {
        _showErrorSnackbar(context, "Error playing audio");
      }
    } catch (e) {
      print("🔈 GlobalAudioPlayer: Error in _tryPlayWithBloc: $e");
      _showErrorSnackbar(context, "Error playing audio");
    }
  }
  
  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  static void dispose() {
    AudioPlayerService.dispose();
  }
}