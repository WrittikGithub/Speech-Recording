part of 'save_feedback_bloc.dart';

@immutable
sealed class SaveFeedbackEvent {}

final class SaveFeedbackButtonClickingEvent extends SaveFeedbackEvent {
  final String additionalinfo;
  final String taskTargetId;

  SaveFeedbackButtonClickingEvent({required this.additionalinfo, required this.taskTargetId});
}
