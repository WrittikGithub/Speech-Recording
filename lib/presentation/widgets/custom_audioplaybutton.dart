import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:flutter_sound/flutter_sound.dart' as flutter_sound;

import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/presentation/helpers/audio_download_helper.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';

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
  final bool isSaved;

  const UnifiedAudioPlayerButton({
    super.key,
    this.localPath,
    this.audioUrl,
    required this.contentId,
    this.size = 48.0,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
    this.isSaved = false,
  });

  @override
  State<UnifiedAudioPlayerButton> createState() => _UnifiedAudioPlayerButtonState();
}

class _UnifiedAudioPlayerButtonState extends State<UnifiedAudioPlayerButton> {
  AudioPlayer? _audioPlayer;
  just_audio.AudioPlayer? _justAudioPlayer;
  flutter_sound.FlutterSoundPlayer? _flutterSoundPlayer;
  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _playerStateChangeSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _justAudioPlayerStatusSubscription;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isLoading = false;
  final bool _useLocalPath = false;
  bool _isDisposed = false;
  bool _hasAudio = false;
  String? _effectiveAudioUrl;
  final bool _isPlaying = false;
  final _audioManager = AudioManager();
  bool _usingJustAudio = false;
  bool _usingFlutterSound = false;

  // Added cache for downloaded files
  static final Map<String, String> _downloadCache = {};

  Future<String?> _downloadAndCacheAudio(String url) async {
    // Use the new improved helper
    return AudioDownloadHelper.downloadAndCacheAudio(url);
  }
  
  // Check if WAV file has valid header
  Future<bool> _isValidWavFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final bytes = await file.readAsBytes();
      if (bytes.length < 44) return false; // Minimum WAV header size
      
      // Check for RIFF header and WAVE format
      final header = String.fromCharCodes(bytes.sublist(0, 4));
      final format = String.fromCharCodes(bytes.sublist(8, 12));
      
