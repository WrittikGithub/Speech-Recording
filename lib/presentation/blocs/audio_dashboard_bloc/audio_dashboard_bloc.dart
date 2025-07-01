import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdcp_rebuild/core/appconstants.dart';
import 'package:sdcp_rebuild/models/recording_model.dart';
import 'package:sdcp_rebuild/domain/controllers/notification_service.dart';

part 'audio_dashboard_event.dart';
part 'audio_dashboard_state.dart';

const String _tempRecFileName = 'temp_recording.aac';
const String _finalRecFileName = 'temp_recording.wav';
const String _serverRecordingsKey = 'server_recordings_cache';
const String _localRecordingsKey = 'local_recordings_cache';

class AudioDashboardBloc extends Bloc<AudioDashboardEvent, AudioDashboardState> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _dbPeakSubscription;
  final NotificationService _notificationService = NotificationService();
  bool _isInBackground = false;
  Timer? _backgroundTimer;
  int _backgroundRecordingDuration = 0;

  String? _currentRecordingPath;
  String? _currentPlayingPathForBloc;
  Duration? _lastKnownPositionForBloc;
  Duration? _currentTotalDurationForBloc;
  Timer? _durationTimer;
  int _currentDurationInSeconds = 0;
  List<Recording> _allRecordings = [];
  bool _isPaused = false;
  StreamSubscription<PlaybackDisposition>? _playbackSubscription;
  double _currentSpeed = 1.0;

  String? get currentRecordingPath => _currentRecordingPath;

  AudioDashboardBloc() : super(AudioDashboardInitial()) {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initializeBloc();

    on<LoadRecordingsEvent>(_onLoadRecordings);
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<PauseRecordingEvent>(_onPauseRecording);
    on<ResumeRecordingEvent>(_onResumeRecording);
    on<PlayRecordingEvent>(_onPlayRecording);
    on<PlaySavedRecordingEvent>(_onPlaySavedRecording);
    on<PausePlaybackEvent>(_onPausePlaybackEvent);
    on<ResumePlaybackEvent>(_onResumePlaybackEvent);
    on<StopPlaybackEvent>(_onStopPlaybackEvent);
    on<UpdatePlaybackProgressEvent>(_onUpdatePlaybackProgress);
    on<UpdateRecordingDurationEvent>(_onUpdateRecordingDuration);
    on<ResetRecordingEvent>(_onResetRecording);
    on<DeleteRecordingEvent>(_onDeleteRecording);
    on<DeleteServerRecordingEvent>(_onDeleteServerRecording);
    on<UpdateServerRecordingTitleEvent>(_onUpdateServerRecordingTitle);
    on<SubmitRecordingEvent>(_onSubmitRecording);
    on<LoadServerRecordingsEvent>(_onLoadServerRecordings);
    on<_UpdateDurationEvent>(_onUpdateDuration);
    on<_PlaybackCompletedEvent>(_onPlaybackCompleted);
    on<SetPlaybackSpeedEvent>(_onSetPlaybackSpeed);
    on<SeekPlaybackEvent>(_onSeekPlayback);
  }

  @override
  Future<void> close() async {
    try {
      // Stop any ongoing playback first
      if (_player != null && (_player!.isPlaying || _player!.isPaused)) {
        await _player!.stopPlayer();
      }
      
      // Stop any ongoing recording
      if (_recorder != null && (_recorder!.isRecording || _recorder!.isPaused)) {
        await _recorder!.stopRecorder();
      }
      
      // Cancel all subscriptions
      _recorderSubscription?.cancel();
      _playerSubscription?.cancel();
      _playbackSubscription?.cancel();
      _durationTimer?.cancel();
      _backgroundTimer?.cancel();
      
      // Close audio services
      await _recorder?.closeRecorder();
      await _player?.closePlayer();
      
      // Stop notification service
      _notificationService.stopNotificationService();
    } catch (e) {
      print("Error during BLoC cleanup: $e");
    }
    
    return super.close();
  }

  Future<void> _initializeBloc() async {
    try {
      await _recorder!.openRecorder();
      await _player!.openPlayer();
      await _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
      add(LoadRecordingsEvent());
    } catch (e) {
      emit(AudioDashboardError("Failed to initialize audio services: ${e.toString()}"));
    }
  }

  Future<void> _onStartRecording(StartRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        emit(const AudioDashboardError("Microphone permission not granted."));
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      _currentRecordingPath = p.join(directory.path, _tempRecFileName);
      _currentDurationInSeconds = 0;
      _backgroundRecordingDuration = 0;

      await _recorder!.startRecorder(
        toFile: _currentRecordingPath!,
        codec: Codec.aacMP4,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
        audioSource: AudioSource.microphone,
      );

      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _currentDurationInSeconds++;
        add(UpdateRecordingDurationEvent(_currentDurationInSeconds));
      });

      // Show notification if in background
      if (_isInBackground && event.context != null) {
        _showBackgroundNotification(event.context!);
      }

      emit(RecordingInProgress(_currentDurationInSeconds));
    } catch (e) {
      emit(AudioDashboardError("Failed to start recording: ${e.toString()}"));
    }
  }

  void _onUpdateDuration(_UpdateDurationEvent event, Emitter<AudioDashboardState> emit) {
    emit(RecordingInProgress(event.duration));
  }

  Future<void> _onPauseRecording(PauseRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      if (_recorder!.isRecording) {
        await _recorder!.pauseRecorder();
        _durationTimer?.cancel();
        _backgroundTimer?.cancel();
        _notificationService.stopNotificationService();
        emit(RecordingPaused(_currentDurationInSeconds));
      }
    } catch (e) {
      emit(AudioDashboardError("Failed to pause recording: ${e.toString()}"));
    }
  }

  Future<void> _onResumeRecording(ResumeRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      if (_recorder!.isPaused) {
        await _recorder!.resumeRecorder();
        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _currentDurationInSeconds++;
          add(UpdateRecordingDurationEvent(_currentDurationInSeconds));
        });
        emit(RecordingInProgress(_currentDurationInSeconds));
      }
    } catch (e) {
      emit(AudioDashboardError("Failed to resume recording: ${e.toString()}"));
    }
  }

  Future<void> _onStopRecording(StopRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      _durationTimer?.cancel();
      _backgroundTimer?.cancel();
      _notificationService.stopNotificationService();
      final path = await _recorder!.stopRecorder();

      if (path != null && await File(path).exists()) {
        // Convert AAC to WAV for uncompressed format
        final directory = await getApplicationDocumentsDirectory();
        final wavPath = p.join(directory.path, _finalRecFileName);
        
        try {
          await _convertAacToWav(path, wavPath);
          _currentRecordingPath = wavPath;
          emit(RecordingStopped(wavPath));
          
          // Clean up the temporary AAC file
          final aacFile = File(path);
          if (await aacFile.exists()) {
            await aacFile.delete();
          }
        } catch (conversionError) {
          print("Error converting to WAV: $conversionError");
          // Use AAC file if conversion fails
          _currentRecordingPath = path;
          emit(RecordingStopped(path));
        }
      } else {
        emit(const AudioDashboardError("Failed to stop recording: Path is null or file doesn't exist."));
      }
    } catch (e) {
      emit(AudioDashboardError("Failed to stop recording: ${e.toString()}"));
    }
  }

  Future<void> _convertAacToWav(String aacPath, String wavPath) async {
    try {
      // For now, we'll just copy the AAC file with WAV extension
      // In a production app, you'd use FFmpeg or a similar library for proper conversion
      // This is a simplified approach to maintain the WAV file naming
      final aacFile = File(aacPath);
      
      if (await aacFile.exists()) {
        await aacFile.copy(wavPath);
        print("Converted AAC to WAV (copied): $aacPath -> $wavPath");
      } else {
        throw Exception("Source AAC file does not exist");
      }
    } catch (e) {
      print("Error in AAC to WAV conversion: $e");
      throw e;
    }
  }

  Future<void> _onResetRecording(ResetRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      // Stop any ongoing recording
      if (_recorder!.isRecording || _recorder!.isPaused) {
        await _recorder!.stopRecorder();
      }
      
      // Stop any ongoing playback
      if (_player!.isPlaying || _player!.isPaused) {
        await _player!.stopPlayer();
      }
      
      // Reset all state variables
      _currentRecordingPath = null;
      _currentDurationInSeconds = 0;
      _durationTimer?.cancel();
      _playbackSubscription?.cancel();
      
      // Emit initial state to allow new recording
      emit(AudioDashboardInitial());
    } catch (e) {
      emit(AudioDashboardError("Failed to reset recording: ${e.toString()}"));
    }
  }

  Future<void> _onSubmitRecording(SubmitRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    if (_currentRecordingPath == null) {
      emit(const AudioDashboardError('No recording available to submit.'));
      return;
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(p.join(appDir.path, 'saved_recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'recording_$timestamp.wav';
      final savedPath = p.join(recordingsDir.path, filename);

      await File(_currentRecordingPath!).copy(savedPath);

      final newRecording = Recording(
        path: savedPath,
        name: filename,
        date: DateTime.now(),
        duration: _currentDurationInSeconds,
      );
      _allRecordings.insert(0, newRecording);
      _cacheRecordings();
      emit(RecordingsLoaded(List.from(_allRecordings)));
      _currentRecordingPath = null;
      _currentDurationInSeconds = 0;
      emit(AudioDashboardInitial());
    } catch (e) {
      emit(AudioDashboardError('Failed to submit recording: ${e.toString()}'));
    }
  }

  Future<void> _onLoadRecordings(LoadRecordingsEvent event, Emitter<AudioDashboardState> emit) async {
    emit(AudioDashboardInitial());
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load local recordings
      final cached = prefs.getString(_localRecordingsKey);
      if (cached != null) {
        final decoded = json.decode(cached) as List;
        _allRecordings = decoded.map((data) => Recording.fromJson(data as Map<String, dynamic>)).toList();
      } else {
        _allRecordings = [];
      }
      
      // Also load cached server recordings on startup
      final cachedServerRecordings = prefs.getString(_serverRecordingsKey);
      if (cachedServerRecordings != null) {
        print("Loading cached server recordings during local load");
        final decoded = json.decode(cachedServerRecordings) as List;
        final serverRecordings = decoded.map((data) => Recording.fromJson(data as Map<String, dynamic>)).toList();
        
        // Add server recordings to the list
        _allRecordings.addAll(serverRecordings);
        print("Added ${serverRecordings.length} cached server recordings");
      }
      
      // Always sort by date after loading
      _allRecordings.sort((a, b) => b.date.compareTo(a.date));
      emit(RecordingsLoaded(List.from(_allRecordings)));

      if (event.forceRemote) {
        add(const LoadServerRecordingsEvent());
      }
    } catch (e) {
      print("Error loading recordings: $e");
      emit(const AudioDashboardError('Failed to load local recordings.'));
    }
  }

  Future<void> _onDeleteRecording(DeleteRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      final file = File(event.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _allRecordings.removeWhere((rec) => rec.path == event.filePath);
      _cacheRecordings();
      emit(RecordingsLoaded(List.from(_allRecordings)));
    } catch (e) {
      emit(AudioDashboardError("Failed to delete recording: ${e.toString()}"));
    }
  }

  Future<void> _onPlaySavedRecording(PlaySavedRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    if (_player!.isPlaying || _player!.isPaused) {
      print("[BLoC] Player was active. Stopping before playing new file.");
      await _player!.stopPlayer();
    }
    
    _currentPlayingPathForBloc = event.filePath;
    print("[BLoC] Setting current playing path to: $_currentPlayingPathForBloc");

    try {
      String localPath = event.filePath;
      print("[BLoC] Attempting to play file. Path: $localPath");

      if (localPath.startsWith('server://')) {
        print("[BLoC] Path is a server path. Downloading file...");
        final serverUrl = localPath.replaceFirst('server://', 'https://');
        final http.Response response = await http.get(Uri.parse(serverUrl));
        
        if (response.statusCode == 200) {
          final directory = await getTemporaryDirectory();
          final fileName = p.basename(serverUrl);
          localPath = p.join(directory.path, fileName);
          
          // Ensure the file is properly written and closed
          final file = File(localPath);
          await file.writeAsBytes(response.bodyBytes, flush: true);
          print("[BLoC] File downloaded to: $localPath");
          
          // Verify file size
          final fileSize = await file.length();
          print("[BLoC] Downloaded file size: $fileSize bytes");
          
          if (fileSize == 0) {
            throw Exception('Downloaded file is empty');
          }
        } else {
          print("[BLoC] Failed to download server audio. Status code: ${response.statusCode}");
          throw Exception('Failed to download server audio: ${response.statusCode}');
        }
      }

      final file = File(localPath);
      final fileExists = await file.exists();
      if (!fileExists) {
        print("[BLoC] File does not exist at path: $localPath");
        throw Exception('File not found at $localPath');
      }
      
      // Determine codec based on file extension
      final extension = p.extension(localPath).toLowerCase();
      final codec = _getCodecFromExtension(extension);
      print("[BLoC] Using codec: $codec for file extension: $extension");
      
      print("[BLoC] File exists at path: $localPath. Proceeding to play.");
      print("[BLoC] Calling startPlayer...");
      
      final duration = await _player!.startPlayer(
        fromURI: localPath,
        codec: codec,
        whenFinished: () {
          print("[BLoC] Playback finished for: $_currentPlayingPathForBloc");
          add(const _PlaybackCompletedEvent());
        },
      );
      
      print("[BLoC] startPlayer called. Duration: $duration");
      
      await _player!.setSpeed(_currentSpeed);

      if (duration != null) {
        _currentTotalDurationForBloc = duration;
        _lastKnownPositionForBloc = Duration.zero;

        emit(PlaybackInProgress(
          filePath: event.filePath,
          position: Duration.zero,
          duration: duration,
        ));
        print("[BLoC] Emitted PlaybackInProgress for ${event.filePath}");

        _playerSubscription?.cancel();
        _playerSubscription = _player!.onProgress!.listen((disposition) {
          if (disposition.position != _lastKnownPositionForBloc) {
            _lastKnownPositionForBloc = disposition.position;
            add(UpdatePlaybackProgressEvent(
              filePath: _currentPlayingPathForBloc!,
              position: disposition.position,
              duration: disposition.duration,
            ));
          }
        });
      } else {
        print("[BLoC] Failed to start player: duration is null.");
        emit(const AudioDashboardError("Failed to start player: duration is null."));
      }
    } catch (e, stacktrace) {
      print("[BLoC] Error playing audio: $e");
      print("[BLoC] Stacktrace: $stacktrace");
      emit(AudioDashboardError("Failed to play recording: ${e.toString()}"));
    }
  }

  Codec _getCodecFromExtension(String extension) {
    switch (extension) {
      case '.wav':
        return Codec.pcm16WAV;
      case '.mp3':
        return Codec.mp3;
      case '.aac':
        return Codec.aacADTS;
      case '.m4a':
        return Codec.aacMP4;
      default:
        return Codec.pcm16WAV; // Default to WAV
    }
  }

  Future<void> _onPlayRecording(PlayRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    if (_currentRecordingPath != null) {
      await _playAudio(_currentRecordingPath!, emit);
    }
  }

  Future<void> _playAudio(String path, Emitter<AudioDashboardState> emit) async {
    try {
      if (_player!.isPlaying) {
        await _player!.stopPlayer();
      }

      // Track the current playing path for proper state management
      _currentPlayingPathForBloc = path;

      await _player!.startPlayer(
        fromURI: path,
        codec: Codec.pcm16WAV,
        whenFinished: () {
          add(const StopPlaybackEvent());
        },
      );

      await _player!.setSpeed(1.0); // Reset speed to normal

      _playbackSubscription?.cancel();
      _playbackSubscription = _player!.onProgress!.listen((e) {
        // Update tracking variables for pause/resume functionality
        _lastKnownPositionForBloc = e.position;
        _currentTotalDurationForBloc = e.duration;
        
        add(UpdatePlaybackProgressEvent(
          filePath: path,
          position: e.position,
          duration: e.duration,
        ));
      });

      // Emit an initial progress state. The duration will update once the stream fires.
      emit(PlaybackInProgress(
        filePath: path,
        position: Duration.zero,
        duration: Duration.zero,
      ));
    } catch (e) {
      emit(AudioDashboardError("Playback failed: $e"));
    }
  }

  Future<void> _onPausePlaybackEvent(PausePlaybackEvent event, Emitter<AudioDashboardState> emit) async {
    if (_player!.isPlaying) {
      await _player!.pausePlayer();
      _isPaused = true;
      if (state is PlaybackInProgress) {
        final currentState = state as PlaybackInProgress;
        emit(PlaybackPaused(
          filePath: currentState.filePath,
          position: currentState.position,
          duration: currentState.duration,
          speed: currentState.speed,
        ));
      }
    }
  }

  Future<void> _onResumePlaybackEvent(ResumePlaybackEvent event, Emitter<AudioDashboardState> emit) async {
    if (_player!.isPaused) {
      await _player!.resumePlayer();
      _isPaused = false;
      if (state is PlaybackPaused) {
        final currentState = state as PlaybackPaused;
        emit(PlaybackInProgress(
          filePath: currentState.filePath,
          position: currentState.position,
          duration: currentState.duration,
          speed: currentState.speed,
        ));
      }
    }
  }

  Future<void> _onStopPlaybackEvent(StopPlaybackEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      // Stop player if it's playing or paused
      if (_player != null && (_player!.isPlaying || _player!.isPaused)) {
        await _player!.stopPlayer();
      }
      _playbackSubscription?.cancel();
      
      // Reset player state
      _resetPlayerState();
      
      // Maintain the RecordingStopped state if we have a current recording
      if (_currentRecordingPath != null) {
        emit(RecordingStopped(_currentRecordingPath!));
      } else {
        emit(RecordingsLoaded(List.from(_allRecordings)));
      }
    } catch (e) {
      print("Error stopping playback: $e");
      // Don't emit error for stop playback failures - just log them
      // This prevents permission dialogs from showing when closing player
      // emit(AudioDashboardError("Failed to stop playback: ${e.toString()}"));
      
      // Still emit a proper state to maintain UI consistency
      if (_currentRecordingPath != null) {
        emit(RecordingStopped(_currentRecordingPath!));
      } else {
        emit(RecordingsLoaded(List.from(_allRecordings)));
      }
    }
  }

  void _onPlaybackCompleted(_PlaybackCompletedEvent event, Emitter<AudioDashboardState> emit) {
    _resetPlayerState();
    
    // Maintain the previous state if we have a recording
    if (_currentRecordingPath != null) {
      emit(RecordingStopped(_currentRecordingPath!));
    } else {
      // Otherwise show recordings list
      emit(RecordingsLoaded(List.from(_allRecordings)));
    }
  }

  void _resetPlayerState() {
    _playerSubscription?.cancel();
    _playerSubscription = null;
    _currentPlayingPathForBloc = null;
    _lastKnownPositionForBloc = null;
    _currentTotalDurationForBloc = null;
    _isPaused = false;
  }

  Future<void> _cacheRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final localRecordings = _allRecordings.where((r) => !r.serverSaved).toList();
    final data = json.encode(localRecordings.map((r) => r.toJson()).toList());
    await prefs.setString(_localRecordingsKey, data);
  }

  Future<void> _onLoadServerRecordings(LoadServerRecordingsEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      // Get userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('USER_ID');
      
      if (userId == null) {
        print("User ID not found in SharedPreferences - cannot load server recordings");
        
        // Try to load cached server recordings if available
        final cachedServerRecordings = prefs.getString(_serverRecordingsKey);
        if (cachedServerRecordings != null) {
          print("Loading cached server recordings");
          final decoded = json.decode(cachedServerRecordings) as List;
          final serverRecordings = decoded.map((data) => Recording.fromJson(data as Map<String, dynamic>)).toList();
          
          // Merge with local recordings
          final localRecordings = _allRecordings.where((r) => !r.serverSaved).toList();
          _allRecordings = [...localRecordings, ...serverRecordings];
          _allRecordings.sort((a, b) => b.date.compareTo(a.date));
          
          emit(RecordingsLoaded(List.from(_allRecordings)));
        }
        return;
      }

      print("Loading server recordings for user: $userId");

      final response = await http.post(
        Uri.parse('https://vacha.langlex.com/Api/ApiController/getAudioRecordings'),
        body: {
          'userId': userId,
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['error'] == false && responseData['data'] != null) {
          final List<dynamic> recordings = responseData['data'] as List;
          
          print("Successfully loaded ${recordings.length} server recordings");
          
          // Convert server recordings to Recording objects
          final serverRecordings = recordings.map((recording) => Recording(
            path: 'server://vacha.langlex.com/${recording['file_path']}',  // Use actual file path from server
            name: recording['title'] as String,
            date: DateTime.parse(recording['date_recorded'] as String),
            duration: int.parse(recording['duration'] as String),
            serverSaved: true,  // Mark as server recording
            serverId: int.parse(recording['id'] as String),  // Convert string ID to int
          )).toList();

          // Cache server recordings separately
          await _cacheServerRecordings(serverRecordings);

          // Update _allRecordings with server recordings
          // Keep local recordings and add server recordings
          final localRecordings = _allRecordings.where((r) => !r.serverSaved).toList();
          _allRecordings = [...localRecordings, ...serverRecordings];
          
          // Sort by date
          _allRecordings.sort((a, b) => b.date.compareTo(a.date));
          
          // Cache the updated recordings
          await _cacheRecordings();
          
          // Emit updated state
          emit(RecordingsLoaded(List.from(_allRecordings)));
        } else {
          print("Server returned error: ${responseData['message']}");
          
          // Try to load cached server recordings as fallback
          await _loadCachedServerRecordings(emit);
        }
      } else {
        print("Failed to fetch server recordings. Status code: ${response.statusCode}");
        
        // Try to load cached server recordings as fallback
        await _loadCachedServerRecordings(emit);
      }
    } catch (e) {
      print("Error loading server recordings: $e");
      
      // Try to load cached server recordings as fallback
      await _loadCachedServerRecordings(emit);
      
      // Don't emit error state for server recording failures - just continue with local recordings
      // emit(AudioDashboardError("Failed to load server recordings: ${e.toString()}"));
    }
  }

  Future<void> _cacheServerRecordings(List<Recording> serverRecordings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(serverRecordings.map((r) => r.toJson()).toList());
      await prefs.setString(_serverRecordingsKey, data);
      print("Cached ${serverRecordings.length} server recordings");
    } catch (e) {
      print("Error caching server recordings: $e");
    }
  }

  Future<void> _loadCachedServerRecordings(Emitter<AudioDashboardState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedServerRecordings = prefs.getString(_serverRecordingsKey);
      
      if (cachedServerRecordings != null) {
        print("Loading cached server recordings as fallback");
        final decoded = json.decode(cachedServerRecordings) as List;
        final serverRecordings = decoded.map((data) => Recording.fromJson(data as Map<String, dynamic>)).toList();
        
        // Merge with local recordings
        final localRecordings = _allRecordings.where((r) => !r.serverSaved).toList();
        _allRecordings = [...localRecordings, ...serverRecordings];
        _allRecordings.sort((a, b) => b.date.compareTo(a.date));
        
        emit(RecordingsLoaded(List.from(_allRecordings)));
        print("Loaded ${serverRecordings.length} cached server recordings");
      } else {
        print("No cached server recordings available");
      }
    } catch (e) {
      print("Error loading cached server recordings: $e");
    }
  }

  void _onUpdatePlaybackProgress(UpdatePlaybackProgressEvent event, Emitter<AudioDashboardState> emit) {
    emit(PlaybackInProgress(
      filePath: event.filePath,
      position: event.position,
      duration: event.duration,
    ));
  }

  void _onUpdateRecordingDuration(UpdateRecordingDurationEvent event, Emitter<AudioDashboardState> emit) {
    emit(RecordingInProgress(event.duration));
  }

  Future<void> _onDeleteServerRecording(DeleteServerRecordingEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      final response = await http.post(
        Uri.parse('https://vacha.langlex.com/Api/ApiController/deleteAudioRecording'),
        body: {
          'id': event.id.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['error'] == false) {
          _allRecordings.removeWhere((rec) => rec.serverId == event.id);
          await _cacheRecordings();
          emit(RecordingsLoaded(List.from(_allRecordings)));
        } else {
          emit(AudioDashboardError("Failed to delete server recording: ${responseData['message']}"));
        }
      } else {
        emit(AudioDashboardError("Failed to delete server recording: Server error ${response.statusCode}"));
      }
    } catch (e) {
      emit(AudioDashboardError("Failed to delete server recording: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateServerRecordingTitle(UpdateServerRecordingTitleEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      final response = await http.post(
        Uri.parse('https://vacha.langlex.com/Api/ApiController/updateTitleAudioRecording'),
        body: {
          'id': event.id.toString(),
          'title': event.newTitle,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['error'] == false) {
          // Update the recording title in local list
          final index = _allRecordings.indexWhere((recording) => recording.serverId == event.id);
          if (index != -1) {
            final updatedRecording = Recording(
              path: event.newTitle,  // Update path with new title
              name: event.newTitle,  // Update name with new title
              date: _allRecordings[index].date,
              duration: _allRecordings[index].duration,
              serverSaved: true,
              serverId: event.id,
            );
            _allRecordings[index] = updatedRecording;
          }
          
          // Cache updated recordings
          await _cacheRecordings();
          
          // Emit success state
          emit(RecordingsLoaded(List.from(_allRecordings)));
        } else {
          emit(AudioDashboardError(responseData['message'] as String));
        }
      } else {
        emit(const AudioDashboardError('Failed to update recording title'));
      }
    } catch (e) {
      emit(AudioDashboardError('Error updating recording title: ${e.toString()}'));
    }
  }

  Future<void> _onSetPlaybackSpeed(SetPlaybackSpeedEvent event, Emitter<AudioDashboardState> emit) async {
    try {
      if (_player == null || !_player!.isOpen()) {
        emit(const AudioDashboardError("Player is not initialized"));
        return;
      }

      if (_currentPlayingPathForBloc == null) {
        emit(const AudioDashboardError("No file is currently playing"));
        return;
      }

      _currentSpeed = event.speed;
      print("Setting playback speed to: ${event.speed}x");
      
      // Set the speed on the player if it's playing or paused
      if (_player!.isPlaying || _player!.isPaused) {
        await _player!.setSpeed(event.speed);
      }

      // Always emit state with new speed to update UI
      if (state is PlaybackInProgress) {
        final currentState = state as PlaybackInProgress;
        if (currentState.filePath == _currentPlayingPathForBloc) {
          emit(PlaybackInProgress(
            filePath: currentState.filePath,
            position: currentState.position,
            duration: currentState.duration,
            speed: _currentSpeed,
          ));
          print("Emitted PlaybackInProgress with speed: $_currentSpeed");
        }
      } else if (state is PlaybackPaused) {
        final currentState = state as PlaybackPaused;
        if (currentState.filePath == _currentPlayingPathForBloc) {
          emit(PlaybackPaused(
            filePath: currentState.filePath,
            position: currentState.position,
            duration: currentState.duration,
            speed: _currentSpeed,
          ));
          print("Emitted PlaybackPaused with speed: $_currentSpeed");
        }
      }
    } catch (e) {
      print("Error setting playback speed: $e");
      emit(AudioDashboardError("Failed to set playback speed: ${e.toString()}"));
    }
  }

  Future<void> _onSeekPlayback(SeekPlaybackEvent event, Emitter<AudioDashboardState> emit) async {
    if (_player == null || !_player!.isOpen() || !(_player!.isPlaying || _player!.isPaused)) {
      emit(const AudioDashboardError("Player is not initialized or not playing"));
      return;
    }

    try {
      Duration newPosition;
      if (event.relative) {
        // For relative seeking (e.g., skip forward/backward)
        final currentPosition = _lastKnownPositionForBloc ?? Duration.zero;
        newPosition = currentPosition + event.position;
      } else {
        // For absolute seeking (e.g., slider)
        newPosition = event.position;
      }

      // Ensure we don't seek beyond bounds
      if (newPosition < Duration.zero) {
        newPosition = Duration.zero;
      }
      if (_currentTotalDurationForBloc != null && newPosition > _currentTotalDurationForBloc!) {
        newPosition = _currentTotalDurationForBloc!;
      }

      // Perform the seek
      await _player!.seekToPlayer(newPosition);
      _lastKnownPositionForBloc = newPosition;

      // Emit appropriate state based on whether we're playing or paused
      if (_player!.isPlaying) {
        emit(PlaybackInProgress(
          filePath: _currentPlayingPathForBloc!,
          position: newPosition,
          duration: _currentTotalDurationForBloc ?? Duration.zero,
          speed: _currentSpeed,
        ));
      } else if (_player!.isPaused) {
        emit(PlaybackPaused(
          filePath: _currentPlayingPathForBloc!,
          position: newPosition,
          duration: _currentTotalDurationForBloc ?? Duration.zero,
          speed: _currentSpeed,
        ));
      }
    } catch (e) {
      emit(AudioDashboardError("Failed to seek: ${e.toString()}"));
    }
  }

  void setBackgroundState(bool isBackground, BuildContext context) {
    _isInBackground = isBackground;
    if (_recorder?.isRecording == true) {
      if (isBackground) {
        _showBackgroundNotification(context);
      } else {
        _notificationService.stopNotificationService();
      }
    }
  }

  void _showBackgroundNotification(BuildContext context) {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_recorder!.isRecording) {
        timer.cancel();
        _notificationService.stopNotificationService();
        return;
      }

      _backgroundRecordingDuration++;
      final duration = Duration(seconds: _backgroundRecordingDuration);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      final durationStr = '${hours > 0 ? '$hours:' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      _notificationService.showRecordingNotification(
        context,
        title: 'Recording in Progress',
        body: 'Duration: $durationStr',
      );
    });
  }
} 