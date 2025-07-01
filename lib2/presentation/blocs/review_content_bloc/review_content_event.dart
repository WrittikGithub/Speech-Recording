part of 'review_content_bloc.dart';

@immutable
sealed class ReviewContentEvent {}

final class ReviewContentFetchingInitialEvent extends ReviewContentEvent {
  final String taskTargetId;

  ReviewContentFetchingInitialEvent({required this.taskTargetId});
}
final class ReviewContentDownloadingEvent extends ReviewContentEvent {
  final String taskTargetId;

  ReviewContentDownloadingEvent({required this.taskTargetId});
}