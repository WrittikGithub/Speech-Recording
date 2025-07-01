part of 'task_bloc.dart';

@immutable
sealed class TaskEvent {}

final class TaskFetchingInitialEvent extends TaskEvent {}

final class TaskSerachEvent extends TaskEvent {
  final String query;

  TaskSerachEvent({required this.query});
}

final class TaskFilterEvent extends TaskEvent {
  final String? language;
  final String? status;

  TaskFilterEvent({ this.language, this.status});
}
/////////
final class TaskRefreshEvent extends TaskEvent {}
class TaskDownloadEvent extends TaskEvent {
  final bool forceDownload; // If true, will re-download even if local data exists
  
  TaskDownloadEvent({
    this.forceDownload = false,
  });
}


///////////////
// // Normal download
// context.read<TaskBloc>().add(TaskDownloadEvent());

// // Force re-download
// context.read<TaskBloc>().add(TaskDownloadEvent(forceDownload: true));