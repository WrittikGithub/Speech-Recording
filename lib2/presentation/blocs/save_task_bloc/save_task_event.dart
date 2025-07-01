part of 'save_task_bloc.dart';

@immutable
sealed class SaveTaskEvent {}

final class SaveTaskButtonclickingEvent extends SaveTaskEvent {
  final SubmitTaskModel saveData;

  SaveTaskButtonclickingEvent({required this.saveData});
}
