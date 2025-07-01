part of 'reviews_assignmentsinterview_bloc.dart';

@immutable
sealed class ReviewsAssignmentsinterviewEvent {}

final class ReviewsAssignmentsInitialFetchingEvent
    extends ReviewsAssignmentsinterviewEvent {}

final class ReviewsAssignmentsSearchingEvent
    extends ReviewsAssignmentsinterviewEvent {
  final String query;

  ReviewsAssignmentsSearchingEvent({required this.query});
}

final class ReviewsAssignmentsFilteringEvent
    extends ReviewsAssignmentsinterviewEvent {
  final String? language;

  ReviewsAssignmentsFilteringEvent({ this.language});
}
final class ReviewsAssignmentsRefreshEvent
    extends ReviewsAssignmentsinterviewEvent {}
class ReviewsAssignmentsDownloadEvent extends ReviewsAssignmentsinterviewEvent {
  final bool forceDownload; // If true, will re-download even if local data exists
  
  ReviewsAssignmentsDownloadEvent({
    this.forceDownload = false,
  });
}

class ReviewsAssignmentsDownloadSingleEvent extends ReviewsAssignmentsinterviewEvent {
  final String taskTargetId;
  
  ReviewsAssignmentsDownloadSingleEvent({
    required this.taskTargetId,
  });
}