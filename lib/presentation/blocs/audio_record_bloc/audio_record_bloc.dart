import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meta/meta.dart';

part 'audio_record_event.dart';
part 'audio_record_state.dart';

final Logger _logger = Logger();

class AudioRecordBloc extends Bloc<AudioRecordEvent, AudioRecordState> {
  late final FlutterSoundRecorder _recorder;
  late final FlutterSoundPlayer _player;
  String? _recordingPath;
  final Codec _codec = Codec.aacADTS; // Consistent codec across recording and playback
  bool _playerInitialized = false;
  Timer? _waveformTimer;
  List<double> _waveformData = [];
  static const int _maxWaveformPoints = 100;

  AudioRecordBloc() 
      : super(AudioRecordInitial()) {
    // Initialize without the logLevel parameter that's causing issues
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    
    on<StartRecording>(_onStartRecording);
    on<PauseRecording>(_onPauseRecording);
    on<ResumeRecording>(_onResumeRecording);
    on<StopRecording>(_onStopRecording);
    on<PlayRecording>(_onPlayRecording);
    on<PlayLocalFile>(_onPlayLocalFile);
    on<PlayRemoteAudio>(_onPlayRemoteAudio);
    on<PausePlayback>(_onPausePlayback);
    on<ResetRecording>(_onResetRecording);
    on<ResetToInitialState>(_onResetToInitialState);
    
    // Always initialize immediately to ensure we're ready for playback
    _forceInitializePlayer();
    _initRecorder();
  }
  
  Future<void> _initRecorder() async {
    try {
      // Initialize the recorder
      await _recorder.openRecorder();
      _logger.i("Recorder opened successfully");
    } catch (e) {
      _logger.i("Error opening recorder: $e (continuing anyway)");
    }
  }

  Future<void> _initPlayer() async {
    try {
      // Don't check isOpen first, just try to open directly
      await _player.openPlayer();
      _playerInitialized = true;
      _logger.i("Player initialized successfully");
    } catch (e) {
      _logger.i("Error initializing player: $e");
    }
  }
  
  // Force reinitialization of player
  Future<void> _forceInitializePlayer() async {
    try {
      // First try to close the player if it's open
      try {
        await _player.closePlayer();
        _logger.i("Closed player for reinitialization");
      } catch (e) {
        _logger.i("Error closing player (might not be open): $e");
      }
      
      // Add small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Then reopen it
      await _player.openPlayer();
      _playerInitialized = true;
      _logger.i("Player force reinitialized successfully");
    } catch (e) {
      _logger.i("Error during force reinitialization: $e");
      _playerInitialized = false;
    }
  }

  Future<void> _onStartRecording(
      StartRecording event, Emitter<AudioRecordState> emit) async {
    try {
      // Request microphone permission
      if (await Permission.microphone.request().isGranted) {
        // Get directory for recording
        final directory = await getApplicationDocumentsDirectory();
        // Use aac extension to match the codec
        _recordingPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
        _logger.i("Will record to path: $_recordingPath");
        
        // Start recording with AAC codec
        await _recorder.startRecorder(
          toFile: _recordingPath,
          codec: _codec, // Use the class-level codec variable
          sampleRate: 44100,
        );

        // Start waveform data collection
        _startWaveformCollection(emit);
        
        emit(AudioRecording());
        _logger.i("Recording started");
      } else {
        _logger.i("Microphone permission denied");
        emit(AudioRecordInitial());
      }
    } catch (e) {
      _logger.i("Error starting recording: $e");
      emit(AudioRecordInitial());
    }
  }

  Future<void> _onPauseRecording(
      PauseRecording event, Emitter<AudioRecordState> emit) async {
    try {
      await _recorder.pauseRecorder();
      emit(AudioRecordingPaused());
    } catch (e) {
      emit(AudioRecordInitial());
    }
  }

  Future<void> _onResumeRecording(
      ResumeRecording event, Emitter<AudioRecordState> emit) async {
    try {
      await _recorder.resumeRecorder();
      emit(AudioRecording());
    } catch (e) {
      emit(AudioRecordInitial());
    }
  }

  Future<void> _onStopRecording(
      StopRecording event, Emitter<AudioRecordState> emit) async {
    try {
      // Identical to your original, simple approach
      _recordingPath = await _recorder.stopRecorder();
      await _recorder.closeRecorder();
      
      if (_recordingPath != null) {
        // Simple state emission, no extra checks
        emit(AudioRecordingStopped(
          _recordingPath!,
          base64Data: '',  // This will be set later
          serverUrl: null,
        ));
      }
    } catch (e) {
      emit(AudioRecordInitial());
    }
  }

