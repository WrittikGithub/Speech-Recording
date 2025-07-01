import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  static FlutterSoundPlayer? _player;
  static bool _isPlaying = false;
  static String? _currentPlayingPath;
  static double _currentSpeed = 1.0;
  static bool _androidWorkaround = false;
  
  factory AudioPlayerService() {
    return _instance;
  }
  
  AudioPlayerService._internal() {
    _initializePlayer();
  }
  
  static Future<void> _initializePlayer() async {
    try {
      // Always close any existing player first to avoid conflicts
      if (_player != null) {
        try {
          if (_player!.isOpen()) {
            await _player!.stopPlayer();
            await _player!.closePlayer();
          }
        } catch (e) {
          print("🎧 AudioPlayerService: Error closing existing player: $e");
        }
        _player = null;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Create a new instance
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      print("🎧 AudioPlayerService: Player initialized");
    } catch (e) {
      print("🎧 AudioPlayerService: Error initializing player: $e");
      _player = null;
    }
  }
  
  static Future<bool> playAudio(String path, {VoidCallback? onComplete}) async {
    print("🎧 AudioPlayerService: Attempting to play audio from $path");
    
    // Ensure path is properly formatted
    if (path.startsWith('file://')) {
      path = path.substring(7);
      print("🎧 AudioPlayerService: Removed file:// prefix, now: $path");
    }
    
    // Validate file
    if (!await _validateAudioFile(path)) {
      print("🎧 AudioPlayerService: Invalid audio file: $path");
      return false;
    }
    
    // CRITICAL: On Android, restart the player completely for each play
    if (Platform.isAndroid) {
      print("🎧 AudioPlayerService: Android detected, using complete player reset");
      await _initializePlayer();
      _androidWorkaround = true;
    } else {
      // For other platforms, just ensure it's initialized
      if (_player == null || !_player!.isOpen()) {
        await _initializePlayer();
      }
    }
    
    if (_player == null) {
      print("🎧 AudioPlayerService: Failed to initialize player");
      return false;
    }
    
    // Stop any current playback
    if (_isPlaying) {
      await stopAudio();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // Determine codec based on file extension
    Codec codec;
    if (path.toLowerCase().endsWith('.mp3')) {
      codec = Codec.mp3;
      print("🎧 AudioPlayerService: Using MP3 codec");
    } else if (path.toLowerCase().endsWith('.wav')) {
      codec = Codec.pcm16WAV;
      print("🎧 AudioPlayerService: Using WAV codec");
    } else if (path.toLowerCase().endsWith('.aac')) {
      codec = Codec.aacADTS;
      print("🎧 AudioPlayerService: Using AAC codec");
    } else {
      // Default to MP3 
      codec = Codec.mp3;
      print("🎧 AudioPlayerService: Using default MP3 codec for unknown file type");
    }
    
    try {
      print("🎧 AudioPlayerService: Starting playback with codec ${codec.name}");
      await _player!.startPlayer(
        fromURI: path,
        codec: codec,
        whenFinished: () {
          print("🎧 AudioPlayerService: Playback completed");
          _isPlaying = false;
          _currentPlayingPath = null;
          if (onComplete != null) onComplete();
        },
      );
      await setSpeed(_currentSpeed);
      
      _isPlaying = true;
      _currentPlayingPath = path;
      print("🎧 AudioPlayerService: Playback started successfully");
      return true;
    } catch (e) {
      print("🎧 AudioPlayerService: Error playing audio (first attempt): $e");
      
      // Try again with a fresh player instance and different approach
      try {
        print("🎧 AudioPlayerService: Reinitializing player for second attempt");
        await _initializePlayer();
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try without specifying codec
        print("🎧 AudioPlayerService: Starting player without codec specification");
        await _player!.startPlayer(
          fromURI: path,
          whenFinished: () {
            print("🎧 AudioPlayerService: Playback completed (second attempt)");
            _isPlaying = false;
            _currentPlayingPath = null;
            if (onComplete != null) onComplete();
          },
        );
        await setSpeed(_currentSpeed);
        
        _isPlaying = true;
        _currentPlayingPath = path;
        print("🎧 AudioPlayerService: Playback started successfully (second attempt)");
        return true;
      } catch (e2) {
        print("🎧 AudioPlayerService: Error playing audio (second attempt): $e2");
        
        // Final attempt with buffer adjustment
        try {
          print("🎧 AudioPlayerService: Final attempt with buffer adjustment");
          // Give the system time to release audio resources
          await Future.delayed(const Duration(milliseconds: 800));
          await _initializePlayer(); 
          
          // Set Android focus manually - no need for explicit audio focus
          if (Platform.isAndroid) {
            print("🎧 AudioPlayerService: Setting up Android focus");
            // We'll just use a longer delay instead of explicit audio focus
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
          await _player!.startPlayer(
            fromURI: path,
            whenFinished: () {
              print("🎧 AudioPlayerService: Playback completed (final attempt)");
              _isPlaying = false;
              _currentPlayingPath = null;
              if (onComplete != null) onComplete();
            },
          );
          await setSpeed(_currentSpeed);
          
          _isPlaying = true;
          _currentPlayingPath = path;
          print("🎧 AudioPlayerService: Playback started successfully (final attempt)");
          return true;
        } catch (e3) {
          print("🎧 AudioPlayerService: All playback attempts failed: $e3");
          return false;
        }
      }
    }
  }
  
  static Future<void> stopAudio() async {
    if (_player != null) {
      try {
        if (_player!.isOpen() && _player!.isPlaying) {
          await _player!.stopPlayer();
          print("🎧 AudioPlayerService: Audio stopped");
        }
        
        // On Android, completely close and reinitialize player
        if (Platform.isAndroid && _androidWorkaround) {
          await _player!.closePlayer();
          _player = null;
          _androidWorkaround = false;
          print("🎧 AudioPlayerService: Android workaround - player closed");
        }
        
        _isPlaying = false;
        _currentPlayingPath = null;
      } catch (e) {
        print("🎧 AudioPlayerService: Error stopping audio: $e");
        // Force reset on error
        await _initializePlayer();
      }
    }
  }
  
  static Future<bool> _validateAudioFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        print("🎧 AudioPlayerService: File does not exist: $path");
        return false;
      }
      
      final fileSize = await file.length();
      print("🎧 AudioPlayerService: File size: $fileSize bytes");
      
      if (fileSize < 100) {
        print("🎧 AudioPlayerService: File too small: $fileSize bytes");
        return false;
      }
      
      try {
        // For wav files, verify they have valid headers by checking first few bytes
        if (path.toLowerCase().endsWith('.wav')) {
          final bytes = await file.openRead(0, 12).toList();
          if (bytes.isEmpty || bytes[0].length < 12) {
            print("🎧 AudioPlayerService: WAV file has invalid header");
            // Try to fix the file
            return await _fixWavFile(path);
          }
        }
      } catch (e) {
        print("🎧 AudioPlayerService: Error checking file header: $e");
      }
      
      return true;
    } catch (e) {
      print("🎧 AudioPlayerService: Error validating file: $e");
      return false;
    }
  }
  
  static Future<bool> _fixWavFile(String path) async {
    try {
      // Create a backup of the original file
      final originalFile = File(path);
      final backupPath = '${path}_backup';
      await originalFile.copy(backupPath);
      
      // Try basic WAV header repair
      final fileSize = await originalFile.length();
      final bytes = List<int>.filled(44, 0); // Standard WAV header size
      
      // RIFF header
      bytes[0] = 82; // 'R'
      bytes[1] = 73; // 'I'
      bytes[2] = 70; // 'F'
      bytes[3] = 70; // 'F'
      
      // File size - 8
      final fileSizeMinus8 = fileSize - 8;
      bytes[4] = fileSizeMinus8 & 0xFF;
      bytes[5] = (fileSizeMinus8 >> 8) & 0xFF;
      bytes[6] = (fileSizeMinus8 >> 16) & 0xFF;
      bytes[7] = (fileSizeMinus8 >> 24) & 0xFF;
      
      // WAVE header
      bytes[8] = 87; // 'W'
      bytes[9] = 65; // 'A'
      bytes[10] = 86; // 'V'
      bytes[11] = 69; // 'E'
      
      // fmt subchunk
      bytes[12] = 102; // 'f'
      bytes[13] = 109; // 'm'
      bytes[14] = 116; // 't'
      bytes[15] = 32; // ' '
      
      // Subchunk1Size (16 for PCM)
      bytes[16] = 16;
      bytes[17] = 0;
      bytes[18] = 0;
      bytes[19] = 0;
      
      // AudioFormat (1 for PCM)
      bytes[20] = 1;
      bytes[21] = 0;
      
      // NumChannels (1 for mono, 2 for stereo)
      bytes[22] = 1;
      bytes[23] = 0;
      
      // SampleRate (44100)
      bytes[24] = 68; // 44100 & 0xFF
      bytes[25] = 172; // (44100 >> 8) & 0xFF
      bytes[26] = 0;
      bytes[27] = 0;
      
      // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
      bytes[28] = 136; // 88200 & 0xFF
      bytes[29] = 88; // (88200 >> 8) & 0xFF
      bytes[30] = 1; // (88200 >> 16) & 0xFF
      bytes[31] = 0;
      
      // BlockAlign (NumChannels * BitsPerSample/8)
      bytes[32] = 2;
      bytes[33] = 0;
      
      // BitsPerSample (16)
      bytes[34] = 16;
      bytes[35] = 0;
      
      // data subchunk
      bytes[36] = 100; // 'd'
      bytes[37] = 97; // 'a'
      bytes[38] = 116; // 't'
      bytes[39] = 97; // 'a'
      
      // Subchunk2Size (data size)
      final dataSize = fileSize - 44;
      bytes[40] = dataSize & 0xFF;
      bytes[41] = (dataSize >> 8) & 0xFF;
      bytes[42] = (dataSize >> 16) & 0xFF;
      bytes[43] = (dataSize >> 24) & 0xFF;
      
      // Create a fixed file with proper header
      final fixedPath = '${path}_fixed.wav';
      final fixedFile = File(fixedPath);
      
      // Write header
      final fixedSink = fixedFile.openWrite();
      fixedSink.add(bytes);
      
      // Append original data, skipping the first 44 bytes (or whatever header was there)
      final originalData = await originalFile.openRead(44).toList();
      for (var chunk in originalData) {
        fixedSink.add(chunk);
      }
      
      await fixedSink.flush();
      await fixedSink.close();
      
      // Replace original with fixed file
      await fixedFile.copy(path);
      await fixedFile.delete();
      
      print("🎧 AudioPlayerService: WAV file fixed");
      return true;
    } catch (e) {
      print("🎧 AudioPlayerService: Error fixing WAV file: $e");
      return false;
    }
  }
  
  static Future<String?> downloadAndCacheAudio(String url) async {
    try {
      print("🎧 AudioPlayerService: Downloading audio from $url");
      
      // Create a unique filename based on URL hash
      final urlHash = url.hashCode.abs();
      String fileName;
      
      if (url.toLowerCase().endsWith('.mp3')) {
        fileName = 'audio_$urlHash.mp3';
      } else if (url.toLowerCase().endsWith('.wav')) {
        fileName = 'audio_$urlHash.wav';
      } else if (url.toLowerCase().endsWith('.aac')) {
        fileName = 'audio_$urlHash.aac';
      } else {
        fileName = 'audio_$urlHash.mp3';
      }
      
      // Create cache directory
      final tempDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${tempDir.path}/audio_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final localPath = '${cacheDir.path}/$fileName';
      
      // Check if file already exists in cache
      final file = File(localPath);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 100) {
          print("🎧 AudioPlayerService: Using cached file: $localPath ($fileSize bytes)");
          return localPath;
        } else {
          // Delete small/corrupted file
          await file.delete();
        }
      }
      
      // Use HttpClient for better streaming support
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        // Stream the response directly to file
        final sink = file.openWrite();
        await response.pipe(sink);
        await sink.flush();
        await sink.close();
        
        final downloadedSize = await file.length();
        
        if (downloadedSize < 100) {
          print("🎧 AudioPlayerService: Downloaded file too small: $downloadedSize bytes");
          await file.delete();
          return null;
        }
        
        print("🎧 AudioPlayerService: Downloaded audio to $localPath ($downloadedSize bytes)");
        return localPath;
      } else {
        print("🎧 AudioPlayerService: Download failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("🎧 AudioPlayerService: Error downloading audio: $e");
      return null;
    }
  }
  
  static Future<void> setSpeed(double speed) async {
    if (_player != null && _player!.isPlaying) {
      try {
        await _player!.setSpeed(speed);
        _currentSpeed = speed;
        print("🎧 AudioPlayerService: Speed set to $speed");
      } catch (e) {
        print("🎧 AudioPlayerService: Error setting speed: $e");
      }
    }
  }
  
  static Future<void> pauseAudio() async {
    if (_player != null && _player!.isPlaying) {
      try {
        await _player!.pausePlayer();
        _isPlaying = false;
        print("🎧 AudioPlayerService: Audio paused");
      } catch (e) {
        print("🎧 AudioPlayerService: Error pausing audio: $e");
      }
    }
  }
  
  static Future<void> resumeAudio() async {
    if (_player != null && !_player!.isPaused) {
      try {
        await _player!.resumePlayer();
        _isPlaying = true;
        print("🎧 AudioPlayerService: Audio resumed");
      } catch (e) {
        print("🎧 AudioPlayerService: Error resuming audio: $e");
      }
    }
  }
  
  static bool get isPlaying => _isPlaying;
  
  static bool get isPaused => _player?.isPaused ?? false;
  
  static Future<void> dispose() async {
    if (_player != null) {
      try {
        if (_player!.isOpen()) {
          await _player!.stopPlayer();
          await _player!.closePlayer();
        }
        _player = null;
        print("🎧 AudioPlayerService: Player disposed");
      } catch (e) {
        print("🎧 AudioPlayerService: Error disposing player: $e");
      }
    }
  }
  
  static Stream<PlaybackDisposition>? get onProgress => _player?.onProgress;
  
  static Future<void> seekTo(Duration position) async {
    if (_player != null) {
      try {
        await _player!.seekToPlayer(position);
        print("🎧 AudioPlayerService: Seeked to ${position.inMilliseconds}ms");
      } catch (e) {
        print("🎧 AudioPlayerService: Error seeking audio: $e");
      }
    }
  }
  
  static String? get currentPlayingPath => _currentPlayingPath;
} 