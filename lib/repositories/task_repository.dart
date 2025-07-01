// New methods to check and download audio content
Future<bool> checkContentHasAudio(String contentId) async {
  try {
    final response = await _apiService.post(
      '/task/content/check',
      {
        'content_id': contentId,
      },
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['has_audio'] == true;
    }
    return false;
  } catch (e) {
    print("Error checking content audio: $e");
    return false;
  }
}

Future<String?> downloadAudioContent({
  required String contentId,
  required String taskTargetId,
}) async {
  try {
    final response = await _apiService.post(
      '/task/content/download',
      {
        'content_id': contentId,
        'task_target_id': taskTargetId,
      },
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['audio_base64'];
    }
    return null;
  } catch (e) {
    print("Error downloading audio content: $e");
    return null;
  }
} 