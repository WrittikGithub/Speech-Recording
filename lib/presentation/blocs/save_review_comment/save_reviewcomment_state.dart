part of 'save_reviewcomment_bloc.dart';

@immutable
sealed class SaveReviewcommentState {}

final class SaveReviewcommentInitial extends SaveReviewcommentState {}

final class SaveReviewCommentInitial extends SaveReviewcommentState {}

final class SaveReviewCommentLoadingState extends SaveReviewcommentState {}

final class SaveReviewCommentSuccessState extends SaveReviewcommentState {}

final class SaveReviewCommentErrorState extends SaveReviewcommentState {
  final String message;

  SaveReviewCommentErrorState({required this.message});
}