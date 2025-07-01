part of 'save_reviewcomment_bloc.dart';

@immutable
sealed class SaveReviewcommentEvent {}
final class SaveReviewCommentButtonClickingEvent extends SaveReviewcommentEvent{
  final String taskTargetId;
  final String contentId;
  final String comment;

  SaveReviewCommentButtonClickingEvent({required this.taskTargetId, required this.contentId, required this.comment});
}