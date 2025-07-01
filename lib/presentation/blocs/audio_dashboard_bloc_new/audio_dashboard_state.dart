part of 'audio_dashboard_bloc.dart';

@immutable
sealed class AudioDashboardState extends Equatable {
  const AudioDashboardState();

  @override
  List<Object> get props => [];
}

class AudioDashboardInitial extends AudioDashboardState {}
class RecordingStarted extends AudioDashboardState {}
class RecordingPaused extends AudioDashboardState {}
class RecordingResumed extends AudioDashboardState {}
class RecordingStopped extends AudioDashboardState {
  final String filePath;
  const RecordingStopped(this.filePath);

  @override
  List<Object> get props => [filePath];
}
class PlaybackStarted extends AudioDashboardState {
  final List<Recording> recordings;
  final String playingPath;
  
  const PlaybackStarted(this.playingPath, {this.recordings = const []});
  
  @override
  List<Object> get props => [playingPath, recordings];
}
class RecordingInProgress extends AudioDashboardState {
  final int duration;
  const RecordingInProgress(this.duration);

  @override
  List<Object> get props => [duration];
}
class AudioDashboardError extends AudioDashboardState {
  final String message;
  const AudioDashboardError(this.message);

  @override
  List<Object> get props => [message];
}

// New states for recording management
class RecordingSubmitted extends AudioDashboardState {
  final String savedPath;
  const RecordingSubmitted(this.savedPath);

  @override
  List<Object> get props => [savedPath];
}

class RecordingsLoaded extends AudioDashboardState {
  final List<Recording> recordings;
  const RecordingsLoaded(this.recordings);

  @override
  List<Object> get props => [recordings];
}

// Recording model class
class Recording extends Equatable {
  final String path;
  final String name;
  final DateTime date;

  const Recording({
    required this.path,
    required this.name,
    required this.date,
  });

  @override
  List<Object> get props => [path, name, date];
} 