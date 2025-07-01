part of 'submit_task_bloc.dart';

@immutable
sealed class SubmitTaskState {}

final class SubmitTaskInitial extends SubmitTaskState {}
final class SubmitTaskLoadingState extends SubmitTaskState {}

final class SubmitTaskSuccessState extends SubmitTaskState {
  final String message;

  SubmitTaskSuccessState({required this.message});
}

final class SubmitTaskErrorState extends SubmitTaskState {
  final String message;

  SubmitTaskErrorState({required this.message});
}
