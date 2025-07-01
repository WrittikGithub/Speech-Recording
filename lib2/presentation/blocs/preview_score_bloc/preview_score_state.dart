part of 'preview_score_bloc.dart';

@immutable
sealed class PreviewScoreState {}

final class PreviewScoreInitial extends PreviewScoreState {}

final class PreviewScoreLoadingState extends PreviewScoreState {}

final class PreviewScoreSuccessState extends PreviewScoreState {
  final List<PreviewScoremodel> previewScores;

  PreviewScoreSuccessState({required this.previewScores});
}

final class PreviewScoreErrorState extends PreviewScoreState {
  final String message;

  PreviewScoreErrorState({required this.message});
}
