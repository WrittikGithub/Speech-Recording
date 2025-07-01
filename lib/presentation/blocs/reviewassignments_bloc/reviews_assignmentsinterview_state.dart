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
  final String? taskTargetId;

  ReviwsAssignmentsErrorState({required this.message, this.taskTargetId});
}

final class ReviewdownloadingState extends ReviewsAssignmentsinterviewState {
  final double progress; // Progress from 0.0 to 1.0
  final String? message; // Optional message to show during download
  final String? taskTargetId; // Optional task ID for single task downloads

  ReviewdownloadingState({
    required this.progress,
    this.message,
    this.taskTargetId,
  });
}

final class ReviewDownloadCompletedState extends ReviewsAssignmentsinterviewState {
  // This is a notification state to show download completion notification
  // You can optionally add more properties here if needed
  final DateTime completedAt = DateTime.now();
}