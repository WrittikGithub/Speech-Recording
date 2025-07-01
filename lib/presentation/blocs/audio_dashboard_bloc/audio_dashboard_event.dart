part of 'audio_dashboard_bloc.dart';

@immutable
sealed class AudioDashboardEvent extends Equatable {
  const AudioDashboardEvent();

  @override
  List<Object?> get props => [];
}

class StartRecordingEvent extends AudioDashboardEvent {
  final BuildContext? context;
  const StartRecordingEvent({this.context});

  @override
  List<Object?> get props => [context];
}

class PauseRecordingEvent extends AudioDashboardEvent {}
class ResumeRecordingEvent extends AudioDashboardEvent {}
class StopRecordingEvent extends AudioDashboardEvent {}
class ResetRecordingEvent extends AudioDashboardEvent {}

// New events for recording management
class SubmitRecordingEvent extends AudioDashboardEvent {}
class LoadRecordingsEvent extends AudioDashboardEvent {
  final bool forceRemote;
  const LoadRecordingsEvent({this.forceRemote = false});

  @override
  List<Object> get props => [forceRemote];
}
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
  final Duration? startAt;

  const PlaySavedRecordingEvent(this.filePath, {this.startAt});
  
  @override
  List<Object?> get props => [filePath, startAt];
}

// Add event to fetch server recordings
class LoadServerRecordingsEvent extends AudioDashboardEvent {
  const LoadServerRecordingsEvent();
}

// Add event to request duration for a recording
class GetRecordingDurationEvent extends AudioDashboardEvent {
  final String filePath;
  
  const GetRecordingDurationEvent(this.filePath);
  
  @override
  List<Object> get props => [filePath];
}

// Events for Playback Control
class PausePlaybackEvent extends AudioDashboardEvent {
  const PausePlaybackEvent();
}

class ResumePlaybackEvent extends AudioDashboardEvent {
  const ResumePlaybackEvent();
}

class PlayRecordingEvent extends AudioDashboardEvent {}

class StopPlaybackEvent extends AudioDashboardEvent {
  const StopPlaybackEvent();
}

class SeekPlaybackEvent extends AudioDashboardEvent {
  final Duration position;
  final bool relative; // true for seeking forward/backward, false for absolute seek

  const SeekPlaybackEvent(this.position, {this.relative = false});

  @override
  List<Object> get props => [position, relative];
}

class UpdatePlaybackProgressEvent extends AudioDashboardEvent {
  final String filePath;
  final Duration position;
  final Duration duration;

  const UpdatePlaybackProgressEvent({
    required this.filePath,
    required this.position,
    required this.duration,
  });

  @override
  List<Object> get props => [filePath, position, duration];
}

class UpdateRecordingDurationEvent extends AudioDashboardEvent {
  final int duration;

  const UpdateRecordingDurationEvent(this.duration);

  @override
  List<Object> get props => [duration];
}

class DeleteServerRecordingEvent extends AudioDashboardEvent {
  final int id;  // Server recording ID
  
  const DeleteServerRecordingEvent(this.id);
  
  @override
  List<Object> get props => [id];
}

class UpdateServerRecordingTitleEvent extends AudioDashboardEvent {
  final int id;  // Server recording ID
  final String newTitle;
  
  const UpdateServerRecordingTitleEvent({
    required this.id,
    required this.newTitle,
  });
  
  @override
  List<Object> get props => [id, newTitle];
}

class SetPlaybackSpeedEvent extends AudioDashboardEvent {
  final double speed;

  const SetPlaybackSpeedEvent(this.speed);

  @override
  List<Object> get props => [speed];
} 