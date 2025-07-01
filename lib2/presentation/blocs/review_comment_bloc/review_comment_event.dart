part of 'review_comment_bloc.dart';

@immutable
sealed class ReviewCommentEvent {}
final class FetchReviewCommentInitialEvent extends ReviewCommentEvent {
  final String contentId;
  final String taskTargetId;

  FetchReviewCommentInitialEvent({required this.contentId, required this.taskTargetId});
}
