import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:sdcp_rebuild/presentation/blocs/audio_record_bloc/audio_record_bloc.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/core/endpoints.dart';
import 'package:sdcp_rebuild/core/colors.dart';
import 'package:sdcp_rebuild/presentation/screens/taskdetailspage/widgets/record_audiopage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';

// Add these enum and class definitions after imports
enum PlayerState {
  playing,
  paused,
  stopped
}

class AudioManager {
  String? _currentlyPlaying;
  final List<Function> _listeners = [];
  
  void setCurrentlyPlaying(String? contentId) {
    _currentlyPlaying = contentId;
    _notifyListeners();
  }
  
  String? getCurrentlyPlaying() {
    return _currentlyPlaying;
  }
  
  void addListener(Function callback) {
    _listeners.add(callback);
  }
  
  void removeListener(Function callback) {
    _listeners.remove(callback);
  }
  
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

class UnifiedAudioPlayerButton extends StatefulWidget {
  final String contentId;
  final String? audioUrl;
  final String? localPath;
  final double size;
  final bool forceBlueButton;
  final bool isSaved;

  const UnifiedAudioPlayerButton({
    super.key,
    required this.contentId,
    this.audioUrl,
    this.localPath,
    this.size = 40,
    this.forceBlueButton = false,
    this.isSaved = false,
  });

  @override
  State<UnifiedAudioPlayerButton> createState() => _UnifiedAudioPlayerButtonState();
}

class _UnifiedAudioPlayerButtonState extends State<UnifiedAudioPlayerButton> {
  bool _isPlaying = false;
  String? _localPath;
  String? _serverUrl;
  bool _isLoadingAudio = false;
  bool _hasError = false;
  final bool _isDisposed = false;
  PlayerState _playerState = PlayerState.stopped;
  String? _effectiveAudioUrl;
  final AudioManager _audioManager = AudioManager();
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    print("🔊 [UnifiedAudioPlayerButton] INIT: contentId=${widget.contentId}, isSaved=${widget.isSaved}");
    
    // Initialize audio paths when the widget is created
    _fetchAudioPaths();
  }
  
