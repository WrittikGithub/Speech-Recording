part of 'save_feedback_bloc.dart';

@immutable
sealed class SaveFeedbackState {}

final class SaveFeedbackInitial extends SaveFeedbackState {}

final class SaveFeedbackLoadingState extends SaveFeedbackState {}

final class SaveFeedbackSuccessState extends SaveFeedbackState {}

final class SaveFeedbackErrorState extends SaveFeedbackState {
  final String message;

  SaveFeedbackErrorState({required this.message});
}
