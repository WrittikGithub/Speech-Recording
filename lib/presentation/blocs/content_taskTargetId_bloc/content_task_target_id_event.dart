part of 'content_task_target_id_bloc.dart';

@immutable
abstract class ContentTaskTargetIdEvent {
  const ContentTaskTargetIdEvent();
}

class ContentTaskTargetIdButtonclickingEvent extends ContentTaskTargetIdEvent {
  final String contentTaskTargetId;
  
  const ContentTaskTargetIdButtonclickingEvent({
    required this.contentTaskTargetId,
  });
}

class ContentTaskInitialFetchingEvent extends ContentTaskTargetIdEvent {
  final String contentTaskTargetId;

  const ContentTaskInitialFetchingEvent({
    required this.contentTaskTargetId,
  });
}

class ContentTaskDownloadingEvent extends ContentTaskTargetIdEvent {
  final String contentTaskTargetId;

  const ContentTaskDownloadingEvent({
    required this.contentTaskTargetId,
  });
}

class ContentTaskTargetIdLoadingEvent extends ContentTaskTargetIdEvent {
  final String contentTaskTargetId;

  const ContentTaskTargetIdLoadingEvent({
    required this.contentTaskTargetId,
  });
}

// New event for updating content status directly
class ContentTaskTargetIdUpdateStatusEvent extends ContentTaskTargetIdEvent {
  final String contentId;
  final String taskTargetId;
  final String newStatus;

  const ContentTaskTargetIdUpdateStatusEvent({
    required this.contentId,
    required this.taskTargetId,
    required this.newStatus,
  });
}