// import 'dart:async';
// import 'dart:io';

// import 'package:bloc/bloc.dart';
// import 'package:meta/meta.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';


// part 'audio_record_event.dart';
// part 'audio_record_state.dart';

// class AudioRecordBloc extends Bloc<AudioRecordEvent, AudioRecordState> {
//   final AudioRecorder _recorder = AudioRecorder();
//   String? _recordingPath;
//   AudioRecordBloc() : super(AudioRecordInitial()) {
//     on<AudioRecordEvent>((event, emit) {});
//     on<StartRecording>(_onstartRecording);
//     on<PauseRecording>(_onPauseRecording);
//     on<ResumeRecording>(_onResumingRecording);
//     on<StopRecording>(_onStopRecording);
//     on<PlayRecording>(_onPlayRecording);
//     on<PausePlayback>(_onPausePlayback);
//     on<ResetRecording>(_onResetRecording);
//   }

//   FutureOr<void> _onstartRecording(
//       StartRecording event, Emitter<AudioRecordState> emit) async {
//     try {
//       if (await _recorder.hasPermission()) {
//         final directory = await getApplicationCacheDirectory();
//         _recordingPath =
//             '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
//         await _recorder.start(
//             RecordConfig(
//                 encoder: AudioEncoder.wav, sampleRate: 44100, bitRate: 128000),
//             path: _recordingPath!);
//         emit(AudioRecording());
//       }
//     } catch (e) {
//       emit(AudioRecordInitial());
//     }
//   }

//   FutureOr<void> _onPauseRecording(
//       PauseRecording event, Emitter<AudioRecordState> emit) async {
//     try {
//       await _recorder.pause();
//       emit(AudioRecordingPaused());
//     } catch (e) {}
//   }

//   FutureOr<void> _onResumingRecording(
//       ResumeRecording event, Emitter<AudioRecordState> emit) async {
//     try {
//       await _recorder.resume();
//       emit(AudioRecording());
//     } catch (e) {}
//   }

//   FutureOr<void> _onStopRecording(
//       StopRecording event, Emitter<AudioRecordState> emit) async {
//     try {
//       final path = await _recorder.stop();
//       if (path != null) {
//         _recordingPath = path;
//         emit(AudioRecordingStopped(path));
//       }
//     } catch (e) {
//       emit(AudioRecordInitial());
//     }
//   }

//   FutureOr<void> _onPlayRecording(
//       PlayRecording event, Emitter<AudioRecordState> emit) async {
//     if (_recordingPath != null) {
//       emit(AudioPlaying(_recordingPath!));
//     }
//   }

//   FutureOr<void> _onPausePlayback(
//       PausePlayback event, Emitter<AudioRecordState> emit) async {
//     if (_recordingPath != null) {
//       emit(AudioPlayingPaused(_recordingPath!));
//     }
//   }

//   FutureOr<void> _onResetRecording(
//       ResetRecording event, Emitter<AudioRecordState> emit) async {
//     try {
//       await _recorder.cancel();
//       if (_recordingPath != null) {
//         final file = File(_recordingPath!);
//         if (await file.exists()) {
//           await file.delete();
//         }
//       }
//       _recordingPath = null;
//       emit(AudioRecordInitial());
//     } catch (e) {}
//   }
//     @override
//   Future<void> close() async {
//     await _recorder.dispose();
//     super.close();
//   }
// }
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  }

  Future<void> _onStartRecording(
      StartRecording event, Emitter<AudioRecordState> emit) async {
    try {
      // Request microphone permission
      if (await Permission.microphone.request().isGranted) {
        // Initialize the recorder
        await _recorder.openRecorder();
        
        // Get temporary directory for recording
        // final directory = await getTemporaryDirectory();
           final directory = await getApplicationDocumentsDirectory();
        _recordingPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

        // Start recording
        await _recorder.startRecorder(
          toFile: _recordingPath,
          codec: Codec.pcm16WAV,
            sampleRate: 44100,
        );
        emit(AudioRecording());
      } else {
        emit(AudioRecordInitial());
      }
    } catch (e) {
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
      log("recording path is $_recordingPath");
      try {
        await _player.openPlayer();
        await _player.startPlayer(
          fromURI: _recordingPath,
          codec: Codec.pcm16WAV,
            sampleRate: 44100,
          whenFinished: () {
            add(PausePlayback());
          },
        );
        emit(AudioPlaying(_recordingPath!));
      } catch (e) {
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

  @override
  Future<void> close() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    super.close();
  }
}