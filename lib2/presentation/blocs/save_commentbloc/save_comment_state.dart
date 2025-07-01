part of 'save_comment_bloc.dart';

@immutable
sealed class SaveCommentState {}

final class SaveCommentInitial extends SaveCommentState {}

final class SaveCommentLoadingState extends SaveCommentState {}

final class SaveCommentSuccessState extends SaveCommentState {}

final class SaveCommentErrorState extends SaveCommentState {
  final String message;

  SaveCommentErrorState({required this.message});
}
