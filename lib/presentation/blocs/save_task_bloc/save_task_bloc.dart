import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sdcp_rebuild/domain/repositories/taskrepo.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';

part 'save_task_event.dart';
part 'save_task_state.dart';

class SaveTaskBloc extends Bloc<SaveTaskEvent, SaveTaskState> {
  final Taskrepo repository;
  SaveTaskBloc({required this.repository}) : super(SaveTaskInitial()) {
    on<SaveTaskEvent>((event, emit) {});
    on<SaveTaskButtonclickingEvent>(_onSaveTask);
  }

  FutureOr<void> _onSaveTask(
      SaveTaskButtonclickingEvent event, Emitter<SaveTaskState> emit) async {
    try {
      print("🔄 [SaveTaskBloc] Starting save task for contentId: ${event.saveData.contentId}");
      emit(SaveTaskLoadingState());
      
      final response = await repository.saveTask(taskRecord: event.saveData);
      print("🔄 [SaveTaskBloc] Server response: status=${response.status}, error=${response.error}, message=${response.message}");
      
      if (!response.error && response.status == 200) {
        // Extract the server URL from the response if it exists
        String? serverUrl;
        if (response.data != null && response.data is Map) {
          // Try different possible keys for the server URL
          final responseMap = response.data as Map;
          serverUrl = responseMap['audioUrl'] as String? ?? 
                     responseMap['fileUrl'] as String? ?? 
                     responseMap['serverUrl'] as String? ??
                     responseMap['url'] as String?;
                     
          print("🔄 [SaveTaskBloc] Extracted serverUrl from response: $serverUrl");
          print("🔄 [SaveTaskBloc] Full response data: $responseMap");
        }
        
        // If we have a contentId and serverUrl, update the database
        if (serverUrl != null) {
          print("🔄 [SaveTaskBloc] Updating database with serverUrl for contentId: ${event.saveData.contentId}");
          await _updateAudioUrlInDatabase(
            event.saveData.contentId, 
            serverUrl
          );
          
          // Additionally, try to update the content status directly in the database
          try {
            final dbHelper = ContentDatabaseHelper();
            await dbHelper.updateContentStatus(
              contentId: event.saveData.contentId,
              status: "SAVED"
            );
            print("✅ [SaveTaskBloc] Content status updated to SAVED in database");
          } catch (e) {
            print("❌ [SaveTaskBloc] Error updating content status: $e");
          }
          
          // Emit a refresh state to force UI updates
          print("🔄 [SaveTaskBloc] Emitting SaveTaskRefreshNeededState to trigger UI refresh");
          emit(SaveTaskRefreshNeededState(
            message: "Database updated, refresh needed",
            serverUrl: serverUrl
          ));
          
          // Small delay to allow UI to process the refresh state
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        print("✅ [SaveTaskBloc] Emitting SaveTaskSuccessState with serverUrl: $serverUrl");
        emit(SaveTaskSuccessState(
          message: response.message,
          isOffline: false,
          serverUrl: serverUrl // Pass the server URL in the success state
        ));
      } else {
        print("❌ [SaveTaskBloc] Emitting SaveTaskErrorState: ${response.message}");
        emit(SaveTaskErrorState(message: response.message));
      }
    } catch (e) {
      print("❌ [SaveTaskBloc] Exception in _onSaveTask: $e");
      emit(SaveTaskErrorState(message: e.toString()));
    }
  }

  // Helper method to update the database with the server URL
  Future<void> _updateAudioUrlInDatabase(String contentId, String serverUrl) async {
    try {
      final dbHelper = ContentDatabaseHelper();
      
      print("Updating DB with serverUrl: $serverUrl for contentId: $contentId");
      
      // Get the existing audio path to make sure we keep it
      final existingPaths = await dbHelper.getAudioPathsForContent(contentId);
      final existingPath = existingPaths?['localPath'] ?? '';
      
      // Use the existing method with the correct parameters
      await dbHelper.updateContent(
        contentId: contentId,
        audioPath: existingPath, // Keep the existing local path
        base64Audio: '', // We can leave this empty
        serverUrl: serverUrl // Add the server URL
      );
      
      print("Database update completed. Verifying...");
      // Verify the update worked
      final updatedPaths = await dbHelper.getAudioPathsForContent(contentId);
      print("Updated paths: $updatedPaths");
    } catch (e) {
      print("Error updating database with server URL: $e");
    }
  }
}
