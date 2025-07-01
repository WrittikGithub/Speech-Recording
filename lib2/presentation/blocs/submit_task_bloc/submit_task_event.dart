part of 'submit_task_bloc.dart';

@immutable
sealed class SubmitTaskEvent {}
final class SubmitTaskButtonClickEvent extends SubmitTaskEvent {
  final String taskTargetId;

  SubmitTaskButtonClickEvent({required this.taskTargetId});


}
