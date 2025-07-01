Stream<SaveTaskState> _mapSaveAudioToState(
    SaveTaskState currentState, SaveTaskEvent event) async* {
  final SaveAudioEvent saveAudioEvent = event as SaveAudioEvent;

  yield currentState.copyWith(
    saveTaskStatus: SaveTaskStatus.loading,
    contentId: saveAudioEvent.contentId,
    localUrl: saveAudioEvent.audioUrl,
  );

  print('[SaveTaskBloc] Starting to save audio with contentId: ${saveAudioEvent.contentId}');

  try {
    final HttpResponse response =
        await taskRepositoryImpl.saveAudio(saveAudioEvent.audioUrl,
            saveAudioEvent.contentId, saveAudioEvent.taskId, true);

    print('[SaveTaskBloc] Save audio response: ${response.response.statusCode}');
    print('[SaveTaskBloc] Response data: ${response.data}');

    // Get the URL from the response if available
    String? serverUrl;
    try {
      if (response.data is Map && response.data.containsKey('fileUrl')) {
        serverUrl = response.data['fileUrl'];
        print('[SaveTaskBloc] Extracted server URL: $serverUrl');
      }
    } catch (e) {
      print('[SaveTaskBloc] Error extracting server URL: $e');
    }

    if (response.response.statusCode == 200) {
      print('[SaveTaskBloc] Save audio successful');
      
      // First update the state with the server URL
      yield currentState.copyWith(
        saveTaskStatus: SaveTaskStatus.success,
        serverUrl: serverUrl,
      );
      
      // Then refresh the content to make sure UI gets updated
      print('[SaveTaskBloc] Triggering content refresh after successful save');
      
      try {
        // Directly mark content as completed by updating its status
        await taskRepositoryImpl.updateContentStatusAsSaved(
          saveAudioEvent.contentId,
        );
        print('[SaveTaskBloc] Content marked as saved in database');
      } catch (e) {
        print('[SaveTaskBloc] Error updating content status: $e');
      }
      
      // Emit a refresh state to force UI updates
      yield currentState.copyWith(
        saveTaskStatus: SaveTaskStatus.refreshNeeded,
        serverUrl: serverUrl,
      );
      
      // Then revert to success state
      yield currentState.copyWith(
        saveTaskStatus: SaveTaskStatus.success,
        serverUrl: serverUrl,
      );
    } else {
      print('[SaveTaskBloc] Save audio failed with status code: ${response.response.statusCode}');
      yield currentState.copyWith(
        saveTaskStatus: SaveTaskStatus.failure,
        error: 'Failed to save audio: ${response.response.statusCode}',
      );
    }
  } catch (error) {
    print('[SaveTaskBloc] Error saving audio: $error');
    yield currentState.copyWith(
      saveTaskStatus: SaveTaskStatus.failure,
      error: error.toString(),
    );
  }
} 