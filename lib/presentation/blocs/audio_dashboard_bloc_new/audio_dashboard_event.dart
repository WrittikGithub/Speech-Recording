part of 'audio_dashboard_bloc.dart';

@immutable
sealed class AudioDashboardEvent extends Equatable {
  const AudioDashboardEvent();

  @override
  List<Object> get props => [];
}

class StartRecordingEvent extends AudioDashboardEvent {}
class PauseRecordingEvent extends AudioDashboardEvent {}
class ResumeRecordingEvent extends AudioDashboardEvent {}
class StopRecordingEvent extends AudioDashboardEvent {}
class PlayRecordingEvent extends AudioDashboardEvent {}
class ResetRecordingEvent extends AudioDashboardEvent {}

// New events for recording management
class SubmitRecordingEvent extends AudioDashboardEvent {}
class LoadRecordingsEvent extends AudioDashboardEvent {}
class DeleteRecordingEvent extends AudioDashboardEvent {
  final String filePath;
  const DeleteRecordingEvent(this.filePath);

  @override
  List<Object> get props => [filePath];
}

// Private event not exposed to UI
class _UpdateDurationEvent extends AudioDashboardEvent {
  final int duration;
  const _UpdateDurationEvent(this.duration);
  
  @override
  List<Object> get props => [duration];
}

class _PlaybackCompletedEvent extends AudioDashboardEvent {
  const _PlaybackCompletedEvent();
}

// Add this new event class
class PlaySavedRecordingEvent extends AudioDashboardEvent {
  final String filePath;
  const PlaySavedRecordingEvent(this.filePath);
  
  @override
  List<Object> get props => [filePath];
} 