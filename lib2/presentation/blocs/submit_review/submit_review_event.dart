part of 'submit_review_bloc.dart';

@immutable
sealed class SubmitReviewEvent {}

final class SubmitReviewButtonClickEvent extends SubmitReviewEvent {
  final String taskTargetId;

  SubmitReviewButtonClickEvent({required this.taskTargetId});


}
