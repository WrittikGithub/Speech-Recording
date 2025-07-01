part of 'save_task_bloc.dart';

@immutable
sealed class SaveTaskState {}

final class SaveTaskInitial extends SaveTaskState {}

final class SaveTaskLoadingState extends SaveTaskState {}

final class SaveTaskSuccessState extends SaveTaskState {
  final String message;

  SaveTaskSuccessState({required this.message});
}

final class SaveTaskErrorState extends SaveTaskState {
  final String message;

  SaveTaskErrorState(this.message);
}