  // Add a method to fetch audio paths from database
  Future<void> _fetchAudioPaths() async {
    if (!widget.isSaved) return;
    
    try {
      setState(() {
        _isLoadingAudio = true;
      });
      
      // CRITICAL FIX: FIRST always check GlobalAudioPlayer since it has the most recent recording
      final globalPath = GlobalAudioPlayer.getAudioPath(widget.contentId);
      if (globalPath != null && globalPath.isNotEmpty) {
        // Verify the file exists
        final globalFile = File(globalPath);
        if (await globalFile.exists()) {
          print("🔊 [UnifiedAudioPlayerButton] Found path in GlobalAudioPlayer for ${widget.contentId}");
          
          setState(() {
            _localPath = globalPath;
            // Server URL might be null, which is fine for local playback
            _serverUrl = null;
            _isLoadingAudio = false;
            
            print("🔊 [UnifiedAudioPlayerButton] PATHS FROM GLOBAL: contentId=${widget.contentId}");
            print("🔊 Local path: $_localPath");
          });
          return; // Use the global path immediately
        } else {
          print("🔊 [UnifiedAudioPlayerButton] File in GlobalAudioPlayer does not exist: $globalPath");
        }
      }
      
      // Then check if there's a path in the SharedAudioPathProvider (which has the most recent recording)
      final sharedPaths = SharedAudioPathProvider.getAudioPaths(widget.contentId);
      if (sharedPaths != null && sharedPaths['localPath']?.isNotEmpty == true) {
        print("🔊 [UnifiedAudioPlayerButton] Found path in SharedAudioPathProvider for ${widget.contentId}");
        
        // Verify the file exists
        final localFile = File(sharedPaths['localPath']!);
        if (await localFile.exists() && await localFile.length() > 0) {
          print("🔊 [UnifiedAudioPlayerButton] File exists at ${sharedPaths['localPath']}, size: ${await localFile.length()} bytes");
          
          setState(() {
            _localPath = sharedPaths['localPath'];
            _serverUrl = sharedPaths['serverUrl'];
            _isLoadingAudio = false;
            
            print("🔊 [UnifiedAudioPlayerButton] PATHS FROM SHARED: contentId=${widget.contentId}");
            print("🔊 Local path: $_localPath, Server URL: $_serverUrl");
            
            // CRITICAL: Update GlobalAudioPlayer with this path to ensure consistency
            GlobalAudioPlayer.setCurrentAudio(widget.contentId, _localPath!);
          });
          return; // Use the shared path if available
        } else {
          print("🔊 [UnifiedAudioPlayerButton] File in SharedAudioPathProvider does not exist: ${sharedPaths['localPath']}");
          // Continue checking other sources
        }
      }
      
      // Use localPath from props if provided
      if (widget.localPath != null && widget.localPath!.isNotEmpty) {
        // Verify the file exists
        final localFile = File(widget.localPath!);
        if (await localFile.exists() && await localFile.length() > 0) {
          print("🔊 [UnifiedAudioPlayerButton] File exists from props at ${widget.localPath}, using it directly");
          
          setState(() {
            _localPath = widget.localPath;
            _serverUrl = widget.audioUrl;
            _isLoadingAudio = false;
            
            // Update SharedAudioPathProvider and GlobalAudioPlayer
            SharedAudioPathProvider.setAudioPaths(widget.contentId, _localPath!, _serverUrl);
            GlobalAudioPlayer.setCurrentAudio(widget.contentId, _localPath!);
            
            print("🔊 [UnifiedAudioPlayerButton] PATHS FROM PROPS: contentId=${widget.contentId}");
            print("🔊 Local path: $_localPath, Server URL: $_serverUrl");
          });
          return;
        }
      }
      
      // If no valid sources found above, check the database
      final dbHelper = ContentDatabaseHelper();
      final paths = await dbHelper.getAudioPathsForContent(widget.contentId);
      
      if (paths != null && paths['localPath']?.isNotEmpty == true) {
        // Verify the file exists
        final localFile = File(paths['localPath']!);
        if (await localFile.exists() && await localFile.length() > 0) {
          print("🔊 [UnifiedAudioPlayerButton] File exists in DB at ${paths['localPath']}, size: ${await localFile.length()} bytes");
          
          setState(() {
            _localPath = paths['localPath'];
            _serverUrl = paths['serverUrl'];
            _isLoadingAudio = false;
            
            // Update the SharedAudioPathProvider and GlobalAudioPlayer
            SharedAudioPathProvider.setAudioPaths(widget.contentId, _localPath!, _serverUrl);
            GlobalAudioPlayer.setCurrentAudio(widget.contentId, _localPath!);
            
            print("🔊 [UnifiedAudioPlayerButton] PATHS LOADED FROM DB: contentId=${widget.contentId}");
            print("🔊 Local path: $_localPath, Server URL: $_serverUrl");
          });
          return;
        } else {
          print("🔊 [UnifiedAudioPlayerButton] File in DB does not exist: ${paths['localPath']}");
        }
      }
      
      // If we have a server URL from either source but no valid local file,
      // try to download the audio from the server URL
      final serverUrl = paths?['serverUrl'] ?? 
                        sharedPaths?['serverUrl'] ?? 
                        widget.audioUrl;
      
      if (serverUrl != null && serverUrl.isNotEmpty) {
        print("🔊 [UnifiedAudioPlayerButton] No valid local file found, but have server URL: $serverUrl");
        
        // Download the audio file
        final downloadedPath = await _downloadAudio(serverUrl);
        if (downloadedPath != null) {
          print("🔊 [UnifiedAudioPlayerButton] Downloaded audio to: $downloadedPath");
          
          setState(() {
            _localPath = downloadedPath;
            _serverUrl = serverUrl;
            _isLoadingAudio = false;
            
            // Update the SharedAudioPathProvider and database and GlobalAudioPlayer
            SharedAudioPathProvider.setAudioPaths(widget.contentId, _localPath!, _serverUrl);
            GlobalAudioPlayer.setCurrentAudio(widget.contentId, _localPath!);
            dbHelper.updateContent(
              contentId: widget.contentId,
              audioPath: downloadedPath,
              base64Audio: '',
              serverUrl: serverUrl
            );
          });
          return;
        }
      }
      
      // If we still don't have a valid path, use what was passed in props
      if (widget.localPath != null && widget.localPath!.isNotEmpty) {
        final propFile = File(widget.localPath!);
        if (await propFile.exists() && await propFile.length() > 0) {
          print("🔊 [UnifiedAudioPlayerButton] Using file from props: ${widget.localPath}");
          
          setState(() {
            _localPath = widget.localPath;
            _serverUrl = widget.audioUrl;
            _isLoadingAudio = false;
            
            // Update the SharedAudioPathProvider and GlobalAudioPlayer
            SharedAudioPathProvider.setAudioPaths(widget.contentId, _localPath!, _serverUrl);
            GlobalAudioPlayer.setCurrentAudio(widget.contentId, _localPath!);
          });
          return;
        }
      }
      
      // If all else fails, and we have a URL, set just the server URL
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        setState(() {
          _serverUrl = widget.audioUrl;
          _isLoadingAudio = false;
        });
      } else {
        setState(() {
          _isLoadingAudio = false;
        });
      }
    } catch (e) {
      print("🔊 [UnifiedAudioPlayerButton] Error fetching audio paths: $e");
      setState(() {
        _isLoadingAudio = false;
      });
    }
  }
  
  // Add method to download audio
  Future<String?> _downloadAudio(String serverUrl) async {
    try {
      print("🔄 [UnifiedAudioPlayerButton] Downloading audio from: $serverUrl");
      
      // Ensure the URL is properly formatted with base URL if needed
      Uri uri;
      if (serverUrl.startsWith('http://') || serverUrl.startsWith('https://')) {
        uri = Uri.parse(serverUrl);
      } else if (serverUrl.startsWith('/')) {
        // If it starts with slash but doesn't have a domain, add the base URL
        uri = Uri.parse('${Endpoints.recordURL}$serverUrl');
      } else {
        // Otherwise, assume it's a relative path and add the base URL with slash
        uri = Uri.parse('${Endpoints.recordURL}/$serverUrl');
      }
      
      print("🔄 [UnifiedAudioPlayerButton] Resolved URI: $uri");
      
      // Use http package to download the audio file
      final http.Client client = http.Client();
      final response = await client.get(uri);
      
      if (response.statusCode == 200) {
        // Check if the response is actually an audio file by checking content type or length
        final contentType = response.headers['content-type'] ?? '';
        final contentLength = int.tryParse(response.headers['content-length'] ?? '0') ?? 0;
        
        print("🔄 [UnifiedAudioPlayerButton] Response content type: $contentType, length: $contentLength");
        
        if (!contentType.contains('audio') && !contentType.contains('octet-stream') && contentLength < 1000) {
          print("⚠️ [UnifiedAudioPlayerButton] Warning: Response may not be an audio file. ContentType: $contentType, Length: $contentLength");
          
          // Check if response is JSON, which might contain the actual URL
          if (contentType.contains('json') || response.body.startsWith('{')) {
            try {
              final Map<String, dynamic> jsonData = jsonDecode(response.body);
              print("🔄 [UnifiedAudioPlayerButton] JSON response received: $jsonData");
              
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
              
              // Find the first non-null URL
              final actualUrl = possibleUrls.firstWhere(
                (url) => url != null && url.toString().isNotEmpty,
                orElse: () => null
              );
              
              if (actualUrl != null) {
                print("🔄 [UnifiedAudioPlayerButton] Found actual URL in JSON response: $actualUrl");
                return _downloadAudio(actualUrl.toString());
              }
            } catch (e) {
              print("⚠️ [UnifiedAudioPlayerButton] Error parsing JSON response: $e");
            }
          }
        }
        
        // Create a unique filename based on contentId
        final ContentDatabaseHelper dbHelper = ContentDatabaseHelper();
        final String audioDir = await dbHelper.getAudioDirectory();
        
        // Ensure the directory exists
        final directory = Directory(audioDir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        final String fileName = 'audio_${widget.contentId}_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final String filePath = '$audioDir/$fileName';
        
        // Write the file to disk
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Verify the file was created and has content
        if (await file.exists() && await file.length() > 0) {
          print("✅ [UnifiedAudioPlayerButton] Downloaded audio to: $filePath with size ${await file.length()} bytes");
          
          // Try to open the file to verify it's a valid audio file
          try {
            // Update database with the new file path
            await dbHelper.updateContent(
              contentId: widget.contentId,
              audioPath: filePath,
              base64Audio: '',
              serverUrl: serverUrl
            );
            
            print("✅ [UnifiedAudioPlayerButton] Updated database with audio path");
            return filePath;
          } catch (e) {
            print("❌ [UnifiedAudioPlayerButton] Error verifying audio file: $e");
          }
        } else {
          print("❌ [UnifiedAudioPlayerButton] File was created but is empty or missing");
          return null;
        }
      } else {
        print("❌ [UnifiedAudioPlayerButton] Failed to download audio: HTTP ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ [UnifiedAudioPlayerButton] Error downloading audio: $e");
      return null;
    }
    return null;
  }
  
  @override
  void didUpdateWidget(UnifiedAudioPlayerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Log status changes for debugging
    if (oldWidget.isSaved != widget.isSaved) {
      print("🔊 [UnifiedAudioPlayerButton] STATUS CHANGED: contentId=${widget.contentId}, oldSaved=${oldWidget.isSaved}, newSaved=${widget.isSaved}");
      
      // Fetch audio paths again when isSaved changes to true
      if (widget.isSaved) {
        _fetchAudioPaths();
      }
    }
    
    // Check if the URL or local path has changed
    if (oldWidget.audioUrl != widget.audioUrl || oldWidget.localPath != widget.localPath) {
      print("🔊 [UnifiedAudioPlayerButton] PROPS CHANGED: audioUrl or localPath updated");
      _fetchAudioPaths();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    try {
      // ALWAYS use isSaved prop as the source of truth
      final bool hasAudio = widget.isSaved;
      final buttonColor = hasAudio ? Colors.blue : Appcolors.kgreyColor;
      
      // Debug output to see what's happening with each button
      print('UnifiedAudioPlayerButton: contentId=${widget.contentId}, isSaved=${widget.isSaved}, buttonColor=$buttonColor');
      
      return BlocListener<AudioRecordBloc, AudioRecordState>(
        listener: (context, state) {
          if (!mounted) return;
          
          if (state is AudioPlaying) {
            if (state.path.contains(widget.contentId)) {
              setState(() => _isPlaying = true);
            } else {
              setState(() => _isPlaying = false);
            }
          } else if (state is AudioPlayingPaused || 
                    state is AudioRecordInitial || 
                    state is AudioRecordingStopped) {
            setState(() => _isPlaying = false);
          }
        },
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          color: buttonColor,
          child: InkWell(
            onTap: hasAudio ? () async {
              if (_isLoadingAudio) {
                // Show loading indicator or message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Loading audio file..."),
                    duration: Duration(seconds: 1),
                  )
                );
                return;
              }
              
              try {
                // Special case - check if there's a saved audio path in GlobalAudioPlayer
                final globalPath = GlobalAudioPlayer.getAudioPath(widget.contentId);
                
                if (globalPath != null && globalPath.isNotEmpty) {
                  print("🔊 Using GlobalAudioPlayer path for playback: $globalPath");
                  // Try to play using the GlobalAudioPlayer
                      GlobalAudioPlayer.playContentAudio(context, widget.contentId);
                      return;
                }
                
                if (_isDisposed) return;
                
                // Fallback to local logic if we get here
                if (_playerState == PlayerState.playing) {
                  // If already playing, stop it
                  await AudioPlayerService.stopAudio();
                  _safeSetState(() => _playerState = PlayerState.stopped);
                  _audioManager.setCurrentlyPlaying(null);
                } else {
                  if (!_isInitialized) {
                    await _initializePlayer();
                  }
                  
                  if (_effectiveAudioUrl == null) {
                    _showErrorMessage('No audio source available');
                          return;
                  }
                  
                  // Always download if it's a remote URL
                  if (_effectiveAudioUrl!.startsWith('http')) {
                    final localPath = await AudioPlayerService.downloadAndCacheAudio(_effectiveAudioUrl!);
                    if (localPath != null) {
                      _effectiveAudioUrl = localPath;
                    }
                  }
                  
                  // Register with audio manager
                  _audioManager.setCurrentlyPlaying(widget.contentId);
                  
                  // Play using AudioPlayerService
                  final success = await AudioPlayerService.playAudio(
                    _effectiveAudioUrl!, 
                    onComplete: () {
                      _safeSetState(() => _playerState = PlayerState.stopped);
                      _audioManager.setCurrentlyPlaying(null);
                    }
                  );
                  
                  if (success) {
                    _safeSetState(() => _playerState = PlayerState.playing);
                  } else {
                    _showErrorMessage('Failed to play audio');
                  }
                }
              } catch (e) {
                print('Error playing audio: $e');
                // Show error to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error playing audio: $e"),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  )
                );
              }
            } : null,
            child: _isLoadingAudio 
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Center(
            child: SizedBox(
                      width: widget.size * 0.5,
                      height: widget.size * 0.5,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : SizedBox(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: widget.size * 0.6,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error building UnifiedAudioPlayerButton: $e');
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
        child: Center(
          child: Icon(
            Icons.error,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    try {
      if (_isPlaying) {
        context.read<AudioRecordBloc>().add(PausePlayback());
      }
    } catch (e) {
      print('Error stopping audio on dispose: $e');
    }
    super.dispose();
  }

  void _safeSetState(Function fn) {
    if (mounted && !_isDisposed) {
      setState(() {
        fn();
      });
    }
  }
  
  Future<void> _initializePlayer() async {
    try {
      // Check if we already have audio paths cached in global audio player
      final globalPath = GlobalAudioPlayer.getAudioPath(widget.contentId);
      if (globalPath != null && globalPath.isNotEmpty) {
        _effectiveAudioUrl = globalPath;
      } else if (widget.localPath != null && widget.localPath!.isNotEmpty) {
        _effectiveAudioUrl = widget.localPath;
      } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        // For remote URLs, try downloading first
        final localPath = await AudioPlayerService.downloadAndCacheAudio(widget.audioUrl!);
        if (localPath != null) {
          _effectiveAudioUrl = localPath;
        } else {
          _effectiveAudioUrl = widget.audioUrl;
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      print("Error initializing player: $e");
      _hasError = true;
    }
  }
  
  void _showErrorMessage(String message) {
    if (!mounted || _isDisposed) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 