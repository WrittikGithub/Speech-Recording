part of 'reviews_assignmentsinterview_bloc.dart';

@immutable
sealed class ReviewsAssignmentsinterviewState {}

final class ReviewsAssignmentsinterviewInitial
    extends ReviewsAssignmentsinterviewState {}

final class ReviewsAssignmentsinterviewLoadingState
    extends ReviewsAssignmentsinterviewState {}

final class ReviewsAssignmentsinterviewSuccessState
    extends ReviewsAssignmentsinterviewState {
  final List<ReviewsModel> reviewslists;

  ReviewsAssignmentsinterviewSuccessState({required this.reviewslists});
}

final class ReviewAssignmentsSearchState
    extends ReviewsAssignmentsinterviewState {
  final List<ReviewsModel> searchReviewsList;

  ReviewAssignmentsSearchState({required this.searchReviewsList});
}

final class ReviewsAssignmentsFilterState
    extends ReviewsAssignmentsinterviewState {
  final List<ReviewsModel> filterdReviewsList;

  ReviewsAssignmentsFilterState({required this.filterdReviewsList});
}

final class ReviwsAssignmentsErrorState
    extends ReviewsAssignmentsinterviewState {
  final String message;

  ReviwsAssignmentsErrorState({required this.message});
}
final class ReviewdownloadingState extends ReviewsAssignmentsinterviewState {
  final double progress; // Progress from 0.0 to 1.0
  final String? message; // Optional message to show during download

  ReviewdownloadingState({
    required this.progress,
    this.message,
  });
}