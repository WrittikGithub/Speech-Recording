import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/review_content_model.dart';
import 'package:sdcp_rebuild/domain/repositories/reviewsrepo.dart';
import 'package:sdcp_rebuild/presentation/widgets/audio_player_service.dart';
import 'package:logger/logger.dart';

part 'review_content_event.dart';
part 'review_content_state.dart';

class ReviewContentBloc extends Bloc<ReviewContentEvent, ReviewContentState> {
  final Reviewsrepo repository;
  final Logger _logger = Logger();
  
  ReviewContentBloc({required this.repository})
      : super(ReviewContentInitial()) {
    on<ReviewContentEvent>((event, emit) {});
    on<ReviewContentFetchingInitialEvent>(fetchreviewcontent);
    on<ReviewContentDownloadingEvent>(downloadreviewcontent);
    on<ReviewContentPlayAudioEvent>(playAudioContent);
    on<SelectTileEvent>(selectTile);
  }

  FutureOr<void> fetchreviewcontent(ReviewContentFetchingInitialEvent event,
      Emitter<ReviewContentState> emit) async {
    emit(ReviewContentLoadingState());
    final response =
        await repository.fetchcreviewcontent(taskTargetId: event.taskTargetId);
    if (!response.error && response.status == 200) {
      emit(ReviewContentSuccessState(contentlist: response.data!));
    } else {
      emit(ReviewContentErrrorState(message: response.message));
    }
  }
  

  FutureOr<void> downloadreviewcontent(ReviewContentDownloadingEvent event, Emitter<ReviewContentState> emit) async {
    try {
      // Emit downloading state
      emit(ReviewContentDownloadingState(
        contentTaskTargetId: event.taskTargetId
      ));
      
      // Download the content
      await repository.syncReviewContentsForTask(event.taskTargetId);
      
      // Ensure there's enough time for UI to process state changes
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Emit success state with unique timestamp to force rebuilds
      emit(ReviewContentDownloadSuccessState(
        contentTaskTargetId: event.taskTargetId,
        timestamp: DateTime.now().millisecondsSinceEpoch
      ));
    } catch (e) {
      emit(ReviewContentErrrorState(
        message: 'Download failed: ${e.toString()}',
        contentTaskTargetId: event.taskTargetId
      ));
    }
  }
  
  FutureOr<void> playAudioContent(ReviewContentPlayAudioEvent event, Emitter<ReviewContentState> emit) async {
    try {
      emit(ReviewContentPlayingAudioState(
        contentTaskTargetId: event.taskTargetId,
        contentId: event.contentId
      ));
      
      // Get content from database
      final reviewContents = await repository.reviewContentDatabaseHelper
          .getContentsByTargetTaskTargetId(event.taskTargetId);
      
      // Find the specific content matching the contentId
      final content = reviewContents.firstWhere(
        (c) => c.contentId == event.contentId,
        orElse: () => throw Exception('Content not found')
      );
      
      String? audioPath;
      
      // Check for audio path
      if (content.targetTargetContentPath.isNotEmpty) {
        audioPath = content.targetTargetContentPath;
      } else if (content.contentReferencePath.isNotEmpty) {
        audioPath = content.contentReferencePath;
      } else {
        throw Exception('No audio source available');
      }
      
      // Verify the audio file exists before attempting to play it
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file not found at path: $audioPath');
      }
      
      // Play using the AudioPlayerService
      final success = await AudioPlayerService.playAudio(audioPath, onComplete: () {
        print("Review audio playback completed");
      });
      
      if (!success) {
        throw Exception('Failed to play audio using AudioPlayerService');
      }
      
      emit(ReviewContentAudioSuccessState(
        contentTaskTargetId: event.taskTargetId,
        contentId: event.contentId
      ));
    } catch (e) {
      _logger.e('Error playing audio content: $e');
      emit(ReviewContentAudioErrorState(
        contentTaskTargetId: event.taskTargetId,
        contentId: event.contentId,
        message: 'Could not play audio: ${e.toString()}',
      ));
    }
  }

  FutureOr<void> selectTile(SelectTileEvent event, Emitter<ReviewContentState> emit) {
    emit(TileSelectionState(selectedTileIndex: event.tileIndex));
  }

  @override
  Future<void> close() {
    repository.dispose();
    return super.close();
  }
}
