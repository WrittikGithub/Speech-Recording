part of 'audio_dashboard_bloc.dart';

@immutable
sealed class AudioDashboardState extends Equatable {
  const AudioDashboardState();

  @override
  List<Object> get props => [];
}

class AudioDashboardInitial extends AudioDashboardState {}
class RecordingStarted extends AudioDashboardState {}
class RecordingPaused extends AudioDashboardState {
  final int duration;
  const RecordingPaused(this.duration);

  @override
  List<Object> get props => [duration];
}
class RecordingResumed extends AudioDashboardState {}
class RecordingStopped extends AudioDashboardState {
  final String filePath;
  const RecordingStopped(this.filePath);

  @override
  List<Object> get props => [filePath];
}
class PlaybackStarted extends AudioDashboardState {
  final List<Recording> recordings;
  final String? playingPath;
  
  const PlaybackStarted({this.playingPath, this.recordings = const []});
  
  @override
  List<Object> get props => [recordings];
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

// State for when playback is stopped or completed
class PlaybackStopped extends AudioDashboardState {}

// New states for recording management
class RecordingSubmitted extends AudioDashboardState {
  final String savedPath;
  const RecordingSubmitted(this.savedPath);

  @override
  List<Object> get props => [savedPath];
}

class RecordingsLoaded extends AudioDashboardState {
  final List<Recording> recordings;
  
  // Get convenience lists
  List<Recording> get localRecordings => recordings.where((rec) => !rec.serverSaved).toList();
  List<Recording> get serverRecordings => recordings.where((rec) => rec.serverSaved).toList();
  
  const RecordingsLoaded(this.recordings);

  @override
  List<Object> get props => [recordings];
}

// Recording model class
class Recording extends Equatable {
  final String path;
  final String name;
  final DateTime date;
  final int duration;
  final bool serverSaved;
  final int? serverId;

  const Recording({
    required this.path,
    required this.name,
    required this.date,
    required this.duration,
    this.serverSaved = false,
    this.serverId,
  });

  @override
  List<Object?> get props => [path, name, date, duration, serverSaved, serverId];

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'date': date.toIso8601String(),
        'duration': duration,
        'serverSaved': serverSaved,
        'serverId': serverId,
      };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        path: json['path'],
        name: json['name'],
        date: DateTime.parse(json['date']),
        duration: json['duration'],
        serverSaved: json['serverSaved'] ?? false,
        serverId: json['serverId'],
      );
}

// State for when a recording duration is loaded
class RecordingDurationLoaded extends AudioDashboardState {
  final int durationInSeconds;
  
  const RecordingDurationLoaded(this.durationInSeconds);
  
  @override
  List<Object> get props => [durationInSeconds];
}

// Playback States
class PlaybackInitial extends AudioDashboardState {}

class PlaybackInProgress extends AudioDashboardState {
  final String filePath;
  final Duration position;
  final Duration duration;
  final double speed;

  const PlaybackInProgress({required this.filePath, required this.position, required this.duration, this.speed = 1.0});

  @override
  List<Object> get props => [filePath, position, duration, speed];
}

class PlaybackPaused extends AudioDashboardState {
  final String filePath;
  final Duration position;
  final Duration duration;
  final double speed;

  const PlaybackPaused({required this.filePath, required this.position, required this.duration, this.speed = 1.0});

  @override
  List<Object> get props => [filePath, position, duration, speed];
}

class AudioPlayerError extends AudioDashboardState {
  final String message;
  final String? filePath;
  final Duration? position;
  final Duration? duration;

  const AudioPlayerError(this.message, {this.filePath, this.position, this.duration});

  @override
  List<Object> get props => [message, filePath ?? '', position ?? Duration.zero, duration ?? Duration.zero];

  @override
  String toString() => 'AudioPlayerError { message: $message, filePath: $filePath, position: $position, duration: $duration }';
}

class RecordingDeletionError extends AudioDashboardState {
  final String message;
  const RecordingDeletionError(this.message);

  @override
  List<Object> get props => [message];
}