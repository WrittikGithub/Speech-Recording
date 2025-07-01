// part of 'audio_record_bloc.dart';

// @immutable
// sealed class AudioRecordState {}

// final class AudioRecordInitial extends AudioRecordState {}
// final class  AudioRecorderReady extends AudioRecordState {}
// final class AudioRecording extends AudioRecordState {}
// final class AudioRecordingPaused extends AudioRecordState {}
// final class AudioRecordingStopped extends AudioRecordState{
//   final String path;
//   AudioRecordingStopped(this.path);
// }
// final class AudioPlaying extends AudioRecordState {
//   final String path;
//   AudioPlaying(this.path);
// }
// final class AudioPlayingPaused extends AudioRecordState {
//   final String path;
//   AudioPlayingPaused(this.path);
// } 
part of 'audio_record_bloc.dart';

@immutable
abstract class AudioRecordState {}

class AudioRecordInitial extends AudioRecordState {}

class AudioRecording extends AudioRecordState {
  final List<double> waveformData;
  
  AudioRecording({this.waveformData = const []});
}

class AudioRecordingPaused extends AudioRecordState {
  final List<double> waveformData;
  
  AudioRecordingPaused({this.waveformData = const []});
}

class AudioRecordingStopped extends AudioRecordState {
  final String filePath;
  final String base64Data;
  final String? serverUrl;
  final List<double> waveformData;

  AudioRecordingStopped(
    this.filePath, {
    required this.base64Data,
    this.serverUrl,
    this.waveformData = const [],
  });
}

class AudioPlaying extends AudioRecordState {
  final String filePath;
  final List<double> waveformData;

  AudioPlaying(this.filePath, {this.waveformData = const []});
}

class AudioPlayingPaused extends AudioRecordState {
  final String filePath;
  final List<double> waveformData;

  AudioPlayingPaused(this.filePath, {this.waveformData = const []});
}

class AudioRecordError extends AudioRecordState {
  final String message;

  AudioRecordError(this.message);
}