part of 'fetch_comment_bloc.dart';

@immutable
sealed class FetchCommentEvent {}

final class FetchCommentInitialEvent extends FetchCommentEvent {
  final String contentId;
  final String taskTargetId;

  FetchCommentInitialEvent({required this.contentId, required this.taskTargetId});
}
