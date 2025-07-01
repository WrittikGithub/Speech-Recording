import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class SimpleAudioPlayer extends StatefulWidget {
  final String audioPath;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onInit;
  
  const SimpleAudioPlayer({
    super.key,
    required this.audioPath,
    this.size = 48.0,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
    this.onInit,
  });

  @override
  State<SimpleAudioPlayer> createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  late FlutterSoundPlayer _player;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initPlayer();
    
    // Call onInit callback if provided
    if (widget.onInit != null) {
      widget.onInit!();
    }
  }
  
  @override
  void dispose() {
    _stopAndClosePlayer();
    super.dispose();
  }
  
  Future<void> _initPlayer() async {
    print("SIMPLE_PLAYER: Initializing player");
    try {
      _player = FlutterSoundPlayer();
      await _player.openPlayer();
      setState(() => _isInitialized = true);
      print("SIMPLE_PLAYER: Player initialized successfully");
    } catch (e) {
      print("SIMPLE_PLAYER: Error initializing player: $e");
    }
  }
  
  Future<void> _stopAndClosePlayer() async {
    print("SIMPLE_PLAYER: Stopping and closing player");
    try {
      if (_isPlaying) {
        await _player.stopPlayer();
      }
      await _player.closePlayer();
    } catch (e) {
      print("SIMPLE_PLAYER: Error closing player: $e");
    }
  }
  
  Future<void> _togglePlay() async {
    print("SIMPLE_PLAYER: Toggle play called for: ${widget.audioPath}");
    
    if (!_isInitialized) {
      _showError("Player not initialized");
      return;
    }
    
    if (_isPlaying) {
      await _stopPlayback();
    } else {
      await _startPlayback();
    }
  }
  
  Future<void> _stopPlayback() async {
    print("SIMPLE_PLAYER: Stopping playback");
    try {
      await _player.stopPlayer();
      setState(() => _isPlaying = false);
    } catch (e) {
      print("SIMPLE_PLAYER: Error stopping playback: $e");
    }
  }
  
  Future<void> _startPlayback() async {
    print("SIMPLE_PLAYER: Starting playback from path: ${widget.audioPath}");
    setState(() => _isLoading = true);
    
    try {
      // Check if file exists
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        print("SIMPLE_PLAYER: File doesn't exist: ${widget.audioPath}");
        _showError("Audio file not found");
        setState(() => _isLoading = false);
        return;
      }
      
      final fileSize = await file.length();
      print("SIMPLE_PLAYER: File size: $fileSize bytes");
      
      if (fileSize < 100) {
        print("SIMPLE_PLAYER: File too small, might be corrupted");
        _showError("Audio file may be corrupted");
        setState(() => _isLoading = false);
        return;
      }

      // Check if the file path has the correct format
      String audioPath = widget.audioPath;
      if (audioPath.startsWith('file://')) {
        audioPath = audioPath.substring(7); // Remove 'file://' prefix
        print("SIMPLE_PLAYER: Corrected file path from: ${widget.audioPath} to: $audioPath");
      }
      
      // Reset the player first to ensure clean state
      if (_player.isOpen()) {
        await _player.closePlayer();
      }
      await _player.openPlayer();
      
      // Get the codec based on file extension
      final ext = audioPath.toLowerCase();
      Codec codec = Codec.aacADTS;  // Default
      
      if (ext.endsWith('.mp3')) {
        codec = Codec.mp3;
      } else if (ext.endsWith('.wav')) {
        codec = Codec.pcm16WAV;
      } else if (ext.endsWith('.aac')) {
        codec = Codec.aacADTS;
      }
      
      print("SIMPLE_PLAYER: Using codec: ${codec.name}");
      
      // Add a delay to ensure Android audio system is ready
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      await _player.startPlayer(
        fromURI: audioPath,
        codec: codec,
        whenFinished: () {
          print("SIMPLE_PLAYER: Playback completed");
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _isLoading = false;
            });
          }
        },
      );
      
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
      
      print("SIMPLE_PLAYER: Playback started successfully");
    } catch (e) {
      print("SIMPLE_PLAYER: Error starting playback: $e");
      _showError("Error playing audio: ${e.toString().substring(0, math.min(e.toString().length, 100))}");
      setState(() => _isLoading = false);
      
      // Try to recover the player
      await _initPlayer();
    }
  }
  
  void _showError(String message) {
    print("SIMPLE_PLAYER: Error: $message");
    if (!mounted) return;
    
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
      onTap: _isLoading ? null : _togglePlay,
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