part of 'save_task_bloc.dart';

@immutable
sealed class SaveTaskState {}

final class SaveTaskInitial extends SaveTaskState {}

final class SaveTaskLoadingState extends SaveTaskState {}

final class SaveTaskSuccessState extends SaveTaskState {
  final String message;
  final bool isOffline;
  final String? serverUrl;

  SaveTaskSuccessState({
    required this.message,
    this.isOffline = false,
    this.serverUrl,
  });
}

final class SaveTaskRefreshNeededState extends SaveTaskState {
  final String message;
  final String? serverUrl;

  SaveTaskRefreshNeededState({
    required this.message,
    this.serverUrl,
  });
}

final class SaveTaskErrorState extends SaveTaskState {
  final String message;

  SaveTaskErrorState({required this.message});
}
