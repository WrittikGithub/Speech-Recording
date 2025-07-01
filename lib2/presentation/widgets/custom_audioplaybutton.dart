import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import 'package:sdcp_rebuild/domain/databases/save_task_databasehelper.dart';



// // class AudioPlayerButton extends StatefulWidget {
// //   final String audioUrl;
// //   final double size;
// //   final Color backgroundColor;
// //   final Color iconColor;
// //   final String contentId;

// //   const AudioPlayerButton({
// //     Key? key,
// //     required this.audioUrl,
// //     required this.contentId,
// //     this.size = 48.0,
// //     this.backgroundColor = Colors.blue,
// //     this.iconColor = Colors.white,
// //   }) : super(key: key);

// //   @override
// //   State<AudioPlayerButton> createState() => _AudioPlayerButtonState();
// // }

// // class _AudioPlayerButtonState extends State<AudioPlayerButton> {
// //   late AudioPlayer _audioPlayer;
// //   PlayerState? _playerState;
// //   StreamSubscription? _playerStateChangeSubscription;
// //   StreamSubscription? _playerCompleteSubscription;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _initializePlayer();
// //   }

// //   void _initializePlayer() {
// //     _audioPlayer = AudioPlayer();
// //     _audioPlayer.setReleaseMode(ReleaseMode.stop);
// //     _audioPlayer.setSourceUrl(widget.audioUrl);
// //     _initStreams();
// //   }

// //   void _initStreams() {
// //     _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
// //       if (mounted) {
// //         setState(() {
// //           _playerState = PlayerState.stopped;
// //         });
// //       }
// //     });

// //     _playerStateChangeSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
// //       if (mounted) {
// //         setState(() {
// //           _playerState = state;
// //         });
// //       }
// //     });
// //   }

// //   Future<void> _togglePlay() async {
// //     try {
// //       if (_playerState == PlayerState.playing) {
// //         await _audioPlayer.pause();
// //       } else {
// //         if (_playerState == PlayerState.stopped) {
// //           await _audioPlayer.setSourceUrl(widget.audioUrl);
// //         }
// //         await _audioPlayer.resume();
// //       }
// //     } catch (e) {
// //       debugPrint('Error playing audio: $e');
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Error playing audio: $e')),
// //         );
// //       }
// //     }
// //   }

// //   void _cleanupAudio() {
// //     _playerCompleteSubscription?.cancel();
// //     _playerStateChangeSubscription?.cancel();
// //     _audioPlayer.stop();
// //     _playerState = PlayerState.stopped;
// //   }

// //   @override
// //   void didUpdateWidget(AudioPlayerButton oldWidget) {
// //     super.didUpdateWidget(oldWidget);
    
// //     // Check if content has changed
// //     if (oldWidget.contentId != widget.contentId) {
// //       _cleanupAudio();
// //       _audioPlayer.setSourceUrl(widget.audioUrl);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final bool isPlaying = _playerState == PlayerState.playing;
    
// //     return Material(
// //       shape: const CircleBorder(),
// //       clipBehavior: Clip.antiAlias,
// //       color: widget.backgroundColor,
// //       child: InkWell(
// //         onTap: _togglePlay,
// //         child: Container(
// //           width: widget.size,
// //           height: widget.size,
// //           decoration: const BoxDecoration(
// //             shape: BoxShape.circle,
// //           ),
// //           child: Center(
// //             child: Icon(
// //               isPlaying ? Icons.pause : Icons.play_arrow,
// //               color: widget.iconColor,
// //               size: widget.size * 0.5,
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _cleanupAudio();
// //     _audioPlayer.dispose();
// //     super.dispose();
// //   }
// // }
// ///////////

// // class AudioPlayerButton extends StatefulWidget {
// //   final String audioUrl;
// //   final double size;
// //   final Color backgroundColor;
// //   final Color iconColor;
// //   final String contentId;

// //   const AudioPlayerButton({
// //     super.key,
// //     required this.audioUrl,
// //     required this.contentId,
// //     this.size = 48.0,
// //     this.backgroundColor = Colors.blue,
// //     this.iconColor = Colors.white,
// //   });

