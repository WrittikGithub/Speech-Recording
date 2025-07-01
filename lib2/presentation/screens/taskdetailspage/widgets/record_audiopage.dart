// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:sdcp_rebuild/presentation/blocs/audio_record_bloc/audio_record_bloc.dart';

// // class AudioRecorderWidget extends StatelessWidget {
// //   final String contentId;
// //   final Function(String) onSubmit;

// //   const AudioRecorderWidget({
// //     super.key,
// //     required this.contentId,
// //     required this.onSubmit,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocBuilder<AudioRecordBloc, AudioRecordState>(
// //       builder: (context, state) {
// //         return Container(
// //           padding: const EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             borderRadius: BorderRadius.circular(5),
// //             border: Border.all(color: Colors.grey),
// //           ),
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //             children: [
// //               _buildRecordingControls(context, state),
// //               if (state is AudioRecordingStopped) ...[
// //                 IconButton(
// //                   icon: const Icon(Icons.play_arrow),
// //                   onPressed: () =>
// //                       context.read<AudioRecordBloc>().add(PlayRecording()),
// //                 ),
// //                 ElevatedButton(
// //                   onPressed: () => onSubmit(state.path),
// //                   child: const Text('Submit'),
// //                 ),
// //               ],
// //               if (state is! AudioRecordInitial)
// //                 IconButton(
// //                   icon: const Icon(Icons.refresh),
// //                   onPressed: () =>
// //                       context.read<AudioRecordBloc>().add(ResetRecording()),
// //                 ),
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildRecordingControls(
// //       BuildContext context, AudioRecordState state) {
// //     if (state is AudioRecording) {
// //       return Row(
// //         children: [
// //           IconButton(
// //             icon: const Icon(Icons.pause),
// //             onPressed: () =>
// //                 context.read<AudioRecordBloc>().add(PauseRecording()),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.stop),
// //             onPressed: () =>
// //                 context.read<AudioRecordBloc>().add(StopRecording()),
// //           ),
// //         ],
// //       );
// //     } else if (state is AudioRecordingPaused) {
// //       return Row(
// //         children: [
// //           IconButton(
// //             icon: const Icon(Icons.mic),
// //             onPressed: () =>
// //                 context.read<AudioRecordBloc>().add(ResumeRecording()),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.stop),
// //             onPressed: () =>
// //                 context.read<AudioRecordBloc>().add(StopRecording()),
// //           ),
// //         ],
// //       );
// //     } else if (state is AudioPlaying) {
// //       return IconButton(
// //         icon: const Icon(Icons.pause),
// //         onPressed: () => context.read<AudioRecordBloc>().add(PausePlayback()),
// //       );
// //     } else if (state is AudioPlayingPaused) {
// //       return IconButton(
// //         icon: const Icon(Icons.play_arrow),
// //         onPressed: () => context.read<AudioRecordBloc>().add(PlayRecording()),
// //       );
// //     }

// //     return IconButton(
// //       icon: const Icon(Icons.mic),
// //       onPressed: () => context.read<AudioRecordBloc>().add(StartRecording()),
// //     );
// //   }
// // }

import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/presentation/blocs/audio_record_bloc/audio_record_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_task_bloc/save_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;
class AudioRecorderWidget extends StatelessWidget {
  final Function(String) onSubmit;
  final String tasktargetId;
  final String contentId;
  const AudioRecorderWidget({
    super.key,
    required this.onSubmit,
    required this.tasktargetId,
    required this.contentId,
  });
Future<void> _updateContentInDatabase(String audioPath) async {
  try {
    final dbHelper = ContentDatabaseHelper();
    
    // Move recording to permanent storage
    final permanentPath = await dbHelper.moveRecordingToPermanentStorage(audioPath);
    
    // Update database with new path
    final Database db = await dbHelper.database;
    await db.update(
      'contents',
      {
        'targetContentPath': permanentPath,
        'targetDigitizationStatus': 'SAVED'
      },
      where: 'contentId = ? AND taskTargetId = ?',
      whereArgs: [contentId, tasktargetId],
    );
    
    print('Updated database with new audio path: $permanentPath');
  } catch (e) {
    print('Error updating database: $e');
  }
}

  @override
  Widget build(BuildContext context) {
   // String? submittedAudioPath;
    return MultiBlocListener(
      listeners: [
        // Listener for SaveTaskBloc to show snackbars
        BlocListener<SaveTaskBloc, SaveTaskState>(
          listener: (context, state) {
            if (state is SaveTaskSuccessState) {
              // if (submittedAudioPath != null) {
              //   _updateContentInDatabase(submittedAudioPath!);
              // }

              CustomSnackBar.show(
                  context: context,
                  title: 'Success....',
                  message: state.message,
                  contentType: ContentType.success);
              // Reset the audio recording
              context.read<AudioRecordBloc>().add(ResetRecording());
              context.read<ContentTaskTargetIdBloc>().add(
                  ContentTaskInitialFetchingEvent(
                      contentTaskTargetId: tasktargetId));
            } else if (state is SaveTaskErrorState) {
              CustomSnackBar.show(
                  context: context,
                  title: 'Error',
                  message: state.message,
                  contentType: ContentType.failure);
            }
          },
        ),
      ],
      child: BlocBuilder<AudioRecordBloc, AudioRecordState>(
        builder: (context, audioState) {
          return BlocBuilder<SaveTaskBloc, SaveTaskState>(
            builder: (context, saveTaskState) {
              return Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Appcolors.kgreenColor, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRecordingControls(context, audioState),
                    // Persist play and submit buttons after stopping recording
                    if (audioState is AudioRecordingStopped ||
                        audioState is AudioPlaying ||
                        audioState is AudioPlayingPaused) ...[
                      // Single button for play/pause during playback
                      IconButton(
                        icon: Icon(
                          audioState is AudioPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: audioState is AudioPlaying
                              ? Colors.red
                              : Appcolors.kgreenColor,
                          size: 35,
                        ),
                        onPressed: () => context.read<AudioRecordBloc>().add(
                            audioState is AudioPlaying
                                ? PausePlayback()
                                : PlayRecording()),
                      ),
                      // Submit button with loading state
                      saveTaskState is SaveTaskLoadingState
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadiusStyles.kradius20(),
                                  ),
                                  backgroundColor: Appcolors.kgreenColor),
                              onPressed: () {},
                              child: Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                    color: Appcolors.kwhiteColor, size: 30),
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusStyles.kradius20(),
                                ),
                                backgroundColor: Appcolors.kgreenColor,
                              ),
                              onPressed: () async {
                                // Convert audio to base64 before submitting
                                if (audioState is AudioRecordingStopped ||
                                    audioState is AudioPlaying ||
                                    audioState is AudioPlayingPaused) {
                                  try {
                                    String? recordingPath;
                                    if (audioState is AudioRecordingStopped) {
                                      recordingPath = (audioState).path;
                                    } else if (audioState is AudioPlaying) {
                                      recordingPath = (audioState).path;
                                    } else if (audioState
                                        is AudioPlayingPaused) {
                                      recordingPath = (audioState).path;
                                    }

                                    if (recordingPath != null) {
                                      // submittedAudioPath = recordingPath;
                                      // String base64Audio =
                                      //     await AudioUploadHelper
                                      //         .convertAudioToBase64(
                                      //             recordingPath);
                                       final result = await AudioUploadHelper.storeAudioFormats(recordingPath);
                                               await _updateContentInDatabase(recordingPath);
                                      onSubmit(result.base64String);
                                    }
                                    // String base64Audio = await AudioUploadHelper
                                    //     .convertAudioToBase64(audioState.path);

                                    // // Optional: Check file size before uploading
                                    // int fileSize = await AudioUploadHelper
                                    //     .getAudioFileSize(audioState.path);
                                    // print('Audio file size: $fileSize bytes');

                                    // // Call your submit function with base64 encoded audio
                                    // onSubmit(base64Audio);
                                  } catch (e) {
                                    // Handle conversion error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to process audio: $e'),
                                        backgroundColor: Appcolors.kredColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: TextStyles.body(
                                text: 'Submit',
                                weight: FontWeight.bold,
                                color: Appcolors.kwhiteColor,
                              ),
                            ),
                    ],
                    // Reset button always visible when not in initial state
                    if (audioState is! AudioRecordInitial)
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.blue,
                        ),
                        onPressed: () => context
                            .read<AudioRecordBloc>()
                            .add(ResetRecording()),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordingControls(BuildContext context, AudioRecordState state) {
    if (state is AudioRecording) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () =>
                context.read<AudioRecordBloc>().add(PauseRecording()),
          ),
          IconButton(
            icon: const Icon(
              Icons.stop,
              color: Appcolors.kredColor,
            ),
            onPressed: () =>
                context.read<AudioRecordBloc>().add(StopRecording()),
          ),
        ],
      );
    } else if (state is AudioRecordingPaused) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.mic,
              color: Appcolors.kredColor,
            ),
            onPressed: () =>
                context.read<AudioRecordBloc>().add(ResumeRecording()),
          ),
          IconButton(
            icon: const Icon(
              Icons.stop,
              color: Appcolors.kredColor,
            ),
            onPressed: () =>
                context.read<AudioRecordBloc>().add(StopRecording()),
          ),
        ],
      );
    } else if (state is AudioRecordInitial) {
      return IconButton(
        icon: const Icon(
          Icons.mic,
          color: Appcolors.kredColor,
          size: 35,
        ),
        onPressed: () => context.read<AudioRecordBloc>().add(StartRecording()),
      );
    }

    // Return empty widget for other states
    return const SizedBox.shrink();
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
  /// Stores both WAV and base64 versions of the audio
  static Future<AudioStorageResult> storeAudioFormats(String wavFilePath) async {
    try {
      // Get application documents directory for storing base64
      final directory = await getApplicationDocumentsDirectory();
      
      // Create base64 filename from WAV filename but with different extension
      final wavFileName = Path.basename(wavFilePath);
      final base64FileName = wavFileName.replaceAll('.wav', '.b64');
      final base64FilePath = '${directory.path}/base64_audio/$base64FileName';

      // Ensure directory exists
      final base64Dir = Directory('${directory.path}/base64_audio');
      if (!await base64Dir.exists()) {
        await base64Dir.create(recursive: true);
      }

      // Convert to base64
      File wavFile = File(wavFilePath);
      if (!await wavFile.exists()) {
        throw Exception('WAV file does not exist at path: $wavFilePath');
      }
      
      List<int> audioBytes = await wavFile.readAsBytes();
      String base64Audio = base64Encode(audioBytes);

      // Store base64 in separate file
      final base64File = File(base64FilePath);
      await base64File.writeAsString(base64Audio);

      return AudioStorageResult(
        wavPath: wavFilePath,
        base64Path: base64FilePath,
        base64String: base64Audio,
      );
    } catch (e) {
      print('Error storing audio formats: $e');
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