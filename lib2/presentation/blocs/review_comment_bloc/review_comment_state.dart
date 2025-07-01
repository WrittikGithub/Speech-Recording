part of 'review_comment_bloc.dart';

@immutable
sealed class ReviewCommentState {}

final class ReviewCommentInitial extends ReviewCommentState {}
final class FetchReviewCommentInitial extends ReviewCommentState {}

final class FetchReviewCommmentLoadingState extends ReviewCommentState {}

final class FetchReviewCommentSuccessState extends ReviewCommentState {
  final List<CommentModel> comments;

  FetchReviewCommentSuccessState({required this.comments});
}

final class FetchReviewCommentErrorState extends ReviewCommentState {
  final String message;

  FetchReviewCommentErrorState({required this.message});
}