// //   @override
// //   State<AudioPlayerButton> createState() => _AudioPlayerButtonState();
// // }

// // class _AudioPlayerButtonState extends State<AudioPlayerButton> with SingleTickerProviderStateMixin {
// //   AudioPlayer? _audioPlayer;
// //   PlayerState _playerState = PlayerState.stopped;
// //   StreamSubscription? _playerStateChangeSubscription;
// //   StreamSubscription? _playerCompleteSubscription;
// //   bool _isInitialized = false;
// //   bool _hasError = false;
// //   bool _isLoading = false;

// //   final GlobalKey _buttonKey = GlobalKey();

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkAudioAvailability();
// //   }
// // /////////////////////////////


// //   Future<void> _checkAudioAvailability() async {
// //     if (widget.audioUrl.isEmpty) {
// //       setState(() {
// //         _hasError = true;
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _isLoading = true;
// //     });

// //     try {
// //       // Create a temporary audio player to test the URL
// //       final testPlayer = AudioPlayer();
// //       await testPlayer.setSourceUrl(widget.audioUrl);
// //       await testPlayer.dispose();
      
// //       // If we get here, the URL is valid
// //       setState(() {
// //         _hasError = false;
// //         _isLoading = false;
// //       });
// //       _initializePlayer();
// //     } catch (e) {
// //       debugPrint('Error checking audio availability: $e');
// //       setState(() {
// //         _hasError = true;
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   Future<void> _initializePlayer() async {
// //     if (_isInitialized || _hasError) return;

// //     _audioPlayer = AudioPlayer();
// //     _isInitialized = true;

// //     try {
// //       await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
// //       await _audioPlayer?.setSourceUrl(widget.audioUrl);
// //       _initStreams();
// //     } catch (e) {
// //       debugPrint('Error initializing audio player: $e');
// //       setState(() {
// //         _hasError = true;
// //         _isInitialized = false;
// //       });
// //     }
// //   }

// //   void _initStreams() {
// //     _playerCompleteSubscription?.cancel();
// //     _playerStateChangeSubscription?.cancel();

// //     _playerCompleteSubscription = _audioPlayer?.onPlayerComplete.listen((event) {
// //       if (mounted) {
// //         setState(() {
// //           _playerState = PlayerState.stopped;
// //         });
// //       }
// //     });

// //     _playerStateChangeSubscription = _audioPlayer?.onPlayerStateChanged.listen(
// //       (state) {
// //         if (mounted) {
// //           setState(() {
// //             _playerState = state;
// //           });
// //         }
// //       },
// //       onError: (error) {
// //         debugPrint('Error in player state stream: $error');
// //         setState(() {
// //           _hasError = true;
// //         });
// //       },
// //     );
// //   }

// //   Future<void> _togglePlay() async {
// //     if (_hasError) {
// //       _showErrorMessage('Audio file not available');
// //       return;
// //     }

// //     if (!_isInitialized) {
// //       await _initializePlayer();
// //     }

// //     try {
// //       if (_playerState == PlayerState.playing) {
// //         await _audioPlayer?.pause();
// //       } else {
// //         if (_playerState == PlayerState.stopped) {
// //           await _audioPlayer?.setSourceUrl(widget.audioUrl);
// //         }
// //         await _audioPlayer?.resume();
// //       }
// //     } catch (e) {
// //       debugPrint('Error playing audio: $e');
// //       setState(() {
// //         _hasError = true;
// //       });
// //       _showErrorMessage('Error playing audio');
// //     }
// //   }

// //   void _showErrorMessage(String message) {
// //     if (mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(message),
// //           backgroundColor: Colors.red,
// //           duration: const Duration(seconds: 2),
// //         ),
// //       );
// //     }
// //   }

// //   Future<void> _cleanupAudio() async {
// //     _playerCompleteSubscription?.cancel();
// //     _playerStateChangeSubscription?.cancel();
// //     await _audioPlayer?.stop();
// //     _playerState = PlayerState.stopped;
// //     _isInitialized = false;
// //   }

// //   @override
// //   void didUpdateWidget(AudioPlayerButton oldWidget) {
// //     super.didUpdateWidget(oldWidget);
    
// //     if (oldWidget.contentId != widget.contentId || 
// //         oldWidget.audioUrl != widget.audioUrl) {
// //       _cleanupAudio();
// //       _checkAudioAvailability();
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_isLoading) {
// //       return SizedBox(
// //         width: widget.size,
// //         height: widget.size,
// //         child: const CircularProgressIndicator(),
// //       );
// //     }

// //     return Container(
// //       key: _buttonKey,
// //       child: Material(
// //         shape: const CircleBorder(),
// //         clipBehavior: Clip.antiAlias,
// //         color: _hasError ? Colors.grey : widget.backgroundColor,
// //         child: InkWell(
// //           onTap: _togglePlay,
// //           child: Container(
// //             width: widget.size,
// //             height: widget.size,
// //             decoration: const BoxDecoration(
// //               shape: BoxShape.circle,
// //             ),
// //             child: Center(
// //               child: Icon(
// //                 _hasError 
// //                   ? Icons.error_outline
// //                   : (_playerState == PlayerState.playing 
// //                       ? Icons.pause 
// //                       : Icons.play_arrow),
// //                 color: widget.iconColor,
// //                 size: widget.size * 0.5,
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _cleanupAudio();
// //     _audioPlayer?.dispose();
// //     _audioPlayer = null;
// //     super.dispose();
// //   }
// // }
// //////////////////////////////////////

// // class UnifiedAudioPlayerButton extends StatefulWidget {
// //   final String? localPath;
// //   final String? audioUrl;
// //   final double size;
// //   final Color backgroundColor;
// //   final Color iconColor;
// //   final String contentId;

// //   const UnifiedAudioPlayerButton({
// //     super.key,
// //     this.localPath,
// //     this.audioUrl,
// //     required this.contentId,
// //     this.size = 48.0,
// //     this.backgroundColor = Colors.blue,
// //     this.iconColor = Colors.white,
// //   });

// //   @override
// //   State<UnifiedAudioPlayerButton> createState() => _UnifiedAudioPlayerButtonState();
// // }

// // class _UnifiedAudioPlayerButtonState extends State<UnifiedAudioPlayerButton> {
// //   AudioPlayer? _audioPlayer;
// //   PlayerState _playerState = PlayerState.stopped;
// //   StreamSubscription? _playerStateChangeSubscription;
// //   StreamSubscription? _playerCompleteSubscription;
// //   bool _isInitialized = false;
// //   bool _hasError = false;
// //   bool _isLoading = false;
// //   bool _useLocalPath = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _checkAudioAvailability();
// //   }

// //   Future<void> _checkAudioAvailability() async {
// //     if ((widget.localPath?.isEmpty ?? true) && (widget.audioUrl?.isEmpty ?? true)) {
// //       setState(() => _hasError = true);
// //       return;
// //     }

// //     setState(() => _isLoading = true);

// //     try {
// //       // First try local path if available
// //       if (widget.localPath?.isNotEmpty ?? false) {
// //         final file = File(widget.localPath!);
// //         if (await file.exists()) {
// //           _useLocalPath = true;
// //           setState(() {
// //             _hasError = false;
// //             _isLoading = false;
// //           });
// //           _initializePlayer();
// //           return;
// //         }
// //       }

// //       // If local file doesn't exist or path not provided, try URL
// //       if (widget.audioUrl?.isNotEmpty ?? false) {
// //         // Test URL availability
// //         final testPlayer = AudioPlayer();
// //         await testPlayer.setSourceUrl(widget.audioUrl!);
// //         await testPlayer.dispose();
        
// //         _useLocalPath = false;
// //         setState(() {
// //           _hasError = false;
// //           _isLoading = false;
// //         });
// //         _initializePlayer();
// //       } else {
// //         throw Exception('No valid audio source available');
// //       }
// //     } catch (e) {
// //       debugPrint('Error checking audio availability: $e');
// //       setState(() {
// //         _hasError = true;
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   Future<void> _initializePlayer() async {
// //     if (_isInitialized || _hasError) return;

// //     _audioPlayer = AudioPlayer();
// //     _isInitialized = true;

// //     try {
// //       await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
// //       if (_useLocalPath && widget.localPath != null) {
// //         await _audioPlayer?.setSourceDeviceFile(widget.localPath!);
// //       } else if (widget.audioUrl != null) {
// //         await _audioPlayer?.setSourceUrl(widget.audioUrl!);
// //       }
// //       _initStreams();
// //     } catch (e) {
// //       debugPrint('Error initializing audio player: $e');
// //       setState(() {
// //         _hasError = true;
// //         _isInitialized = false;
// //       });
// //     }
// //   }

// //   void _initStreams() {
// //     _playerCompleteSubscription?.cancel();
// //     _playerStateChangeSubscription?.cancel();

// //     _playerCompleteSubscription = _audioPlayer?.onPlayerComplete.listen((event) {
// //       if (mounted) {
// //         setState(() => _playerState = PlayerState.stopped);
// //       }
// //     });

// //     _playerStateChangeSubscription = _audioPlayer?.onPlayerStateChanged.listen(
// //       (state) {
// //         if (mounted) {
// //           setState(() => _playerState = state);
// //         }
// //       },
// //       onError: (error) {
// //         debugPrint('Error in player state stream: $error');
// //         setState(() => _hasError = true);
// //       },
// //     );
// //   }

// //   Future<void> _togglePlay() async {
// //     if (_hasError) {
// //       _showErrorMessage('Audio file not available');
// //       return;
// //     }

// //     if (!_isInitialized) {
// //       await _initializePlayer();
// //     }

// //     try {
// //       if (_playerState == PlayerState.playing) {
// //         await _audioPlayer?.pause();
// //       } else {
// //         if (_playerState == PlayerState.stopped) {
// //           if (_useLocalPath && widget.localPath != null) {
// //             await _audioPlayer?.setSourceDeviceFile(widget.localPath!);
// //           } else if (widget.audioUrl != null) {
// //             await _audioPlayer?.setSourceUrl(widget.audioUrl!);
// //           }
// //         }
// //         await _audioPlayer?.resume();
// //       }
// //     } catch (e) {
// //       debugPrint('Error playing audio: $e');
// //       setState(() => _hasError = true);
// //       _showErrorMessage('Error playing audio');
// //     }
// //   }

// //   void _showErrorMessage(String message) {
// //     if (mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(message),
// //           backgroundColor: Colors.red,
// //           duration: const Duration(seconds: 2),
// //         ),
// //       );
// //     }
// //   }

// //   Future<void> _cleanupAudio() async {
// //     _playerCompleteSubscription?.cancel();
// //     _playerStateChangeSubscription?.cancel();
// //     await _audioPlayer?.stop();
// //     _playerState = PlayerState.stopped;
// //     _isInitialized = false;
// //   }

// //   @override
// //   void didUpdateWidget(UnifiedAudioPlayerButton oldWidget) {
// //     super.didUpdateWidget(oldWidget);
    
// //     if (oldWidget.contentId != widget.contentId || 
// //         oldWidget.localPath != widget.localPath ||
// //         oldWidget.audioUrl != widget.audioUrl) {
// //       _cleanupAudio();
// //       _checkAudioAvailability();
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_isLoading) {
// //       return SizedBox(
// //         width: widget.size,
// //         height: widget.size,
// //         child: const CircularProgressIndicator(),
// //       );
// //     }

// //     return Material(
// //       shape: const CircleBorder(),
// //       clipBehavior: Clip.antiAlias,
// //       color: _hasError ? Colors.grey : widget.backgroundColor,
// //       child: InkWell(
// //         onTap: _togglePlay,
// //         child: Container(
// //           width: widget.size,
// //           height: widget.size,
// //           decoration: const BoxDecoration(
// //             shape: BoxShape.circle,
// //           ),
// //           child: Center(
// //             child: Icon(
// //               _hasError 
// //                 ? Icons.error_outline
// //                 : (_playerState == PlayerState.playing 
// //                     ? Icons.pause 
// //                     : Icons.play_arrow),
// //               color: widget.iconColor,
// //               size: widget.size * 0.5,
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _cleanupAudio();
// //     _audioPlayer?.dispose();
// //     _audioPlayer = null;
// //     super.dispose();
// //   }
// // }
// ///////////
// class UnifiedAudioPlayerButton extends StatefulWidget {
//   final String? localPath;
//   final String? audioUrl;
//   final double size;
//   final Color backgroundColor;
//   final Color iconColor;
//   final String contentId;

//   const UnifiedAudioPlayerButton({
//     super.key,
//     this.localPath,
//     this.audioUrl,
//     required this.contentId,
//     this.size = 48.0,
//     this.backgroundColor = Colors.blue,
//     this.iconColor = Colors.white,
//   });

//   @override
//   State<UnifiedAudioPlayerButton> createState() => _UnifiedAudioPlayerButtonState();
// }

// class _UnifiedAudioPlayerButtonState extends State<UnifiedAudioPlayerButton> {
//   AudioPlayer? _audioPlayer;
//   PlayerState _playerState = PlayerState.stopped;
//   StreamSubscription? _playerStateChangeSubscription;
//   StreamSubscription? _playerCompleteSubscription;
//   bool _isInitialized = false;
//   bool _hasError = false;
//   bool _isLoading = false;
//   bool _useLocalPath = false;
//   bool _isDisposed = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkAudioSourceAvailability();
//   }

//   // Safe setState wrapper
//   void _safeSetState(VoidCallback fn) {
//     if (mounted && !_isDisposed) {
//       setState(fn);
//     }
//   }

//   Future<void> _checkAudioSourceAvailability() async {
//     if ((widget.localPath?.isEmpty ?? true) && (widget.audioUrl?.isEmpty ?? true)) {
//       _safeSetState(() => _hasError = true);
//       return;
//     }

//     _safeSetState(() => _isLoading = true);

//     try {
//       final hasNetwork = await NetworkChecker.hasNetwork();

//       if (hasNetwork && (widget.audioUrl?.isNotEmpty ?? false)) {
//         await _testUrlAvailability();
//         _useLocalPath = false;
//       } else if (widget.localPath?.isNotEmpty ?? false) {
//         await _testLocalFileAvailability();
//         _useLocalPath = true;
//       } else {
//         throw Exception('No valid audio source available');
//       }

//       _safeSetState(() {
//         _hasError = false;
//         _isLoading = false;
//       });
      
//       if (!_isDisposed) {
//         await _initializePlayer();
//       }
//     } catch (e) {
//       debugPrint('Error checking audio availability: $e');
//       _safeSetState(() {
//         _hasError = true;
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _testUrlAvailability() async {
//     if (widget.audioUrl == null) throw Exception('Audio URL is null');
    
//     final testPlayer = AudioPlayer();
//     try {
//       await testPlayer.setSourceUrl(widget.audioUrl!);
//     } finally {
//       await testPlayer.dispose();
//     }
//   }

//   Future<void> _testLocalFileAvailability() async {
//     if (widget.localPath == null) throw Exception('Local path is null');
    
//     final file = File(widget.localPath!);
//     if (!await file.exists()) {
//       throw Exception('Local file does not exist');
//     }
//   }

//   Future<void> _initializePlayer() async {
//     if (_isDisposed || _isInitialized || _hasError) return;

//     _audioPlayer = AudioPlayer();
//     _isInitialized = true;

//     try {
//       await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
//       await _setAudioSource();
//       _initStreams();
//     } catch (e) {
//       debugPrint('Error initializing audio player: $e');
//       _safeSetState(() {
//         _hasError = true;
//         _isInitialized = false;
//       });
//     }
//   }

//   Future<void> _setAudioSource() async {
//     if (_isDisposed) return;
    
//     if (_useLocalPath && widget.localPath != null) {
//       await _audioPlayer?.setSourceDeviceFile(widget.localPath!);
//     } else if (widget.audioUrl != null) {
//       await _audioPlayer?.setSourceUrl(widget.audioUrl!);
//     } else {
//       throw Exception('No valid audio source');
//     }
//   }

//   void _initStreams() {
//     if (_isDisposed) return;

//     _playerCompleteSubscription?.cancel();
//     _playerStateChangeSubscription?.cancel();

//     _playerCompleteSubscription = _audioPlayer?.onPlayerComplete.listen((event) {
//       _safeSetState(() => _playerState = PlayerState.stopped);
//     });

//     _playerStateChangeSubscription = _audioPlayer?.onPlayerStateChanged.listen(
//       (state) {
//         _safeSetState(() => _playerState = state);
//       },
//       onError: (error) {
//         debugPrint('Error in player state stream: $error');
//         _safeSetState(() => _hasError = true);
//       },
//     );
//   }

//   Future<void> _togglePlay() async {
//     if (_hasError) {
//       _showErrorMessage('Audio file not available');
//       return;
//     }

//     if (!_isInitialized && !_isDisposed) {
//       await _initializePlayer();
//     }

//     try {
//       if (_playerState == PlayerState.playing) {
//         await _audioPlayer?.pause();
//       } else {
//         if (_playerState == PlayerState.stopped && !_isDisposed) {
//           await _setAudioSource();
//         }
//         await _audioPlayer?.resume();
//       }
//     } catch (e) {
//       debugPrint('Error playing audio: $e');
//       _safeSetState(() => _hasError = true);
//       _showErrorMessage('Error playing audio');
//     }
//   }

//   void _showErrorMessage(String message) {
//     if (!mounted || _isDisposed) return;
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   Future<void> _cleanupAudio() async {
//     _playerCompleteSubscription?.cancel();
//     _playerStateChangeSubscription?.cancel();
//     await _audioPlayer?.stop();
//     _playerState = PlayerState.stopped;
//     _isInitialized = false;
//   }

//   @override
//   void didUpdateWidget(UnifiedAudioPlayerButton oldWidget) {
//     super.didUpdateWidget(oldWidget);
    
//     if (oldWidget.contentId != widget.contentId || 
//         oldWidget.localPath != widget.localPath ||
//         oldWidget.audioUrl != widget.audioUrl) {
//       _cleanupAudio();
//       _checkAudioSourceAvailability();
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
//     _isDisposed = true;
//     _cleanupAudio();
//     _audioPlayer?.dispose();
//     _audioPlayer = null;
//     super.dispose();
//   }
// }
// First create an AudioManager singleton to track the currently playing button
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  String? _currentlyPlayingContentId;
  final _listeners = <Function(String?)>[];

  void setCurrentlyPlaying(String? contentId) {
    if (_currentlyPlayingContentId != contentId) {
      _currentlyPlayingContentId = contentId;
      _notifyListeners();
    }
  }

  void addListener(Function(String?) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(String?) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_currentlyPlayingContentId);
    }
  }
}

// Modified UnifiedAudioPlayerButton
class UnifiedAudioPlayerButton extends StatefulWidget {
  final String? localPath;
  final String? audioUrl;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final String contentId;

  const UnifiedAudioPlayerButton({
    super.key,
    this.localPath,
    this.audioUrl,
    required this.contentId,
    this.size = 48.0,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
  });

  @override
  State<UnifiedAudioPlayerButton> createState() => _UnifiedAudioPlayerButtonState();
}

class _UnifiedAudioPlayerButtonState extends State<UnifiedAudioPlayerButton> {
  AudioPlayer? _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _playerStateChangeSubscription;
  StreamSubscription? _playerCompleteSubscription;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isLoading = false;
  bool _useLocalPath = false;
  bool _isDisposed = false;
  final _audioManager = AudioManager();

  @override
  void initState() {
    super.initState();
    _checkAudioSourceAvailability();
    _audioManager.addListener(_handleOtherAudioPlaying);
  }

  void _handleOtherAudioPlaying(String? playingContentId) {
    if (playingContentId != null && 
        playingContentId != widget.contentId && 
        _playerState == PlayerState.playing) {
      _audioPlayer?.pause();
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  Future<void> _checkAudioSourceAvailability() async {
    if ((widget.localPath?.isEmpty ?? true) && (widget.audioUrl?.isEmpty ?? true)) {
      _safeSetState(() => _hasError = true);
      return;
    }

    _safeSetState(() => _isLoading = true);

    try {
      final hasNetwork = await NetworkChecker.hasNetwork();

      if (hasNetwork && (widget.audioUrl?.isNotEmpty ?? false)) {
        await _testUrlAvailability();
        _useLocalPath = false;
      } else if (widget.localPath?.isNotEmpty ?? false) {
        await _testLocalFileAvailability();
        _useLocalPath = true;
      } else {
        throw Exception('No valid audio source available');
      }

      _safeSetState(() {
        _hasError = false;
        _isLoading = false;
      });
      
      if (!_isDisposed) {
        await _initializePlayer();
      }
    } catch (e) {
      debugPrint('Error checking audio availability: $e');
      _safeSetState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _testUrlAvailability() async {
    if (widget.audioUrl == null) throw Exception('Audio URL is null');
    
    final testPlayer = AudioPlayer();
    try {
      await testPlayer.setSourceUrl(widget.audioUrl!);
    } finally {
      await testPlayer.dispose();
    }
  }

  Future<void> _testLocalFileAvailability() async {
    if (widget.localPath == null) throw Exception('Local path is null');
    
    final file = File(widget.localPath!);
    if (!await file.exists()) {
      throw Exception('Local file does not exist');
    }
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed || _isInitialized || _hasError) return;

    _audioPlayer = AudioPlayer();
    _isInitialized = true;

    try {
      await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
      await _setAudioSource();
      _initStreams();
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      _safeSetState(() {
        _hasError = true;
        _isInitialized = false;
      });
    }
  }

  Future<void> _setAudioSource() async {
    if (_isDisposed) return;
    
    if (_useLocalPath && widget.localPath != null) {
      await _audioPlayer?.setSourceDeviceFile(widget.localPath!);
    } else if (widget.audioUrl != null) {
      await _audioPlayer?.setSourceUrl(widget.audioUrl!);
    } else {
      throw Exception('No valid audio source');
    }
  }

  void _initStreams() {
    if (_isDisposed) return;

    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();

    _playerCompleteSubscription = _audioPlayer?.onPlayerComplete.listen((event) {
      _safeSetState(() => _playerState = PlayerState.stopped);
      _audioManager.setCurrentlyPlaying(null);
    });

    _playerStateChangeSubscription = _audioPlayer?.onPlayerStateChanged.listen(
      (state) {
        _safeSetState(() => _playerState = state);
      },
      onError: (error) {
        debugPrint('Error in player state stream: $error');
        _safeSetState(() => _hasError = true);
      },
    );
  }

  Future<void> _togglePlay() async {
    if (_hasError) {
      _showErrorMessage('Audio file not available');
      return;
    }

    if (!_isInitialized && !_isDisposed) {
      await _initializePlayer();
    }

    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer?.pause();
        _audioManager.setCurrentlyPlaying(null);
      } else {
        if (_playerState == PlayerState.stopped && !_isDisposed) {
          await _setAudioSource();
        }
        _audioManager.setCurrentlyPlaying(widget.contentId);
        await _audioPlayer?.resume();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _safeSetState(() => _hasError = true);
      _showErrorMessage('Error playing audio');
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

  Future<void> _cleanupAudio() async {
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    await _audioPlayer?.stop();
    _audioManager.setCurrentlyPlaying(null);
    _playerState = PlayerState.stopped;
    _isInitialized = false;
  }

  @override
  void didUpdateWidget(UnifiedAudioPlayerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.contentId != widget.contentId || 
        oldWidget.localPath != widget.localPath ||
        oldWidget.audioUrl != widget.audioUrl) {
      _cleanupAudio();
      _checkAudioSourceAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const CircularProgressIndicator(),
      );
    }

    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: _hasError ? Colors.grey : widget.backgroundColor,
      child: InkWell(
        onTap: _togglePlay,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _hasError 
                ? Icons.error_outline
                : (_playerState == PlayerState.playing 
                    ? Icons.pause 
                    : Icons.play_arrow),
              color: widget.iconColor,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _audioManager.removeListener(_handleOtherAudioPlaying);
    _cleanupAudio();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }
}