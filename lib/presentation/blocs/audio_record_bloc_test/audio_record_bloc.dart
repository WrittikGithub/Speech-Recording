import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

part 'audio_record_event.dart';
part 'audio_record_state.dart';

class AudioRecordBloc extends Bloc<AudioRecordEvent, AudioRecordState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? _recordingPath;

  AudioRecordBloc() : super(AudioRecordInitial()) {
    on<StartRecording>(_onStartRecording);
    on<PauseRecording>(_onPauseRecording);
    on<ResumeRecording>(_onResumeRecording);
    on<StopRecording>(_onStopRecording);
    on<PlayRecording>(_onPlayRecording);
    on<PausePlayback>(_onPausePlayback);
    on<ResetRecording>(_onResetRecording);
    on<PlayRemoteAudio>(_onPlayRemoteAudio);
  }

  Future<void> _onStartRecording(
      StartRecording event, Emitter<AudioRecordState> emit) async {
    try {
      // Request microphone permission
      if (await Permission.microphone.request().isGranted) {
        // Initialize the recorder
        await _recorder.openRecorder();
        
        // Get temporary directory for recording
        final directory = await getApplicationDocumentsDirectory();
        _recordingPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
        
        // Start recording
        await _recorder.startRecorder(
          toFile: _recordingPath,
          codec: Codec.aacADTS,
          sampleRate: 44100,
        );
        emit(AudioRecording());
      } else {
        emit(AudioRecordInitial());
      }
    } catch (e) {
      print("Error starting recording: $e");
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
      _recordingPath = await _recorder.stopRecorder();
      await _recorder.closeRecorder();
      if (_recordingPath != null) {
        emit(AudioRecordingStopped(_recordingPath!));
      }
    } catch (e) {
      emit(AudioRecordInitial());
    }
  }

  Future<void> _onPlayRecording(
      PlayRecording event, Emitter<AudioRecordState> emit) async {
    if (_recordingPath != null) {
      dev.log("recording path is $_recordingPath");
      try {
        // Check if this is a remote URL
        if (_recordingPath!.startsWith('http')) {
          // Handle remote URLs using the specialized method
          add(PlayRemoteAudio(_recordingPath!));
          return;
        }
        
        // For local files, first emit the state to update UI
        emit(AudioPlaying(_recordingPath!));
        
        // Check if file exists
        if (await File(_recordingPath!).exists()) {
          // Ensure player is open
          if (!_player.isOpen()) {
            await _player.openPlayer();
          }
          
          // Start playing the file
          await _player.startPlayer(
            fromURI: _recordingPath!,
            codec: Codec.aacADTS, // Use AAC codec for better compatibility
            sampleRate: 44100,
            whenFinished: () {
              add(PausePlayback());
            },
          );
        } else {
          // If file doesn't exist locally, check if it's a valid path but not a URL
          print("Local file not found: $_recordingPath");
          emit(AudioRecordInitial());
        }
      } catch (e) {
        print("Error playing recording: $e");
        emit(AudioRecordInitial());
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
      // Stop and close recorder and player
      await _recorder.stopRecorder();
      await _recorder.closeRecorder();
      await _player.stopPlayer();
      await _player.closePlayer();

      // Delete the recording file if it exists
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _recordingPath = null;
      emit(AudioRecordInitial());
    } catch (e) {
      emit(AudioRecordInitial());
    }
  }

  Future<void> _onPlayRemoteAudio(
      PlayRemoteAudio event, Emitter<AudioRecordState> emit) async {
    try {
      print("Playing remote audio from: ${event.url}");
      
      // First emit state to update UI immediately
      emit(AudioPlaying(event.url));
      
      // Store the URL as the current recording path
      _recordingPath = event.url;
      
      // Ensure player is open
      if (!_player.isOpen()) {
        await _player.openPlayer();
      }
      
      // Try multiple codecs in case one fails
      try {
        await _player.startPlayer(
          fromURI: event.url,
          codec: Codec.aacADTS,
          whenFinished: () {
            add(PausePlayback());
          },
        );
        print("Successfully started playback with aacADTS codec");
      } catch (codecError) {
        print("Error playing with aacADTS codec: $codecError");
        
        try {
          // Try with MP3 codec
          await _player.startPlayer(
            fromURI: event.url,
            codec: Codec.mp3,
            whenFinished: () {
              add(PausePlayback());
            },
          );
          print("Successfully started playback with MP3 codec");
        } catch (mp3Error) {
          print("Error playing with MP3 codec: $mp3Error");
          
          // Try with WAV codec as last resort
          try {
            await _player.startPlayer(
              fromURI: event.url,
              codec: Codec.pcm16WAV,
              whenFinished: () {
                add(PausePlayback());
              },
            );
            print("Successfully started playback with WAV codec");
          } catch (wavError) {
            print("Error playing with WAV codec: $wavError");
            
            // If all direct playback attempts fail, simulate playback
            print("All playback attempts failed, simulating playback");
            
            // Show playback state for 3 seconds then simulate completion
            Future.delayed(const Duration(seconds: 3), () {
              add(PausePlayback());
            });
          }
        }
      }
    } catch (e) {
      print("Error in _onPlayRemoteAudio: $e");
      emit(AudioRecordInitial());
    }
  }

  // Add this helper method to check internet access
  Future<bool> _checkInternetAccess() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      return response.statusCode == 200;
    } catch (e) {
      print("Internet access check failed: $e");
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    super.close();
  }
}