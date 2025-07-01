import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/core/constants.dart';
import 'package:sdcp_rebuild/core/responsive_utils.dart';
import 'package:sdcp_rebuild/core/urls.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sdcp_rebuild/presentation/blocs/content_taskTargetId_bloc/content_task_target_id_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/submit_task_bloc/submit_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/blocs/save_task_bloc/save_task_bloc.dart';
import 'package:sdcp_rebuild/presentation/screens/taskdetailspage/taskpage.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_navigator.dart';
import 'package:sdcp_rebuild/presentation/widgets/custom_snakebar.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/presentation/screens/taskdetailspage/widgets/record_audiopage.dart';
import 'package:sdcp_rebuild/presentation/widgets/simple_audio_player.dart';

class ScreenTaskListPage extends StatefulWidget {
  final String taskTargetID;
  final String taskTitle;
  const ScreenTaskListPage(
      {super.key, required this.taskTargetID, required this.taskTitle});

  @override
  State<ScreenTaskListPage> createState() => _ScreenTaskListPageState();
}

class _ScreenTaskListPageState extends State<ScreenTaskListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isSyncingAll = false;
  double? _lastKnownScrollPositionBeforeSingleSync;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        actions: [
          // Sync All button - only show when we have local content to sync
          BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
            builder: (context, state) {
              if (state is ContentTaskTargetSuccessState) {
                // Check if there are any SAVED_LOCALLY content
                final hasSavedLocallyContent = state.contentlist.any(
                  (content) => content.targetDigitizationStatus == "SAVED_LOCALLY"
                );
                
                if (hasSavedLocallyContent) {
                  return _isSyncingAll 
                    ? Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(12),
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Appcolors.kpurplelightColor,
                          size: 24,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.sync),
                        tooltip: 'Sync All Recordings',
                        onPressed: () => _syncAllRecordings(context, state.contentlist),
                      );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: 0.0,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
                Appcolors.kpurplelightColor),
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<SaveTaskBloc, SaveTaskState>(
            listener: (context, state) {
              if (state is SaveTaskSuccessState) {
                print("✅ [TasklistPage] SaveTaskSuccess, refreshing content list");
                if (!_isSyncingAll) {
                  context.read<ContentTaskTargetIdBloc>().add(
                    ContentTaskTargetIdLoadingEvent(
                      contentTaskTargetId: widget.taskTargetID
                    )
                  );
                }
              } else if (state is SaveTaskRefreshNeededState) {
                print("🔄 [TasklistPage] SaveTaskRefreshNeeded, reloading content list");
                if (!_isSyncingAll) {
                  context.read<ContentTaskTargetIdBloc>().add(
                    ContentTaskTargetIdLoadingEvent(
                      contentTaskTargetId: widget.taskTargetID
                    )
                  );
                }
              } else if (state is SaveTaskErrorState) {
                print("❌ [TasklistPage] SaveTaskError received: ${state.message}");
                CustomSnackBar.show(
                  context: context,
                  title: 'Upload Failed',
                  message: state.message,
                  contentType: ContentType.failure
                );
              } else if (state is SaveTaskLoadingState) {
                print("🔄 [TasklistPage] SaveTaskLoading received");
              }
            },
          ),
          BlocListener<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
            listener: (context, state) {
              if (state is ContentTaskTargetSuccessState) {
                print("🔍 [TasklistPage] ContentTaskTargetSuccessState received with ${state.contentlist.length} items");
                
                _downloadAudioForContentList(state.contentlist);

                if (_lastKnownScrollPositionBeforeSingleSync != null && _scrollController.hasClients) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_lastKnownScrollPositionBeforeSingleSync!);
                      _lastKnownScrollPositionBeforeSingleSync = null; // Reset directly without setState
                    }
                  });
                }
              }
            },
          ),
        ],
        child: BlocBuilder<ContentTaskTargetIdBloc, ContentTaskTargetIdState>(
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
                      key: const PageStorageKey<String>('taskListListView'),
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.wp(4),
                        vertical: ResponsiveUtils.wp(4),
                      ),
                      itemCount: state.contentlist.length,
                      itemBuilder: (context, index) {
                        final content = state.contentlist[index];
                        IconData statusIcon;
                        Color iconColor;

                        switch (content.targetDigitizationStatus) {
                          case "SAVED_LOCALLY":
                            statusIcon = Icons.cloud_upload_outlined;
                            iconColor = Colors.amber;
                            break;
                          case "SAVED_ON_SERVER":
                          case "SAVED":
                            statusIcon = Icons.cloud_done;
                            iconColor = Colors.green;
                            break;
                          default:
                            statusIcon = Icons.cloud_off_outlined;
                            iconColor = Colors.grey;
                        }

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
                                  Row(
                                    children: [
                                      Icon(statusIcon, color: iconColor, size: 20),
                                      const SizedBox(width: 8),
                                      TextStyles.body(
                                        text: 'SL:${index + 1}',
                                        color: Appcolors.kblackColor,
                                        weight: FontWeight.bold,
                                      ),
                                      if (MinimumRecordingTimeUtils.hasMinimumTime(content.promptSpeechTime))
                                        MinimumRecordingTimeUtils.buildMinimumTimeWidget(content.promptSpeechTime) ?? const SizedBox.shrink(),
                                      const Spacer(),
                                      // Only show sync button for SAVED_LOCALLY status
                                      if (content.targetDigitizationStatus == "SAVED_LOCALLY")
                                        IconButton(
                                          icon: const Icon(Icons.sync, size: 18),
                                          onPressed: () async {
                                            // Store current scroll position in the state variable
                                            if (mounted) {
                                              setState(() {
                                                _lastKnownScrollPositionBeforeSingleSync = _scrollController.position.pixels;
                                              });
                                            }
                                            
                                            var connectivityResult = await (Connectivity().checkConnectivity());
                                            bool isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
                                                            connectivityResult.contains(ConnectivityResult.wifi);

                                            if (!isOnline) {
                                              CustomSnackBar.show(
                                                context: context,
                                                title: 'Offline',
                                                message: 'Cannot sync. Please check your internet connection.',
                                                contentType: ContentType.warning
                                              );
                                              return;
                                            }
                                            
                                            if (!context.mounted) return;

                                            // Check if the local path exists (either from model or database)
                                            final dbHelper = ContentDatabaseHelper();
                                            final paths = await dbHelper.getAudioPathsForContent(content.contentId);
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
                                              contentId: content.contentId,
                                              targetContent: base64String,
                                              isForceOnline: true,
                                              taskTargetId: widget.taskTargetID,
                                            );

                                            if (!context.mounted) return;
                                            // CustomSnackBar.show(
                                            //   context: context,
                                            //   title: 'Syncing...',
                                            //   message: 'Uploading content ${content.contentId} to server.',
                                            //   contentType: ContentType.help
                                            // );

                                            context.read<SaveTaskBloc>().add(
                                              SaveTaskButtonclickingEvent(saveData: saveData)
                                            );

                                            // Update the database status optimistically
                                            await dbHelper.updateContentStatus(
                                              contentId: content.contentId,
                                              status: "SAVED_ON_SERVER"
                                            );

                                            // DO NOT Refresh the UI here directly.
                                            // The SaveTaskBloc listener will trigger the ContentTaskTargetIdBloc to refresh.
                                            // The ContentTaskTargetIdBloc listener will then handle scroll restoration.
                                          },
                                        ),
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
                                      content.targetDigitizationStatus == "SAVED_ON_SERVER" || content.targetDigitizationStatus == "SAVED"
                                      ? content.targetContentPath.isNotEmpty
                                        ? SimpleAudioPlayer(
                                            audioPath: content.targetContentPath,
                                            size: ResponsiveUtils.wp(9),
                                            backgroundColor: Appcolors.kpurpleColor,
                                            iconColor: Colors.white,
                                          )
                                        : GestureDetector(
                                            onTap: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("No audio file available"))
                                              );
                                            },
                                            child: Container(
                                              width: ResponsiveUtils.wp(9),
                                              height: ResponsiveUtils.wp(9),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Appcolors.kgreyColor,
                                              ),
                                              child: Icon(
                                                Icons.volume_off,
                                                color: Colors.white,
                                                size: ResponsiveUtils.wp(5),
                                              ),
                                            ),
                                          )
                                      : Container(
                                        width: ResponsiveUtils.wp(9),
                                        height: ResponsiveUtils.wp(9),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Appcolors.kgreyColor,
                                        ),
                                        child: const Icon(
                                          Icons.mic_none,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadiusStyles.kradius5(),
                                            color: content.targetDigitizationStatus == "SAVED_LOCALLY" 
                                                      ? Colors.amber
                                                      : content.targetDigitizationStatus == "SAVED_ON_SERVER" || content.targetDigitizationStatus == "SAVED"
                                                          ? Appcolors.kgreenColor
                                                          : Appcolors.korangeColor),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: ResponsiveUtils.wp(2.5),
                                              vertical: ResponsiveUtils.wp(1.5)),
                                          child: TextStyles.caption(
                                              text: content.targetDigitizationStatus == "SAVED_LOCALLY"
                                                    ? "Local"
                                                    : content.targetDigitizationStatus == "SAVED_ON_SERVER" || content.targetDigitizationStatus == "SAVED"
                                                        ? "SAVED"
                                                        : "Record",
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
                heroTag: "submitButton",
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
  
  Future<void> _downloadAudioForContentList(List<dynamic> contentList) async {
    print("🔄 [TasklistPage] Starting audio download for ${contentList.length} items");
    
    final dbHelper = ContentDatabaseHelper();
    final String audioDir = await dbHelper.getAudioDirectory();
    
    final directory = Directory(audioDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    for (final content in contentList) {
      try {
        if (content.targetDigitizationStatus != "SAVED" || 
            content.targetContentUrl == null || 
            content.targetContentUrl.isEmpty) {
          continue;
        }
        
        final contentId = content.contentId;
        String serverUrl = content.targetContentUrl;
        
        if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
          if (serverUrl.startsWith('/')) {
            serverUrl = '${Endpoints.recordURL}$serverUrl';
          } else {
            serverUrl = '${Endpoints.recordURL}/$serverUrl';
          }
        }
        
        print("🔄 [TasklistPage] Processing audio for $contentId with URL: $serverUrl");
        
        final existingPaths = await dbHelper.getAudioPathsForContent(contentId);
        final existingLocalPath = existingPaths?['localPath'];
        
        if (existingLocalPath != null && existingLocalPath.isNotEmpty) {
          final existingFile = File(existingLocalPath);
          if (await existingFile.exists() && await existingFile.length() > 0) {
            print("✅ [TasklistPage] Already have local file for $contentId at: $existingLocalPath");
            
            SharedAudioPathProvider.setAudioPaths(contentId, existingLocalPath, serverUrl);
            
            GlobalAudioPlayer.setCurrentAudio(contentId, existingLocalPath);
            continue;
          } else {
            print("⚠️ [TasklistPage] Local file reference exists but file is missing: $existingLocalPath");
          }
        }
        
        print("🔄 [TasklistPage] Downloading audio for $contentId from $serverUrl");
        
        try {
          final http.Client client = http.Client();
          final response = await client.get(Uri.parse(serverUrl));
          
          if (response.statusCode == 200) {
            final contentType = response.headers['content-type'] ?? '';
            final contentLength = int.tryParse(response.headers['content-length'] ?? '0') ?? 0;
            
            print("🔄 [TasklistPage] Server response: ContentType=$contentType, Length=$contentLength");
            
            if (!contentType.contains('audio') && !contentType.contains('octet-stream') && contentLength < 1000) {
              print("⚠️ [TasklistPage] Response may not be an audio file, checking for JSON");
              
              if (contentType.contains('json') || response.body.startsWith('{')) {
                try {
                  final jsonData = jsonDecode(response.body);
                  print("🔄 [TasklistPage] JSON response received: $jsonData");
                  
                  final possibleUrls = [
                    jsonData['fileUrl'],
                    jsonData['audioUrl'],
                    jsonData['url'],
                    jsonData['serverUrl'],
                    if (jsonData['data'] is Map) jsonData['data']['fileUrl'],
                    if (jsonData['data'] is Map) jsonData['data']['audioUrl'],
                    if (jsonData['data'] is Map) jsonData['data']['url'],
                    if (jsonData['data'] is Map) jsonData['data']['serverUrl'],
                  ];
                  
                  final actualUrl = possibleUrls.firstWhere(
                    (url) => url != null && url.toString().isNotEmpty,
                    orElse: () => null
                  );
                  
                  if (actualUrl != null) {
                    print("🔄 [TasklistPage] Found actual URL in JSON: $actualUrl");
                    
                    String newUrl = actualUrl.toString();
                    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
                      if (newUrl.startsWith('/')) {
                        newUrl = '${Endpoints.recordURL}$newUrl';
                      } else {
                        newUrl = '${Endpoints.recordURL}/$newUrl';
                      }
                    }
                    
                    print("🔄 [TasklistPage] Retrying download with new URL: $newUrl");
                    
                    final newResponse = await client.get(Uri.parse(newUrl));
                    if (newResponse.statusCode == 200) {
                      await _saveAudioFile(newResponse, contentId, audioDir, newUrl, dbHelper);
                    } else {
                      print("❌ [TasklistPage] Failed to download audio with new URL: HTTP ${newResponse.statusCode}");
                    }
                    continue;
                  }
                } catch (e) {
                  print("❌ [TasklistPage] Error parsing JSON response: $e");
                }
              }
            }
            
            await _saveAudioFile(response, contentId, audioDir, serverUrl, dbHelper);
          } else {
            print("❌ [TasklistPage] Failed to download audio for $contentId: HTTP ${response.statusCode}");
          }
        } catch (e) {
          print("❌ [TasklistPage] Error downloading audio for $contentId: $e");
        }
      } catch (e) {
        print("❌ [TasklistPage] Error processing content: $e");
      }
    }
    
    print("✅ [TasklistPage] Completed audio download process");
  }
  
  Future<void> _saveAudioFile(http.Response response, String contentId, String audioDir, String serverUrl, ContentDatabaseHelper dbHelper) async {
    try {
      final String fileName = 'audio_${contentId}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final String filePath = '$audioDir/$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      if (await file.exists() && await file.length() > 0) {
        print("✅ [TasklistPage] Downloaded audio to: $filePath with size ${await file.length()} bytes");
        
        await dbHelper.updateContent(
          contentId: contentId,
          audioPath: filePath,
          base64Audio: '',
          serverUrl: serverUrl,
        );
        
        SharedAudioPathProvider.setAudioPaths(contentId, filePath, serverUrl);
        
        GlobalAudioPlayer.setCurrentAudio(contentId, filePath);
        
        print("✅ [TasklistPage] Updated all references for contentId: $contentId");
      } else {
        print("❌ [TasklistPage] File was created but is empty or missing: $filePath");
      }
    } catch (e) {
      print("❌ [TasklistPage] Error saving audio file: $e");
    }
  }

  Future<void> _syncAllRecordings(BuildContext context, List<dynamic> contentList) async {
    if (_isSyncingAll) return;

    // Store current scroll position
    final currentScrollPosition = _scrollController.position.pixels;
    
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
                    connectivityResult.contains(ConnectivityResult.wifi);

    if (!isOnline) {
      CustomSnackBar.show(
        context: context,
        title: 'Offline',
        message: 'Cannot sync. Please check your internet connection.',
        contentType: ContentType.warning
      );
      return;
    }

    final dbHelper = ContentDatabaseHelper();
    
    // Filter for locally saved content
    final localContent = contentList.where(
      (content) => content.targetDigitizationStatus == "SAVED_LOCALLY"
    ).toList();

    if (localContent.isEmpty) {
      CustomSnackBar.show(
        context: context,
        title: 'Info',
        message: 'No local recordings to sync',
        contentType: ContentType.help
      );
      return;
    }

    setState(() => _isSyncingAll = true);

    try {
      CustomSnackBar.show(
        context: context,
        title: 'Syncing...',
        message: 'Uploading ${localContent.length} recordings to server.',
        contentType: ContentType.help
      );

      int successCount = 0;
      int failCount = 0;

      for (var content in localContent) {
        if (!context.mounted) break;
        
        try {
          final paths = await dbHelper.getAudioPathsForContent(content.contentId);
          final localPath = paths?['localPath'];

          if (localPath == null || localPath.isEmpty) {
            failCount++;
            continue;
          }

          final file = File(localPath);
          if (!await file.exists()) {
            failCount++;
            continue;
          }

          final fileBytes = await file.readAsBytes();
          final base64String = base64Encode(fileBytes);

          final saveData = SubmitTaskModel(
            contentId: content.contentId,
            targetContent: base64String,
            isForceOnline: true,
            taskTargetId: widget.taskTargetID,
          );

          if (!context.mounted) break;
          
          // Create a completer to wait for the SaveTaskBloc response
          final completer = Completer<bool>();
          
          late StreamSubscription subscription;
          subscription = context.read<SaveTaskBloc>().stream.listen((state) {
            if (state is SaveTaskSuccessState && !completer.isCompleted) {
              completer.complete(true);
            } else if (state is SaveTaskErrorState && !completer.isCompleted) {
              completer.complete(false);
            }
          });

          context.read<SaveTaskBloc>().add(
            SaveTaskButtonclickingEvent(saveData: saveData)
          );

          final success = await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () => false,
          );

          subscription.cancel();

          if (success) {
            successCount++;
            await dbHelper.updateContentStatus(
              contentId: content.contentId,
              status: "SAVED_ON_SERVER"
            );
          } else {
            failCount++;
          }
        } catch (e) {
          print("Error syncing content ${content.contentId}: $e");
          failCount++;
        }
      }

      if (!context.mounted) return;

      // Only refresh the UI once after all syncs are complete
      context.read<ContentTaskTargetIdBloc>().add(
        ContentTaskTargetIdLoadingEvent(
          contentTaskTargetId: widget.taskTargetID
        )
      );
      
      // Show final status
      CustomSnackBar.show(
        context: context,
        title: successCount > 0 ? 'Sync Complete' : 'Sync Failed',
        message: 'Successfully synced $successCount recordings' + 
                (failCount > 0 ? ', failed to sync $failCount' : ''),
        contentType: successCount > 0 ? ContentType.success : ContentType.failure
      );

      // Restore scroll position after the list updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(currentScrollPosition);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isSyncingAll = false);
      }
    }
  }
}
