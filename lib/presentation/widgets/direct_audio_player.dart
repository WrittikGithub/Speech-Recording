import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';

class DirectAudioPlayer extends StatefulWidget {
  final String? audioPath;
  final String? audioUrl;
  final String contentId;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  
  const DirectAudioPlayer({
    super.key,
    this.audioPath,
    this.audioUrl,
    required this.contentId,
    this.size = 48.0,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
  });

  @override
  State<DirectAudioPlayer> createState() => _DirectAudioPlayerState();
}

class _DirectAudioPlayerState extends State<DirectAudioPlayer> {
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _effectiveAudioPath;
  
  @override
  void initState() {
    super.initState();
    print("DEBUG_AUDIO: DirectAudioPlayer initialized for contentId=${widget.contentId}");
    print("DEBUG_AUDIO: audioPath=${widget.audioPath}, audioUrl=${widget.audioUrl}");
    _prepareAudioSource();
  }
  
  @override
  void dispose() {
    print("DEBUG_AUDIO: DirectAudioPlayer disposing for contentId=${widget.contentId}");
    if (_isPlaying) {
      AudioPlayerService.stopAudio();
    }
    super.dispose();
  }
  
  Future<void> _prepareAudioSource() async {
    print("DEBUG_AUDIO: Preparing audio source for contentId=${widget.contentId}");
    
    // First try the direct path
    if (widget.audioPath != null && widget.audioPath!.isNotEmpty) {
      try {
        print("DEBUG_AUDIO: Checking audio path: ${widget.audioPath}");
        final file = File(widget.audioPath!);
        if (await file.exists()) {
          final fileSize = await file.length();
          print("DEBUG_AUDIO: File exists with size: $fileSize bytes");
          if (fileSize > 100) {
            _effectiveAudioPath = widget.audioPath;
            setState(() => _isInitialized = true);
            print("DEBUG_AUDIO: Using local audio path: $_effectiveAudioPath");
            return;
          } else {
            print("DEBUG_AUDIO: File too small: $fileSize bytes");
          }
        } else {
          print("DEBUG_AUDIO: File does not exist: ${widget.audioPath}");
        }
      } catch (e) {
        print("DEBUG_AUDIO: Error checking audioPath: $e");
      }
    } else {
      print("DEBUG_AUDIO: No audioPath provided");
    }
    
    // Then try the URL if available
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        print("DEBUG_AUDIO: Attempting to download from URL: ${widget.audioUrl}");
        setState(() => _isLoading = true);
        final downloadedPath = await _downloadFile(widget.audioUrl!);
        
        if (downloadedPath != null) {
          _effectiveAudioPath = downloadedPath;
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
          print("DEBUG_AUDIO: Downloaded audio to: $_effectiveAudioPath");
          return;
        } else {
          print("DEBUG_AUDIO: Download failed, no path returned");
        }
      } catch (e) {
        print("DEBUG_AUDIO: Error downloading audio: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      print("DEBUG_AUDIO: No audioUrl provided");
    }
    
    // If we get here, we couldn't find a valid audio source
    print("DEBUG_AUDIO: No valid audio source found for contentId=${widget.contentId}");
    setState(() => _hasError = true);
  }
  
  Future<String?> _downloadFile(String url) async {
    try {
      print("DEBUG_AUDIO: Starting download from: $url");
      // Use AudioPlayerService's download method which has better caching
      final downloadedPath = await AudioPlayerService.downloadAndCacheAudio(url);
      if (downloadedPath != null) {
        print("DEBUG_AUDIO: Download successful, path: $downloadedPath");
        
        // Verify file exists and has content
        final file = File(downloadedPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          print("DEBUG_AUDIO: Downloaded file exists, size: $fileSize bytes");
        } else {
          print("DEBUG_AUDIO: Downloaded file doesn't exist after download!");
        }
      } else {
        print("DEBUG_AUDIO: AudioPlayerService.downloadAndCacheAudio returned null path");
      }
      return downloadedPath;
    } catch (e) {
      print("DEBUG_AUDIO: Error downloading file: $e");
      return null;
    }
  }
  
