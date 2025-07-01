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
    on<ContentTaskInitialFetchingEvent>(fetchtasks);
    on<ContentTaskDownloadingEvent>(downloadtask);
    on<ContentTaskTargetIdLoadingEvent>(_handleLoadingEvent);
    on<ContentTaskTargetIdUpdateStatusEvent>(updateContentStatus);
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
    // Emit downloading state
    emit(ContentDownloadingState(
      contentTaskTargetId: event.contentTaskTargetId
    ));

    // This is the important part - make sure we're properly downloading the content
    await repository.syncContentsForTask(event.contentTaskTargetId);
    
    // Add a delay to ensure UI catches up
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Emit success state
    emit(ContentDownloadSuccessState(
      contentTaskTargetId: event.contentTaskTargetId
    ));
  } catch (e) {
    emit(ContentTaskTargetErrrorState(
      message: 'Download failed: ${e.toString()}', 
      contentTaskTargetId: event.contentTaskTargetId
    ));
  }
}

// Add separate handler for loading event
FutureOr<void> _handleLoadingEvent(
  ContentTaskTargetIdLoadingEvent event,
  Emitter<ContentTaskTargetIdState> emit
) async {
  emit(ContentTasktargetIdLoadingState());
  final response = await repository.fetchContentsWithTaskTargetId(
      taskTargetId: event.contentTaskTargetId,);
  if (!response.error && response.status == 200) {
    emit(ContentTaskTargetSuccessState(contentlist: response.data!));
  } else {
    emit(ContentTaskTargetErrrorState(message: response.message));
  }
}

// Add handler for the new update status event
FutureOr<void> updateContentStatus(
  ContentTaskTargetIdUpdateStatusEvent event,
  Emitter<ContentTaskTargetIdState> emit
) async {
  print("👉 [updateContentStatus] START - contentId: ${event.contentId}, newStatus: ${event.newStatus}");
  
  // Only do this if we're in the success state with content list already loaded
  if (state is ContentTaskTargetSuccessState) {
    print("👉 [updateContentStatus] Current state is ContentTaskTargetSuccessState");
    final currentState = state as ContentTaskTargetSuccessState;
    final contentList = List<ContentModel>.from(currentState.contentlist);
    
    print("👉 [updateContentStatus] Content list size: ${contentList.length}");
    
    // Create a new list with updated content
    List<ContentModel> updatedList = [];
    bool foundContent = false;
    
    for (var content in contentList) {
      if (content.contentId == event.contentId) {
        foundContent = true;
        print("👉 [updateContentStatus] Found matching content: ${content.contentId}");
        print("👉 [updateContentStatus] Old status: ${content.targetDigitizationStatus}, New status: ${event.newStatus}");
        
        // We need to create a new ContentModel since it has final fields
        updatedList.add(ContentModel(
          contentId: content.contentId,
          taskId: content.taskId,
          csid: content.csid,
          sourceContent: content.sourceContent,
          sourceWordCount: content.sourceWordCount,
          sourceCharCount: content.sourceCharCount,
          contentReferenceUrl: content.contentReferenceUrl,
          contentReferencePath: content.contentReferencePath,
          targetLanguageId: content.targetLanguageId,
          targetContentUrl: content.targetContentUrl,
          targetContentPath: content.targetContentPath,
          reviewedContent: content.reviewedContent,
          additionalNotes: content.additionalNotes,
          raiseIssue: content.raiseIssue,
          transLastModifiedBy: content.transLastModifiedBy,
          revLastModifiedBy: content.revLastModifiedBy,
          transLastModifiedDate: content.transLastModifiedDate,
          revLastModifiedDate: content.revLastModifiedDate,
          reviewScoreStatus: content.reviewScoreStatus,
          targetDigitizationStatus: event.newStatus, // Use the new status here
          targetreviewerReviewStatus: content.targetreviewerReviewStatus,
          taskTargetId: content.taskTargetId,
          projectName: content.projectName,
        ));
      } else {
        updatedList.add(content);
      }
    }
    
    if (!foundContent) {
      print("❌ [updateContentStatus] Did NOT find content with ID: ${event.contentId}");
      print("👉 [updateContentStatus] Available content IDs: ${contentList.map((e) => e.contentId).join(', ')}");
    }
    
    // Emit a new success state with the updated content list
    print("👉 [updateContentStatus] Emitting new state with updated content list");
    emit(ContentTaskTargetSuccessState(contentlist: updatedList));
    print("✅ [updateContentStatus] DONE - ContentTaskTargetSuccessState emitted");
  } else {
    print("❌ [updateContentStatus] Current state is NOT ContentTaskTargetSuccessState: ${state.runtimeType}");
  }
}

}
