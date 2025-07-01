// part of 'audio_record_bloc.dart';

// @immutable
// sealed class AudioRecordEvent {}
// final class StartRecording extends AudioRecordEvent{}
// final  class PauseRecording extends AudioRecordEvent{}
// final class ResumeRecording extends AudioRecordEvent {}
// final class StopRecording extends AudioRecordEvent {}
// final class PlayRecording extends AudioRecordEvent{}
// final class PausePlayback extends AudioRecordEvent{}
// final class ResetRecording extends AudioRecordEvent {}
part of 'audio_record_bloc.dart';

@immutable
sealed class AudioRecordEvent {}

final class StartRecording extends AudioRecordEvent {}
final class PauseRecording extends AudioRecordEvent {}
final class ResumeRecording extends AudioRecordEvent {}
final class StopRecording extends AudioRecordEvent {}
final class PlayRecording extends AudioRecordEvent {}
final class PausePlayback extends AudioRecordEvent {}
final class ResetRecording extends AudioRecordEvent {}

class PlayRemoteAudio extends AudioRecordEvent {
  final String url;
  PlayRemoteAudio(this.url);
}