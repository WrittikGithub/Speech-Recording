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

// Add this new event - resets state without deleting files
final class ResetToInitialState extends AudioRecordEvent {}

class RecordingPathUpdated extends AudioRecordEvent {
  final String permanentPath;
  final String base64String;
  final String? serverUrl;
  
  RecordingPathUpdated({
    required this.permanentPath,
    required this.base64String,
    this.serverUrl,
  });
}

class PlayLocalFile extends AudioRecordEvent {
  final String path;
  
  PlayLocalFile(this.path);

  @override
  List<Object> get props => [path];
}

class PlayRemoteAudio extends AudioRecordEvent {
  final String audioUrl;
  PlayRemoteAudio(this.audioUrl);
}