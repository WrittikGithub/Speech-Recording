// import 'dart:async';
// import 'dart:io';

// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';

// class AudioPlayerButtonFromlocal extends StatefulWidget {
//   final String localPath;
//   final double size;
//   final Color backgroundColor;
//   final Color iconColor;
//   final String contentId;

//   const AudioPlayerButtonFromlocal({
//     Key? key,
//     required this.localPath,
//     required this.contentId,
//     this.size = 48.0,
//     this.backgroundColor = Colors.blue,
//     this.iconColor = Colors.white,
//   }) : super(key: key);

//   @override
//   State<AudioPlayerButtonFromlocal> createState() => _AudioPlayerButtonState();
// }

// class _AudioPlayerButtonState extends State<AudioPlayerButtonFromlocal> {
//   AudioPlayer? _audioPlayer;
//   PlayerState _playerState = PlayerState.stopped;
//   StreamSubscription? _playerStateChangeSubscription;
//   StreamSubscription? _playerCompleteSubscription;
//   bool _isInitialized = false;
//   bool _hasError = false;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkAudioAvailability();
//   }

//   Future<void> _checkAudioAvailability() async {
//     if (widget.localPath.isEmpty) {
//       setState(() => _hasError = true);
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final file = File(widget.localPath);
//       if (!await file.exists()) {
//         throw Exception('Audio file not found');
//       }
      
//       // If file exists, initialize the player
//       setState(() {
//         _hasError = false;
//         _isLoading = false;
//       });
//       _initializePlayer();
//     } catch (e) {
//       debugPrint('Error checking audio file: $e');
//       setState(() {
//         _hasError = true;
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _initializePlayer() async {
//     if (_isInitialized || _hasError) return;

//     _audioPlayer = AudioPlayer();
//     _isInitialized = true;

//     try {
//       await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
//       await _audioPlayer?.setSourceDeviceFile(widget.localPath);
//       _initStreams();
//     } catch (e) {
//       debugPrint('Error initializing audio player: $e');
//       setState(() {
//         _hasError = true;
//         _isInitialized = false;
//       });
//     }
//   }

//   void _initStreams() {
//     _playerCompleteSubscription?.cancel();
//     _playerStateChangeSubscription?.cancel();

//     _playerCompleteSubscription = _audioPlayer?.onPlayerComplete.listen((event) {
//       if (mounted) {
//         setState(() => _playerState = PlayerState.stopped);
//       }
//     });

//     _playerStateChangeSubscription = _audioPlayer?.onPlayerStateChanged.listen(
//       (state) {
//         if (mounted) {
//           setState(() => _playerState = state);
//         }
//       },
//       onError: (error) {
//         debugPrint('Error in player state stream: $error');
//         setState(() => _hasError = true);
//       },
//     );
//   }

//   Future<void> _togglePlay() async {
//     if (_hasError) {
//       _showErrorMessage('Audio file not available');
//       return;
//     }

//     if (!_isInitialized) {
//       await _initializePlayer();
//     }

//     try {
//       if (_playerState == PlayerState.playing) {
//         await _audioPlayer?.pause();
//       } else {
//         if (_playerState == PlayerState.stopped) {
//           await _audioPlayer?.setSourceDeviceFile(widget.localPath);
//         }
//         await _audioPlayer?.resume();
//       }
//     } catch (e) {
//       debugPrint('Error playing audio: $e');
//       setState(() => _hasError = true);
//       _showErrorMessage('Error playing audio');
//     }
//   }

//   void _showErrorMessage(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   Future<void> _cleanupAudio() async {
//     _playerCompleteSubscription?.cancel();
//     _playerStateChangeSubscription?.cancel();
//     await _audioPlayer?.stop();
//     _playerState = PlayerState.stopped;
//     _isInitialized = false;
//   }

//   @override
//   void didUpdateWidget(AudioPlayerButtonFromlocal oldWidget) {
//     super.didUpdateWidget(oldWidget);
    
//     if (oldWidget.contentId != widget.contentId || 
//         oldWidget.localPath != widget.localPath) {
//       _cleanupAudio();
//       _checkAudioAvailability();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return SizedBox(
//         width: widget.size,
//         height: widget.size,
//         child: const CircularProgressIndicator(),
//       );
//     }

//     return Material(
//       shape: const CircleBorder(),
//       clipBehavior: Clip.antiAlias,
//       color: _hasError ? Colors.grey : widget.backgroundColor,
//       child: InkWell(
//         onTap: _togglePlay,
//         child: Container(
//           width: widget.size,
//           height: widget.size,
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//           ),
//           child: Center(
//             child: Icon(
//               _hasError 
//                 ? Icons.error_outline
//                 : (_playerState == PlayerState.playing 
//                     ? Icons.pause 
//                     : Icons.play_arrow),
//               color: widget.iconColor,
//               size: widget.size * 0.5,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _cleanupAudio();
//     _audioPlayer?.dispose();
//     _audioPlayer = null;
//     super.dispose();
//   }
// }