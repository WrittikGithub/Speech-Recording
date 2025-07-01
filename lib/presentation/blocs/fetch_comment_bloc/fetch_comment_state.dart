part of 'fetch_comment_bloc.dart';

@immutable
sealed class FetchCommentState {}

final class FetchCommentInitial extends FetchCommentState {}

final class FetchCommmentLoadingState extends FetchCommentState {}

final class FetchCommentSuccessState extends FetchCommentState {
  final List<CommentModel> comments;

  FetchCommentSuccessState({required this.comments});
}

final class FetchCommentErrorState extends FetchCommentState {
  final String message;

  FetchCommentErrorState({required this.message});
}