  Future<void> _onPlayRecording(PlayRecording event, Emitter<AudioRecordState> emit) async {
    if (_recordingPath != null) {
      try {
        _logger.i("Playing recording from path: $_recordingPath");
        
        // If we're already in the AudioRecordingStopped state
        // Immediately emit AudioPlaying state to update UI
        if (state is AudioRecordingStopped) {
          emit(AudioPlaying(_recordingPath!));
        }
        
        // Check if this is a remote URL
        if (_recordingPath!.startsWith('http')) {
          add(PlayRemoteAudio(_recordingPath!));
          return;
        }
        
        // For local files
        final file = File(_recordingPath!);
        if (await file.exists()) {
          // Ensure we emit the playing state
          emit(AudioPlaying(_recordingPath!));
          
          // Ensure player is open
          if (!_player.isOpen()) {
            await _player.openPlayer();
          }
          
          // Try with original codec
          try {
            await _player.startPlayer(
              fromURI: _recordingPath!,
              codec: Codec.pcm16WAV,
              whenFinished: () {
                add(PausePlayback());
              },
            );
          } catch (codecError) {
            // Try alternative codec
            _logger.i("First codec failed: $codecError, trying alternative...");
            await _player.startPlayer(
              fromURI: _recordingPath!,
              codec: Codec.aacADTS,
              whenFinished: () {
                add(PausePlayback());
              },
            );
          }
        } else {
          _logger.i("Local file not found: $_recordingPath");
          emit(AudioRecordError("Audio file not found"));
        }
      } catch (e) {
        _logger.i("Error playing recording: $e");
        emit(AudioRecordError("Error playing audio: $e"));
      }
    }
  }

  Future<void> _onPausePlayback(
      PausePlayback event, Emitter<AudioRecordState> emit) async {
    if (_recordingPath != null) {
      try {
        await _player.pausePlayer();
        emit(AudioPlayingPaused(_recordingPath!));
      } catch (e) {
        emit(AudioRecordInitial());
      }
    }
  }

