part of 'save_review_bloc.dart';

@immutable
sealed class SaveReviewEvent {}

final class SaveRviewButtonclickEvent extends SaveReviewEvent {
  final SaveReviewModel reviews;

  SaveRviewButtonclickEvent({required this.reviews});
}
