part of 'content_task_target_id_bloc.dart';

@immutable
sealed class ContentTaskTargetIdEvent {}

final class ContentTaskInitialFetchingEvent extends ContentTaskTargetIdEvent {
  final String contentTaskTargetId;
  ContentTaskInitialFetchingEvent({required this.contentTaskTargetId});
}

final class ContentTaskDownloadingEvent extends ContentTaskTargetIdEvent {
  final String contentTaskTargetId;
  ContentTaskDownloadingEvent({required this.contentTaskTargetId});
}