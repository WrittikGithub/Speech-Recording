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

  ReviewContentDownloadSuccessState({required this.contentTaskTargetId});
}