  Future<void> _togglePlay() async {
    print("DEBUG_AUDIO: Toggle play called for contentId=${widget.contentId}");
    
    if (!_isInitialized) {
      print("DEBUG_AUDIO: Not initialized, cannot play");
      _showError("Audio player not ready");
      return;
    }
    
    if (_effectiveAudioPath == null) {
      print("DEBUG_AUDIO: No effective audio path available");
      _showError("No audio file available");
      return;
    }
    
    // Check permissions first
    if (!await _checkPermissions()) {
      print("DEBUG_AUDIO: Permission denied");
      _showError("Permission denied for audio playback");
      return;
    }
    
    try {
      if (_isPlaying) {
        print("DEBUG_AUDIO: Stopping current playback");
        await AudioPlayerService.stopAudio();
        setState(() => _isPlaying = false);
      } else {
        print("DEBUG_AUDIO: Starting playback from: $_effectiveAudioPath");
        
        // Validate file exists and has content
        final file = File(_effectiveAudioPath!);
        if (!await file.exists()) {
          print("DEBUG_AUDIO: Audio file not found at path: $_effectiveAudioPath");
          _showError("Audio file not found");
          return;
        }
        
        final fileSize = await file.length();
        print("DEBUG_AUDIO: File size before playing: $fileSize bytes");
        
        if (fileSize < 100) {
          print("DEBUG_AUDIO: Audio file too small, might be corrupted");
          _showError("Audio file is corrupted");
          return;
        }
        
        // Try playing using AudioPlayerService
        print("DEBUG_AUDIO: Calling AudioPlayerService.playAudio()");
        final success = await AudioPlayerService.playAudio(_effectiveAudioPath!, onComplete: () {
          print("DEBUG_AUDIO: Playback completed callback");
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        });
        
        if (success) {
          print("DEBUG_AUDIO: AudioPlayerService reported successful playback start");
          setState(() => _isPlaying = true);
        } else {
          print("DEBUG_AUDIO: AudioPlayerService failed to start playback");
          _showError("Error playing audio");
          
          // Try direct play using flutter_sound as a fallback
          _tryDirectPlay();
        }
      }
    } catch (e) {
      print("DEBUG_AUDIO: Error during playback: $e");
      _showError("Error playing audio");
    }
  }
  
  Future<bool> _checkPermissions() async {
    print("DEBUG_AUDIO: Checking permissions");
    try {
      // For Android, check storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (status.isDenied) {
          print("DEBUG_AUDIO: Storage permission is denied, requesting...");
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return status.isGranted;
      }
      
      // iOS requires no explicit permission for playback from app storage
      return true;
    } catch (e) {
      print("DEBUG_AUDIO: Error checking permissions: $e");
      return false;
    }
  }
  
  Future<void> _tryDirectPlay() async {
    print("DEBUG_AUDIO: Trying direct playback as fallback");
    try {
      // Create a new player instance for direct playback
      final player = FlutterSoundPlayer();
      await player.openPlayer();
      
      print("DEBUG_AUDIO: Direct player opened, attempting to play: $_effectiveAudioPath");
      await player.startPlayer(
        fromURI: _effectiveAudioPath,
        whenFinished: () {
          print("DEBUG_AUDIO: Direct playback completed");
          player.closePlayer();
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      );
      
      print("DEBUG_AUDIO: Direct playback started successfully");
      setState(() => _isPlaying = true);
    } catch (e) {
      print("DEBUG_AUDIO: Error in direct playback attempt: $e");
      _showError("Error playing audio");
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    
    print("DEBUG_AUDIO: Showing error message: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : () {
        print("DEBUG_AUDIO: Audio button tapped for contentId=${widget.contentId}");
        _togglePlay();
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  child: CircularProgressIndicator(
                    color: widget.iconColor,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: widget.iconColor,
                  size: widget.size * 0.6,
                ),
        ),
      ),
    );
  }
} 