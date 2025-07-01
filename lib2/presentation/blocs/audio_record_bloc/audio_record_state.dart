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
sealed class AudioRecordState {}

final class AudioRecordInitial extends AudioRecordState {}
final class AudioRecorderReady extends AudioRecordState {}
final class AudioRecording extends AudioRecordState {}
final class AudioRecordingPaused extends AudioRecordState {}
final class AudioRecordingStopped extends AudioRecordState {
  final String path;
  AudioRecordingStopped(this.path);
}
final class AudioPlaying extends AudioRecordState {
  final String path;
  AudioPlaying(this.path);
}
final class AudioPlayingPaused extends AudioRecordState {
  final String path;
  AudioPlayingPaused(this.path);
}