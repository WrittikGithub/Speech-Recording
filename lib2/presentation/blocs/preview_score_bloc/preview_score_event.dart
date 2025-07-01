part of 'preview_score_bloc.dart';

@immutable
sealed class PreviewScoreEvent {}

final class PreviewScoreButtonClickEvent extends PreviewScoreEvent {
  final String taskTargetId;

  PreviewScoreButtonClickEvent({required this.taskTargetId});
}
