part of 'task_bloc.dart';

@immutable
sealed class TaskState {}

final class TaskInitial extends TaskState {}

final class TaskFetchingLoadingState extends TaskState {}

final class TaskFetchingSuccessState extends TaskState {
  final List<TaskModel> tasks;

  TaskFetchingSuccessState({required this.tasks});
}

final class TaskFetchingErrorState extends TaskState {
  final String message;

  TaskFetchingErrorState({required this.message});
}

final class TasksearchState extends TaskState {
  final List<TaskModel> searchResult;

  TasksearchState({required this.searchResult});
}

final class TaskFilteredState extends TaskState {
  final List<TaskModel> filteredTasks;

  TaskFilteredState({required this.filteredTasks});
}
class TaskDownloadingState extends TaskState {
  final double progress;  // Progress from 0.0 to 1.0
  final String? message; // Optional message to show during download
  
  TaskDownloadingState({
    required this.progress,
    this.message,
  });
}
