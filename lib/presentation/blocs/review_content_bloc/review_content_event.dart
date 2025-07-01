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

final class ReviewContentPlayAudioEvent extends ReviewContentEvent {
  final String taskTargetId;
  final String contentId;

  ReviewContentPlayAudioEvent({required this.taskTargetId, required this.contentId});
}

class SelectTileEvent extends ReviewContentEvent {
  final int tileIndex; // or any identifier for the tile
  SelectTileEvent(this.tileIndex);
}