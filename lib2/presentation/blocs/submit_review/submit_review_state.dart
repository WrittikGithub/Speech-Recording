part of 'submit_review_bloc.dart';

@immutable
sealed class SubmitReviewState {}

final class SubmitReviewInitial extends SubmitReviewState {}

final class SubmitReviewLoadingState extends SubmitReviewState {}

final class SubmitReviewSuccessState extends SubmitReviewState {
  final String message;

  SubmitReviewSuccessState({required this.message});
}

final class SubmitReviewErrorState extends SubmitReviewState {
  final String message;

  SubmitReviewErrorState({required this.message});
}
