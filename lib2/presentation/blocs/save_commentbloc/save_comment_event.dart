part of 'save_comment_bloc.dart';

@immutable
sealed class SaveCommentEvent {}

final class SaveCommentButtonClickingEvent extends SaveCommentEvent {
  final String taskTargetId;
  final String contentId;
  final String comment;

  SaveCommentButtonClickingEvent({required this.taskTargetId, required this.contentId, required this.comment});
}
