part of 'content_task_target_id_bloc.dart';

@immutable
sealed class ContentTaskTargetIdState {}

final class ContentTaskTargetIdInitial extends ContentTaskTargetIdState {}

final class ContentTasktargetIdLoadingState extends ContentTaskTargetIdState {}

final class ContentTaskTargetSuccessState extends ContentTaskTargetIdState {
  final List<ContentModel> contentlist;

  ContentTaskTargetSuccessState({required this.contentlist});
}

final class ContentTaskTargetErrrorState extends ContentTaskTargetIdState {
  final String message;
  final String? contentTaskTargetId;

  ContentTaskTargetErrrorState({
    required this.message, 
    this.contentTaskTargetId
  });
}

final class ContentDownloadingState extends ContentTaskTargetIdState {
  final String contentTaskTargetId;

  ContentDownloadingState({required this.contentTaskTargetId});
}

final class ContentDownloadSuccessState extends ContentTaskTargetIdState {
  final String contentTaskTargetId;

  ContentDownloadSuccessState({required this.contentTaskTargetId});
}
