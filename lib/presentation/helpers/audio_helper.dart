import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AudioHelper {
  static final Map<String, String> _cachedFiles = {};
  
  /// Downloads a file from a URL and returns the local path
  static Future<String?> downloadAndCacheFile(String url) async {
    try {
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/audio_cache');
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final localPath = '${cacheDir.path}/$fileName';
      final file = File(localPath);
      
      // Check if file already exists
      if (await file.exists()) {
        return localPath;
      }
      
      final client = http.Client();
      try {
        final response = await client.get(uri)
            .timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          return localPath;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print("Error downloading file: $e");
    }
    return null;
  }
  
  /// Clears the cached files
  static Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/audio_cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      
      _cachedFiles.clear();
      print("Audio cache cleared");
    } catch (e) {
      print("Error clearing audio cache: $e");
    }
  }
  
  /// Creates a properly formatted URL for audio access
  static String getProperAudioUrl(String projectName, String taskId, String fileName, String taskTargetId) {
    // Properly encode all URL components to handle spaces and special characters
    String sanitizedProjectName = Uri.encodeComponent(projectName.replaceAll(' ', '_'));
    String encodedTaskId = Uri.encodeComponent(taskId);
    
    // Default to uploads format which seems to work based on logs
    String userId = "9"; // Based on logs
    String language = "hi"; // Based on logs
    
    return 'https://vacha.langlex.com/uploads/ref_u_${userId}_${sanitizedProjectName}_${encodedTaskId}_TTI_${taskTargetId}_$language.wav';
  }
} 