  Future<void> _onResetRecording(
      ResetRecording event, Emitter<AudioRecordState> emit) async {
    try {
      // Stop recording if it's active
      try {
        if (_recorder.isRecording) {
          await _recorder.stopRecorder();
        }
        await _recorder.closeRecorder();
      } catch (recorderError) {
        _logger.i("Error closing recorder: $recorderError");
      }
      
      // Stop playback if it's active - don't check isOpen() first
      try {
        await _player.stopPlayer();
        await _player.closePlayer();
        // Re-initialize player
        await _initPlayer();
      } catch (playerError) {
        _logger.i("Error closing player: $playerError");
      }

      // Re-initialize the recorder so it's ready for next recording
      try {
        await _initRecorder();
      } catch (recorderError) {
        _logger.i("Error re-initializing recorder: $recorderError");
      }

      // Delete the recording file if it exists
      if (_recordingPath != null) {
        try {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (fileError) {
          _logger.i("Error deleting file: $fileError");
        }
      }

      _recordingPath = null;
      emit(AudioRecordInitial());
    } catch (e) {
      _logger.i("Error in reset: $e");
      emit(AudioRecordInitial());
    }
  }
  
  Future<void> _onPlayLocalFile(PlayLocalFile event, Emitter<AudioRecordState> emit) async {
    try {
      _logger.i("\n===== PLAYING LOCAL AUDIO =====");
      _logger.i("File path: ${event.path}");
      
      // First check if we need to re-initialize the player (critical)
      if (!_playerInitialized) {
        _logger.i("Player not initialized, initializing now");
        await _initPlayer();
      }
      
      // Store the path for future use
      _recordingPath = event.path;
      
      // Check if file exists and has content
      final file = File(event.path);
      if (await file.exists()) {
        final fileSize = await file.length();
        _logger.i("Local file exists and size is: $fileSize bytes");
        
        if (fileSize == 0) {
          _logger.i("ERROR: File exists but is empty (0 bytes)");
          emit(AudioRecordError("Audio file is empty"));
          return;
        }
        
        // First emit state to update UI
        emit(AudioPlaying(event.path));
        
        // Determine the codec based on file extension
        Codec codec = Codec.aacADTS; // Default to AAC as safer default
        final lowerPath = event.path.toLowerCase();
        if (lowerPath.endsWith('.aac')) {
          codec = Codec.aacADTS;
        } else if (lowerPath.endsWith('.wav')) {
          codec = Codec.pcm16WAV;
        } else if (lowerPath.endsWith('.mp3')) {
          codec = Codec.mp3;
        }
        
        _logger.i("Starting playback with codec: ${codec.name}");
        
        try {
          // Make sure any previous playback is stopped
          try {
            if (_player.isPlaying) {
              await _player.stopPlayer();
              await Future.delayed(const Duration(milliseconds: 200));
            }
          } catch (e) {
            _logger.i("Error stopping previous playback: $e");
          }
          
          // Reopen player if needed (safeguard)
          if (!_player.isOpen()) {
            _logger.i("Player is not open, reopening");
            await _player.openPlayer();
          }
          
          _logger.i("Starting player with codec ${codec.name}");
          // Try with explicit codec first as it's more reliable
          await _player.startPlayer(
            fromURI: event.path,
            codec: codec,
            whenFinished: () {
              _logger.i("Playback finished callback triggered");
              add(PausePlayback());
            },
          );
          
          _logger.i("Player started successfully with codec");
        } catch (e) {
          _logger.i("Error with codec-specific playback attempt: $e");
          
          try {
            // Try without specifying codec
            _logger.i("Trying without specific codec");
            await _player.startPlayer(
              fromURI: event.path,
              whenFinished: () {
                add(PausePlayback());
              },
            );
            _logger.i("Player started successfully without codec");
          } catch (e2) {
            _logger.i("Error with second playback attempt: $e2");
            
            // Last resort: try reopening player and trying again
            try {
              _logger.i("Last resort: reopening player and trying again");
              await _player.closePlayer();
              await Future.delayed(const Duration(milliseconds: 300));
              await _player.openPlayer();
              
              await _player.startPlayer(
                fromURI: event.path,
                whenFinished: () {
                  add(PausePlayback());
                },
              );
              _logger.i("Last resort succeeded");
            } catch (e3) {
              _logger.i("All playback attempts failed: $e3");
              emit(AudioRecordError("Failed to play audio after multiple attempts"));
            }
          }
        }
      } else {
        _logger.i("ERROR: Local file not found: ${event.path}");
        
        // Try to find the file with the same name in common audio directories
        try {
          _logger.i("Attempting to find file by name");
          final fileName = event.path.split('/').last;
          
          // Try common directories
          final appDocDir = await getApplicationDocumentsDirectory();
          final directories = [
            "${appDocDir.path}/recorded_audio",
            "${appDocDir.path}/audio_files",
            "${appDocDir.path}/app_flutter/audio_files",
            (appDocDir.path)
          ];
          
          bool fileFound = false;
          for (String directory in directories) {
            final dir = Directory(directory);
            if (await dir.exists()) {
              _logger.i("Checking directory: $directory");
              
              try {
                final files = await dir.list().toList();
                for (var fileEntity in files) {
                  if (fileEntity is File && fileEntity.path.contains(fileName)) {
                    _logger.i("Found similar file: ${fileEntity.path}");
                    
                    // Try playing this file instead
                    add(PlayLocalFile(fileEntity.path));
                    fileFound = true;
                    break;
                  }
                }
              } catch (e) {
                _logger.i("Error listing directory $directory: $e");
              }
              
              if (fileFound) break;
            }
          }
          
          if (!fileFound) {
            emit(AudioRecordError("Audio file not found"));
          }
        } catch (e) {
          _logger.i("Error searching for alternative file: $e");
          emit(AudioRecordError("Audio file not found"));
        }
      }
    } catch (e) {
      _logger.i("ERROR playing local file: $e");
      _logger.i("Stack trace: ${StackTrace.current}");
      emit(AudioRecordError("Error playing audio: $e"));
    }
  }

  Future<void> _onPlayRemoteAudio(PlayRemoteAudio event, Emitter<AudioRecordState> emit) async {
    try {
      _logger.i("\n===== PLAYING REMOTE AUDIO =====");
      _logger.i("URL: ${event.audioUrl}");
      
      // First emit state to update UI
      emit(AudioPlaying(event.audioUrl));
      
      // Ensure player is initialized
      if (!_playerInitialized) {
        await _initPlayer();
      }
      
      try {
        // Try playing from URL directly
        _logger.i("Playing remote audio from URL");
        await _player.startPlayer(
          fromURI: event.audioUrl,
          whenFinished: () {
            _logger.i("Playback finished");
            add(PausePlayback());
          },
        );
        _logger.i("Remote playback started successfully");
      } catch (e) {
        _logger.i("Error playing remote audio: $e");
        
        // Try downloading and playing locally
        _logger.i("Attempting to download and play locally");
        try {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.aac');
          
          // Download using dart:io HttpClient for better control
          final httpClient = HttpClient();
          final request = await httpClient.getUrl(Uri.parse(event.audioUrl));
          final response = await request.close();
          
          if (response.statusCode == 200) {
            _logger.i("Download started...");
            final sink = tempFile.openWrite();
            await response.pipe(sink);
            await sink.flush();
            await sink.close();
            _logger.i("Downloaded to ${tempFile.path}, size: ${await tempFile.length()} bytes");
            
            // Now play the downloaded file
            await _player.startPlayer(
              fromURI: tempFile.path,
              codec: Codec.aacADTS,
              whenFinished: () {
                add(PausePlayback());
              },
            );
            
            // Store path for future use
            _recordingPath = tempFile.path;
          } else {
            throw Exception("Failed to download. Status code: ${response.statusCode}");
          }
        } catch (downloadError) {
          _logger.i("Download and play failed: $downloadError");
          emit(AudioRecordError("Failed to play remote audio: $downloadError"));
        }
      }
    } catch (e) {
      _logger.i("ERROR in _onPlayRemoteAudio: $e");
      emit(AudioRecordError("Error playing remote audio: $e"));
    }
  }

  Future<void> _onResetToInitialState(
      ResetToInitialState event, Emitter<AudioRecordState> emit) async {
    try {
      // Stop recording if it's active
      try {
        if (_recorder.isRecording) {
          await _recorder.stopRecorder();
        }
        await _recorder.closeRecorder();
      } catch (recorderError) {
        _logger.i("Error closing recorder: $recorderError");
      }
      
      // Stop playback if it's active
      try {
        await _player.stopPlayer();
        await _player.closePlayer();
        // Re-initialize player
        await _initPlayer();
      } catch (playerError) {
        _logger.i("Error closing player: $playerError");
      }

      // Add a delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 300));

      // Force re-initialize the recorder with better error handling
      bool recorderReady = false;
      int retryCount = 0;
      while (!recorderReady && retryCount < 3) {
        try {
          await _recorder.openRecorder();
          recorderReady = true;
          _logger.i("Recorder re-initialized successfully (attempt ${retryCount + 1})");
        } catch (recorderError) {
          retryCount++;
          _logger.i("Error re-initializing recorder (attempt $retryCount): $recorderError");
          
          if (retryCount < 3) {
            // Wait a bit before retrying
            await Future.delayed(Duration(milliseconds: 200 * retryCount));
          }
        }
      }
      
      if (!recorderReady) {
        _logger.i("Failed to re-initialize recorder after 3 attempts");
        // Try one more time with a fresh FlutterSoundRecorder instance
        try {
          _recorder = FlutterSoundRecorder();
          await _recorder.openRecorder();
          _logger.i("Recorder re-initialized with new instance");
        } catch (e) {
          _logger.i("Even fresh recorder instance failed: $e");
        }
      }

      // DO NOT delete the recording file - just clear the path reference
      _recordingPath = null;
      emit(AudioRecordInitial());
    } catch (e) {
      _logger.i("Error in reset to initial: $e");
      emit(AudioRecordInitial());
    }
  }

  void _startWaveformCollection(Emitter<AudioRecordState> emit) {
    _waveformData = [];
    _waveformTimer?.cancel();
    
    // Generate simulated waveform data based on time
    int tickCount = 0;
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_recorder.isRecording) {
        // Create a smooth wave pattern using sine function
        final double normalizedAmplitude = (math.sin(tickCount * 0.2) + 1) / 2;
        tickCount++;
        
        _waveformData.add(normalizedAmplitude);
        if (_waveformData.length > _maxWaveformPoints) {
          _waveformData.removeAt(0);
        }
        
        emit(AudioRecording(waveformData: List.from(_waveformData)));
      }
    });
  }

  void _stopWaveformCollection() {
    _waveformTimer?.cancel();
    _waveformTimer = null;
  }

  @override
  Future<void> close() async {
    _stopWaveformCollection();
    try {
      // Close recorder without checking isOpen
      try {
        await _recorder.closeRecorder();
      } catch (e) {
        _logger.i("Error closing recorder: $e");
      }
      
      // Close player without checking isOpen
      try {
        await _player.closePlayer();
      } catch (e) {
        _logger.i("Error closing player: $e");
      }
    } catch (e) {
      _logger.i("Error in close: $e");
    }
    return super.close();
  }

  @override
  Stream<AudioRecordState> mapEventToState(AudioRecordEvent event) async* {
    // Handle PlayLocalFile event specifically for saved files
    if (event is PlayLocalFile) {
      _logger.i("🎵 AudioRecordBloc: PlayLocalFile event received for path: ${event.path}");
      
      // First stop any ongoing playback
      if (_player.isPlaying) {
        _logger.i("🎵 AudioRecordBloc: Stopping current playback before starting new one");
        try {
          await _player.stopPlayer();
          await Future.delayed(const Duration(milliseconds: 500)); // Wait to ensure player is stopped
        } catch (e) {
          _logger.i("🎵 AudioRecordBloc: Error stopping player: $e");
        }
      }
      
      try {
        // Verify file exists and has content
        final file = File(event.path);
        if (!await file.exists()) {
          _logger.i("🎵 AudioRecordBloc: File doesn't exist: ${event.path}");
          yield AudioRecordError("File doesn't exist");
          return;
        }
        
        final fileSize = await file.length();
        _logger.i("🎵 AudioRecordBloc: File size: $fileSize bytes");
        
        if (fileSize < 100) {
          _logger.i("🎵 AudioRecordBloc: File too small ($fileSize bytes)");
          yield AudioRecordError("Audio file appears to be corrupted");
          return;
        }
        
        // Make sure the player is open
        if (!_player.isOpen()) {
          _logger.i("🎵 AudioRecordBloc: Player not open, opening now");
          await _player.openPlayer();
          await Future.delayed(const Duration(milliseconds: 300)); // Brief delay after opening
        }
        
        // Determine codec based on file extension
        Codec codec;
        if (event.path.toLowerCase().endsWith('.mp3')) {
          codec = Codec.mp3;
          _logger.i("🎵 AudioRecordBloc: Using MP3 codec for local file");
        } else if (event.path.toLowerCase().endsWith('.wav')) {
          codec = Codec.pcm16WAV;
          _logger.i("🎵 AudioRecordBloc: Using WAV codec for local file");
        } else {
          // Default to MP3 for other extensions
          codec = Codec.mp3;
          _logger.i("🎵 AudioRecordBloc: Using default MP3 codec for unknown file type");
        }
        
        // Set up UI state first 
        yield AudioPlaying(event.path);
        
        _logger.i("🎵 AudioRecordBloc: Starting player with codec ${codec.name}");
        // Try with explicit codec first
        try {
          // Make sure any previous playback is stopped
          try {
            if (_player.isPlaying) {
              await _player.stopPlayer();
              await Future.delayed(const Duration(milliseconds: 200));
            }
          } catch (e) {
            _logger.i("Error stopping previous playback: $e");
          }
          
          // Reopen player if needed (safeguard)
          if (!_player.isOpen()) {
            _logger.i("Player is not open, reopening");
            await _player.openPlayer();
          }
          
          _logger.i("Starting player with codec ${codec.name}");
          // Try with explicit codec first as it's more reliable
          await _player.startPlayer(
            fromURI: event.path,
            codec: codec,
            whenFinished: () {
              _logger.i("Playback finished callback triggered");
              add(PausePlayback());
            },
          );
          
          _logger.i("Player started successfully with codec");
        } catch (e) {
          _logger.i("🎵 AudioRecordBloc: Error playing with codec: $e");
          
          try {
            // If first attempt failed, try reopening and using auto-detection
            _logger.i("🎵 AudioRecordBloc: Trying again with reopened player");
            await _player.closePlayer();
            await Future.delayed(const Duration(milliseconds: 300));
            await _player.openPlayer();
            
            // Try one more time with auto-detection
            await _player.startPlayer(
              fromURI: event.path,
              whenFinished: () {
                _logger.i("🎵 AudioRecordBloc: Playback finished (auto-detection)");
                add(PausePlayback());
              },
            );
            _logger.i("🎵 AudioRecordBloc: Player started successfully with auto-detection");
          } catch (e2) {
            _logger.i("🎵 AudioRecordBloc: Second attempt failed: $e2");
            yield AudioRecordError("Error playing audio: ${e2.toString().substring(0, math.min(e.toString().length, 100))}");
          }
        }
      } catch (e) {
        _logger.i("🎵 AudioRecordBloc: Error playing local file: $e");
        yield AudioRecordError("Error playing audio");
      }
    }
  }
}