      return header == 'RIFF' && format == 'WAVE';
    } catch (e) {
      debugPrint('Error checking WAV file validity: $e');
      return false;
    }
  }
  
  // Try to fix WAV header or convert to different format if needed
  Future<String?> _fixWavFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      // Create a new file with .fixed.wav extension
      final fixedPath = filePath.replaceAll('.wav', '.fixed.wav');
      final fixedFile = File(fixedPath);
      
      // Just copy the file for now - you could implement actual WAV header fixing here
      await file.copy(fixedPath);
      
      return fixedPath;
    } catch (e) {
      debugPrint('Error fixing WAV file: $e');
      return null;
    }
  }
  
  // Replace WAV header with a standard one
  Future<String?> _fixWavHeader(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      // Read the file content
      final bytes = await file.readAsBytes();
      if (bytes.length < 44) return null; // Too small to be a valid WAV
      
      debugPrint('WAV file size: ${bytes.length} bytes');
      
      // Create a fixed file path
      final fixedPath = filePath.replaceAll('.wav', '.fixed.wav');
      final fixedFile = File(fixedPath);
      
      // Check if the audio data seems to have content
      if (bytes.length <= 44) {
        debugPrint('WAV file only contains header data, no audio content');
        return null;
      }
      
      // Get any data chunks from original file if they exist
      List<int> dataBytes = [];
      bool foundDataChunk = false;

      // Check common WAV format with 'data' chunk at position 36
      if (bytes.length > 44) {
        final dataHeader = String.fromCharCodes(bytes.sublist(36, 40));
        if (dataHeader == 'data') {
          foundDataChunk = true;
          // If 'data' chunk found at standard position, use rest of file as audio data
          dataBytes = bytes.sublist(44);
          debugPrint('Standard data chunk found at position 36, data size: ${dataBytes.length}');
        }
      }
      
      // If no standard data chunk, search for 'data' marker in the file
      if (!foundDataChunk && bytes.length > 100) {
        for (int i = 0; i < bytes.length - 4; i++) {
          if (String.fromCharCodes(bytes.sublist(i, i + 4)) == 'data') {
            // Found 'data' marker - data starts 8 bytes later (after chunk size)
            foundDataChunk = true;
            if (i + 8 < bytes.length) {
              dataBytes = bytes.sublist(i + 8);
              debugPrint('Non-standard data chunk found at position $i, data size: ${dataBytes.length}');
            }
            break;
          }
        }
      }
      
      // If still no data chunk found, use the whole file minus first 44 bytes as a fallback
      if (!foundDataChunk && bytes.length > 44) {
        dataBytes = bytes.sublist(44);
        debugPrint('No data chunk found, using everything after 44 bytes, size: ${dataBytes.length}');
      }
      
      // Create a basic WAV header (44 bytes)
      final header = ByteData(44);
      
      // RIFF header
      header.setUint8(0, 82); // 'R'
      header.setUint8(1, 73); // 'I'
      header.setUint8(2, 70); // 'F'
      header.setUint8(3, 70); // 'F'
      
      // File size - 8 (size after this field)
      final fileSize = 36 + dataBytes.length;
      header.setUint32(4, fileSize, Endian.little);
      
      // WAVE header
      header.setUint8(8, 87);  // 'W'
      header.setUint8(9, 65);  // 'A'
      header.setUint8(10, 86); // 'V'
      header.setUint8(11, 69); // 'E'
      
      // 'fmt ' chunk
      header.setUint8(12, 102); // 'f'
      header.setUint8(13, 109); // 'm'
      header.setUint8(14, 116); // 't'
      header.setUint8(15, 32);  // ' '
      
      // fmt chunk size (16 for PCM)
      header.setUint32(16, 16, Endian.little);
      
      // Audio format (1 = PCM)
      header.setUint16(20, 1, Endian.little);
      
      // Number of channels (1 = mono, 2 = stereo)
      header.setUint16(22, 1, Endian.little);
      
      // Sample rate (e.g., 44100)
      header.setUint32(24, 44100, Endian.little);
      
      // Byte rate (SampleRate * NumChannels * BitsPerSample/8)
      header.setUint32(28, 44100 * 1 * 16 ~/ 8, Endian.little);
      
      // Block align (NumChannels * BitsPerSample/8)
      header.setUint16(32, 1 * 16 ~/ 8, Endian.little);
      
      // Bits per sample
      header.setUint16(34, 16, Endian.little);
      
      // 'data' chunk
      header.setUint8(36, 100); // 'd'
      header.setUint8(37, 97);  // 'a'
      header.setUint8(38, 116); // 't'
      header.setUint8(39, 97);  // 'a'
      
      // Data size
      header.setUint32(40, dataBytes.length, Endian.little);
      
      // Create fixed file with new header and data
      final headerBytes = header.buffer.asUint8List();
      
      // Write the fixed file
      final sink = fixedFile.openWrite();
      sink.add(headerBytes);
      sink.add(dataBytes);
      await sink.close();
      
      debugPrint('Fixed WAV file saved to: $fixedPath with data size: ${dataBytes.length}');
      
      // Verify the file was created with data
      if (await fixedFile.exists()) {
        final fixedSize = await fixedFile.length();
        debugPrint('Fixed file size: $fixedSize bytes');
        if (fixedSize > 44) {
          return fixedPath;
        } else {
          debugPrint('Fixed file has no audio data');
          return null;
        }
      }
      
      return fixedPath;
    } catch (e) {
      debugPrint('Error fixing WAV header: $e');
      return null;
    }
  }

  // Verify if a WAV file has audio data (not just silence)
  Future<bool> _verifyHasAudioContent(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final bytes = await file.readAsBytes();
      
      // First check file is large enough for actual audio content
      if (bytes.length <= 44) return false;
      
      // Check last 1000 bytes (or file length if smaller) to see if there's any non-zero data
      // This is a simple check but helps identify files that are just header with no data
      final checkLength = math.min(1000, bytes.length - 44);
      final startPos = bytes.length - checkLength;
      
      int nonZeroCount = 0;
      for (int i = startPos; i < bytes.length; i++) {
        if (bytes[i] != 0) {
          nonZeroCount++;
          // If we find at least 10 non-zero bytes, assume it has content
          if (nonZeroCount > 10) return true;
        }
      }
      
      // Also check first 1000 bytes after header (44 bytes)
      final headerCheckLength = math.min(1000, bytes.length - 44);
      for (int i = 44; i < 44 + headerCheckLength; i++) {
        if (bytes[i] != 0) {
          nonZeroCount++;
          if (nonZeroCount > 10) return true;
        }
      }
      
      // If almost all bytes are zero, probably no audio content
      return nonZeroCount > 10;
    } catch (e) {
      debugPrint('Error verifying audio content: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _hasAudio = widget.isSaved;
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
    bool hasAudio = widget.isSaved;
    String? effectiveUrl;
    
    // First check if we have a valid remote URL
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      // Only count it if the URL contains a slash (indicating a valid path)
      if (widget.audioUrl!.contains('/')) {
        hasAudio = true;
        effectiveUrl = widget.audioUrl;
        print('Found valid audio URL: ${widget.audioUrl}');
      } else {
        print('URL exists but appears invalid: ${widget.audioUrl}');
      }
    }
    
    // Then check if we have a valid local path
    if (!hasAudio && widget.localPath != null && widget.localPath!.isNotEmpty) {
      final file = File(widget.localPath!);
      if (await file.exists()) {
        hasAudio = true;
        effectiveUrl = widget.localPath;
        print('Found valid local path: ${widget.localPath}');
      } else {
        print('Local path exists but file not found: ${widget.localPath}');
      }
    }
    
    // If no explicit URL/path, check the database
    if (!hasAudio) {
      try {
        final dbHelper = ContentDatabaseHelper();
        final paths = await dbHelper.getAudioPathsForContent(widget.contentId);
        
        if (paths != null) {
          // Check for server URL
          if (paths.containsKey('serverUrl') && 
              paths['serverUrl'] != null && 
              paths['serverUrl']!.isNotEmpty) {
            
            final serverUrl = paths['serverUrl']!;
            if (serverUrl.contains('/')) {
              hasAudio = true;
              effectiveUrl = serverUrl;
              print('Found valid DB server URL: $serverUrl');
            }
          }
          // Check for local path
          else if (paths.containsKey('localPath') && 
                  paths['localPath'] != null && 
                  paths['localPath']!.isNotEmpty) {
            
            final localPath = paths['localPath']!;
            final file = File(localPath);
            if (await file.exists()) {
              hasAudio = true;
              effectiveUrl = localPath;
              print('Found valid DB local path: $localPath');
            }
          }
        }
      } catch (e) {
        print('Error checking database: $e');
      }
    }
    
    // Update state if mounted
    if (mounted) {
      setState(() {
        _hasAudio = hasAudio || widget.isSaved;
        _effectiveAudioUrl = effectiveUrl;
        print('Updated audio state for ${widget.contentId}: hasAudio=$_hasAudio, effectiveUrl=$_effectiveAudioUrl, isSaved=${widget.isSaved}');
      });
    }
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed || _isInitialized || _hasError) return;

    _isInitialized = true;
    debugPrint('Initializing audio player for content ID: ${widget.contentId}');

    try {
      if (_effectiveAudioUrl == null) {
        throw Exception('No valid audio source available');
      }
      
      debugPrint('Using audio URL: $_effectiveAudioUrl');
      
      // For Vacha server URLs, try the direct API endpoint first
      if (_effectiveAudioUrl!.contains('vacha.langlex.com') && _effectiveAudioUrl!.contains('/uploads/')) {
        // Extract task and content info from URL
        final urlInfo = AudioDownloadHelper.extractVachaUrlInfo(_effectiveAudioUrl!);
        String? taskId = urlInfo['taskId'];
        String? taskTargetId = urlInfo['taskTargetId'];
        String? language = urlInfo['language'];
        
        if (taskId != null) {
          final apiPath = await AudioDownloadHelper.downloadVachaServerAudio(
            widget.contentId, 
            taskId, 
            taskTargetId, 
            language
          );
          
          if (apiPath != null) {
            _effectiveAudioUrl = apiPath;
            await _initializeWithAudioplayers(); // MP3 works best with AudioPlayer
            return;
          } else {
            debugPrint('API download failed, falling back to normal URL');
          }
        }
      }
      
      // For Android, try to download the file first for any URL type
      if (Platform.isAndroid && _effectiveAudioUrl!.startsWith('http')) {
        final localPath = await _downloadAndCacheAudio(_effectiveAudioUrl!);
        if (localPath != null) {
          debugPrint('Successfully downloaded to: $localPath');
          _effectiveAudioUrl = localPath;
          
          // Choose player based on file type
          if (localPath.toLowerCase().endsWith('.wav')) {
            try {
              await _initializeWithFlutterSound();
            } catch (e) {
              debugPrint('Error initializing WAV with flutter_sound: $e');
              try {
                await _initializeWithAudioplayers();
                return;
              } catch (e) {
                debugPrint('Error with audioPlayer fallback: $e');
              }
            }
          } else {
            // For non-WAV files, use AudioPlayer directly
            try {
              await _initializeWithAudioplayers();
              return;
            } catch (e) {
              debugPrint('Error initializing with audioplayers: $e');
            }
          }
        }
      }
      
      // Fallback to direct URL handling if download failed
      if (_effectiveAudioUrl!.startsWith('/')) {
        // Local file - use flutter_sound for WAV, AudioPlayer for others
        if (_effectiveAudioUrl!.toLowerCase().endsWith('.wav')) {
          try {
            await _initializeWithFlutterSound();
          } catch (e) {
            debugPrint('Error initializing local WAV: $e');
            await _initializeWithAudioplayers();
          }
        } else {
          await _initializeWithAudioplayers();
        }
      } else {
        // Remote URL - try AudioPlayer first as it's more reliable for streaming
        try {
          await _initializeWithAudioplayers();
        } catch (e) {
          debugPrint('Error initializing with AudioPlayer: $e');
          await _initializeWithFlutterSound();
        }
      }
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      setState(() {
        _hasError = true;
        _isInitialized = false;
      });
      _showErrorMessage('Failed to load audio');
    }
  }

  Future<void> _initializeWithFlutterSound() async {
    _flutterSoundPlayer = flutter_sound.FlutterSoundPlayer();
    _usingFlutterSound = true;
    _usingJustAudio = false;
    
    try {
      await _flutterSoundPlayer!.openPlayer();
      
      // Set up completion callback with longer timeout
      _flutterSoundPlayer!.setSubscriptionDuration(const Duration(milliseconds: 200));
      _flutterSoundPlayer!.onProgress!.listen((event) {
        // Only trigger completion if we're very close to the end
        if (event.duration.inMilliseconds > 0 && 
            event.position.inMilliseconds >= (event.duration.inMilliseconds - 200)) {
          _safeSetState(() => _playerState = PlayerState.stopped);
          _audioManager.setCurrentlyPlaying(null);
        }
      });
    } catch (e) {
      debugPrint('FlutterSound player initialization failed: $e');
      _usingFlutterSound = false;
      rethrow;
    }
  }

  Future<void> _initializeWithJustAudio() async {
    _justAudioPlayer = just_audio.AudioPlayer();
    _usingJustAudio = true;
    _usingFlutterSound = false;
    
    try {
      // For local files
      if (_effectiveAudioUrl!.startsWith('/')) {
        await _justAudioPlayer!.setFilePath(_effectiveAudioUrl!);
      } 
      // For remote URLs
      else if (_effectiveAudioUrl!.startsWith('http')) {
        // Always try to download first for better compatibility
        final localPath = await _downloadAndCacheAudio(_effectiveAudioUrl!);
        if (localPath != null) {
          await _justAudioPlayer!.setFilePath(localPath);
        } else {
          await _justAudioPlayer!.setUrl(_effectiveAudioUrl!);
        }
      }
      
      _justAudioPlayerStatusSubscription = _justAudioPlayer!.playerStateStream.listen((state) {
        if (_isDisposed) return;
        
        if (state.processingState == just_audio.ProcessingState.completed) {
          _safeSetState(() => _playerState = PlayerState.stopped);
          _audioManager.setCurrentlyPlaying(null);
        } else if (state.playing) {
          _safeSetState(() => _playerState = PlayerState.playing);
        } else {
          _safeSetState(() => _playerState = PlayerState.paused);
        }
      });
    } catch (e) {
      debugPrint('JustAudio initialization failed: $e');
      _usingJustAudio = false;
      rethrow; // Rethrow to try audioplayers
    }
  }
  
  Future<void> _initializeWithAudioplayers() async {
    _audioPlayer = AudioPlayer();
    _usingJustAudio = false;
    _usingFlutterSound = false;
    
    await _audioPlayer?.setReleaseMode(ReleaseMode.stop);
    
    // For local files
    if (_effectiveAudioUrl!.startsWith('/')) {
      await _audioPlayer?.setSourceDeviceFile(_effectiveAudioUrl!);
    } 
    // For remote URLs
    else if (_effectiveAudioUrl!.startsWith('http')) {
      // Try direct URL first
      await _audioPlayer?.setSourceUrl(_effectiveAudioUrl!);
    } else {
      throw Exception('Invalid audio URL format');
    }
    
    _initStreams();
  }

  Future<void> _setAudioSource() async {
    if (_isDisposed) return;
    
    if (_effectiveAudioUrl == null) {
      throw Exception('No valid audio source available');
    }
    
    if (_usingFlutterSound) {
      // FlutterSound handles this differently - nothing needed here
      // as playback starts directly
    } else if (_usingJustAudio) {
      if (_justAudioPlayer?.processingState == just_audio.ProcessingState.idle) {
        // For local files
        if (_effectiveAudioUrl!.startsWith('/')) {
          await _justAudioPlayer!.setFilePath(_effectiveAudioUrl!);
        } 
        // For remote URLs
        else if (_effectiveAudioUrl!.startsWith('http')) {
          final localPath = await _downloadAndCacheAudio(_effectiveAudioUrl!);
          if (localPath != null) {
            await _justAudioPlayer!.setFilePath(localPath);
    } else {
            await _justAudioPlayer!.setUrl(_effectiveAudioUrl!);
          }
        }
      }
    } else {
      // For local files
      if (_effectiveAudioUrl!.startsWith('/')) {
        await _audioPlayer?.setSourceDeviceFile(_effectiveAudioUrl!);
      } 
      // For remote URLs
      else if (_effectiveAudioUrl!.startsWith('http')) {
        // Try direct URL first
        await _audioPlayer?.setSourceUrl(_effectiveAudioUrl!);
      } else {
        throw Exception('Invalid audio URL format');
      }
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
        debugPrint('Pausing playback');
        await AudioPlayerService.stopAudio();
        _safeSetState(() => _playerState = PlayerState.stopped);
        _audioManager.setCurrentlyPlaying(null);
      } else {
        debugPrint('Starting playback using URL: $_effectiveAudioUrl');
        
        if (_effectiveAudioUrl == null) {
          _showErrorMessage('No audio source available');
          return;
        }
        
        // For online URLs, try downloading first
        if (_effectiveAudioUrl!.startsWith('http')) {
          _safeSetState(() => _isLoading = true);
          final localPath = await AudioPlayerService.downloadAndCacheAudio(_effectiveAudioUrl!);
          _safeSetState(() => _isLoading = false);
          
          if (localPath != null) {
            debugPrint('Downloaded audio to: $localPath');
            _effectiveAudioUrl = localPath;
          }
        }
        
        _audioManager.setCurrentlyPlaying(widget.contentId);
        
        // Play using AudioPlayerService
        final success = await AudioPlayerService.playAudio(_effectiveAudioUrl!, onComplete: () {
          _safeSetState(() => _playerState = PlayerState.stopped);
          _audioManager.setCurrentlyPlaying(null);
        });
        
        if (success) {
          _safeSetState(() => _playerState = PlayerState.playing);
        } else {
          debugPrint('Error playing with AudioPlayerService');
          _showErrorMessage('Error playing audio');
        }
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
    _justAudioPlayerStatusSubscription?.cancel();
    
    if (_usingFlutterSound) {
      await _flutterSoundPlayer?.stopPlayer();
    } else if (_usingJustAudio) {
      await _justAudioPlayer?.stop();
    } else {
    await _audioPlayer?.stop();
    }
    
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
    // Show blue button if we have audio (_hasAudio now includes widget.isSaved)
    if (_hasAudio) {
      return _buildPlayPauseButton(Icons.play_arrow, Colors.blue);
    } else {
      // No audio - gray button
      return Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        color: Colors.grey[400],
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: widget.size * 0.75,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPlayPauseButton(IconData icon, Color color) {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: color,
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
              _playerState == PlayerState.playing ? Icons.pause : icon,
              color: Colors.white,
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
    _justAudioPlayer?.dispose();
    if (_flutterSoundPlayer != null && _flutterSoundPlayer!.isOpen()) {
      _flutterSoundPlayer?.closePlayer();
    }
    _audioPlayer = null;
    _justAudioPlayer = null;
    _flutterSoundPlayer = null;
    super.dispose();
  }
}