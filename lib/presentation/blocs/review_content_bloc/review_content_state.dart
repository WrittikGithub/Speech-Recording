part of 'review_content_bloc.dart';

@immutable
sealed class ReviewContentState {}

final class ReviewContentInitial extends ReviewContentState {}
final class ReviewContentLoadingState extends ReviewContentState {}

final class ReviewContentSuccessState extends ReviewContentState {
  final List<ReviewContentModel> contentlist;

  ReviewContentSuccessState({required this.contentlist});

 
}

final class ReviewContentErrrorState extends ReviewContentState {
  final String message;
  final String? contentTaskTargetId;

  ReviewContentErrrorState({required this.message,this.contentTaskTargetId});


}
final class ReviewContentDownloadingState extends ReviewContentState {
  final String contentTaskTargetId;

  ReviewContentDownloadingState({required this.contentTaskTargetId});
}
final class ReviewContentDownloadSuccessState extends ReviewContentState {
  final String contentTaskTargetId;
  final int timestamp;

  ReviewContentDownloadSuccessState({
    required this.contentTaskTargetId,
    required this.timestamp,
  });
}

final class ReviewContentPlayingAudioState extends ReviewContentState {
  final String contentTaskTargetId;
  final String contentId;
  final String? message;

  ReviewContentPlayingAudioState({
    required this.contentTaskTargetId, 
    required this.contentId, 
    this.message
  });
}

final class ReviewContentAudioSuccessState extends ReviewContentState {
  final String contentTaskTargetId;
  final String contentId;

  ReviewContentAudioSuccessState({required this.contentTaskTargetId, required this.contentId});
}

final class ReviewContentAudioErrorState extends ReviewContentState {
  final String message;
  final String contentTaskTargetId;
  final String contentId;

  ReviewContentAudioErrorState({
    required this.message, 
    required this.contentTaskTargetId, 
    required this.contentId
  });
}

class TileSelectionState extends ReviewContentState {
  final int selectedTileIndex;

  TileSelectionState({this.selectedTileIndex = -1}); // Default to no selection
}