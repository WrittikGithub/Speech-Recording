import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/content_model.dart';

import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';

part 'content_task_target_id_event.dart';
part 'content_task_target_id_state.dart';

class ContentTaskTargetIdBloc
    extends Bloc<ContentTaskTargetIdEvent, ContentTaskTargetIdState> {
  final Taskrepo repository;
  ContentTaskTargetIdBloc({required this.repository})
      : super(ContentTaskTargetIdInitial()) {
    on<ContentTaskTargetIdEvent>((event, emit) {});
    on<ContentTaskInitialFetchingEvent>(fetchtasks);
    on<ContentTaskDownloadingEvent>(downloadtask);
  }

  FutureOr<void> fetchtasks(ContentTaskInitialFetchingEvent event,
      Emitter<ContentTaskTargetIdState> emit) async {
    emit(ContentTasktargetIdLoadingState());
    final response = await repository.fetchContentsWithTaskTargetId(
        taskTargetId: event.contentTaskTargetId,);
    if (!response.error && response.status == 200) {
      emit(ContentTaskTargetSuccessState(contentlist: response.data!));
    } else {
      emit(ContentTaskTargetErrrorState(message: response.message));
    }
  }

FutureOr<void> downloadtask(
    ContentTaskDownloadingEvent event, 
    Emitter<ContentTaskTargetIdState> emit) async {
  try {
    emit(ContentDownloadingState(
      contentTaskTargetId: event.contentTaskTargetId
    ));

    await repository.syncContentsForTask(event.contentTaskTargetId);

    emit(ContentDownloadSuccessState(
      contentTaskTargetId: event.contentTaskTargetId
    ));
  } catch (e) {
    emit(ContentTaskTargetErrrorState(
      message: 'Download failed', 
      contentTaskTargetId: event.contentTaskTargetId
    ));
  }
}


}
