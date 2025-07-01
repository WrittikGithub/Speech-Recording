part of 'save_review_bloc.dart';

@immutable
sealed class SaveReviewState {}

final class SaveReviewInitial extends SaveReviewState {}

final class SaveReviewLoadingSate extends SaveReviewState {}

final class SaveReviewSuccessState extends SaveReviewState {}

final class SaveReviewErrorState extends SaveReviewState {
  final String message;

  SaveReviewErrorState({required this.message});
}
