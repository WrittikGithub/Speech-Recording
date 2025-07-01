import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AudioDownloadHelper {
  static final Map<String, String> _cachedFiles = {};
  
  /// Downloads and caches a file from a URL, returns the local file path
  static Future<String?> downloadAndCacheAudio(String url) async {
    try {
      // First check if we've already downloaded this URL
      if (_cachedFiles.containsKey(url)) {
        final cachedPath = _cachedFiles[url]!;
        if (File(cachedPath).existsSync()) {
          final file = File(cachedPath);
          final fileSize = await file.length();
          print("Using cached audio file: $cachedPath (size: $fileSize bytes)");
          
          // Verify the cached file
          if (fileSize < 100) {
            print("Cached file is too small ($fileSize bytes), re-downloading");
          } else {
            return cachedPath;
          }
        }
      }
      
      // Encode the URL properly to handle spaces and special characters
      final uri = Uri.parse(url);
      print("Downloading audio from URL: $url");
      
      // Create a filename from the URL's hash to avoid filename issues
      final urlHash = url.hashCode.abs();
      String fileName;
      
      // Try to preserve original file extension
      if (url.toLowerCase().endsWith('.wav')) {
        fileName = 'audio_$urlHash.wav';
      } else if (url.toLowerCase().endsWith('.mp3')) {
        fileName = 'audio_$urlHash.mp3';
      } else {
        // Default to mp3 as it's more widely supported
        fileName = 'audio_$urlHash.mp3';
      }
      
      // Create cache directory
      final tempDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${tempDir.path}/audio_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final localPath = '${cacheDir.path}/$fileName';
      
      // Check if file already exists in cache
      final file = File(localPath);
      if (await file.exists()) {
        final existingSize = await file.length();
        print("File already cached: $localPath (size: $existingSize bytes)");
        
        // Verify the file is not corrupted
        if (existingSize < 100) {
          print("Existing file is too small, will re-download");
          await file.delete();
        } else {
          _cachedFiles[url] = localPath;
          return localPath;
        }
      }
      
      // Use proper streaming API for better binary data handling
      final client = http.Client();
      try {
        // Create a request with appropriate headers for audio
        final request = http.Request('GET', uri);
        request.headers['Accept'] = 'audio/wav,audio/mp3,audio/*;q=0.9,*/*;q=0.8';
        request.headers['User-Agent'] = 'Flutter/1.0';
        
        // Send the request as a stream
        final response = await client.send(request);
        
        if (response.statusCode == 200) {
          // Get the total content length if available
          final contentLength = response.contentLength ?? -1;
          print("Content length: $contentLength bytes");
          
          // Open a file stream to write the data
          final sink = file.openWrite();
          
          // Save the streamed data to file
          await response.stream.pipe(sink);
          await sink.flush();
          await sink.close();
          
          // Verify the file size
          final fileSize = await file.length();
          print("Downloaded file size: $fileSize bytes");
          
          if (fileSize < 100) {
            print("Downloaded file is too small ($fileSize bytes), likely empty or corrupt");
            await file.delete();
            return null;
          }
          
          // If file is a WAV, check and fix the header if needed
          if (fileName.toLowerCase().endsWith('.wav')) {
            final fixedPath = await fixWavHeader(localPath);
            if (fixedPath != null) {
              print("Fixed WAV header: $fixedPath");
              _cachedFiles[url] = fixedPath;
              return fixedPath;
            }
          }
          
          // Cache the URL -> path mapping
          _cachedFiles[url] = localPath;
          print("Successfully downloaded audio to: $localPath");
          return localPath;
        } else {
          print("Failed to download audio. Status code: ${response.statusCode}");
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print("Error downloading audio: $e");
      return null;
    }
  }
  
  /// Tries to download using a direct API endpoint for Vacha server files
  static Future<String?> downloadVachaServerAudio(String contentId, String taskId, String? taskTargetId, String? languageCode) async {
    try {
      // Construct the API URL
      String apiUrl = 'https://vacha.langlex.com/api/audio/download?contentId=$contentId&taskId=$taskId';
      
      // Add optional parameters
      if (taskTargetId != null && taskTargetId.isNotEmpty) {
        apiUrl += '&taskTargetId=$taskTargetId';
      }
      
      if (languageCode != null && languageCode.isNotEmpty) {
        apiUrl += '&lang=$languageCode';
      }
      
      print("Trying Vacha server API: $apiUrl");
      
      // Create a filename for the downloaded file
      final fileName = 'vacha_${contentId}_${taskId}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      
      // Create cache directory
      final tempDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${tempDir.path}/audio_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final localPath = '${cacheDir.path}/$fileName';
      final file = File(localPath);
      
      // Use proper streaming API
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(apiUrl));
        request.headers['Accept'] = 'audio/mp3,audio/*;q=0.9,*/*;q=0.8';
        request.headers['User-Agent'] = 'Flutter/1.0';
        
        final response = await client.send(request);
        
        if (response.statusCode == 200) {
          // Save the streamed data to file
          final sink = file.openWrite();
          await response.stream.pipe(sink);
          await sink.flush();
          await sink.close();
          
          // Verify the file size
          final fileSize = await file.length();
          print("Downloaded API file size: $fileSize bytes");
          
          if (fileSize < 1000) {
            print("API response is too small ($fileSize bytes), likely not audio");
            await file.delete();
            return null;
          }
          
          _cachedFiles[apiUrl] = localPath;
          print("Successfully downloaded from API to: $localPath");
          return localPath;
        } else {
          print("API request failed. Status code: ${response.statusCode}");
          return null;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      print("Error using Vacha server API: $e");
      return null;
    }
  }
  
  /// Extract task information from a Vacha server URL
  static Map<String, String?> extractVachaUrlInfo(String url) {
    try {
      if (!url.contains('vacha.langlex.com')) {
        return {'contentId': null, 'taskId': null, 'taskTargetId': null, 'language': null};
      }
      
      print("Extracting info from Vacha URL: $url");
      
      final result = {
        'contentId': null as String?,
        'taskId': null as String?,
        'taskTargetId': null as String?,
        'language': null as String?
      };
      
      // Extract the filename
      final urlParts = url.split('/');
      final filename = urlParts.last;
      final filenameParts = filename.split('_');
      
      // The standard format is: ref_u_ID_NAME_TI_ID_TTI_ID_LANG.wav
      if (filenameParts.length >= 9) {
        try {
          // Look for patterns like TI_123 and TTI_456
          for (int i = 0; i < filenameParts.length - 1; i++) {
            if (filenameParts[i] == 'TI') {
              result['taskId'] = filenameParts[i + 1];
            } else if (filenameParts[i] == 'TTI') {
              result['taskTargetId'] = filenameParts[i + 1];
            }
          }
          
          // Get language from extension part
          final dotParts = filename.split('.');
          if (dotParts.length > 1) {
            final langPart = dotParts[0].split('_').last;
            if (langPart.length <= 3) { // Most language codes are 2-3 chars
              result['language'] = langPart;
            }
          }
          
        } catch (e) {
          print("Error parsing filename: $e");
        }
      }
      
      print("Extracted info: $result");
      return result;
    } catch (e) {
      print("Error extracting Vacha URL info: $e");
      return {
        'contentId': null as String?,
        'taskId': null as String?,
        'taskTargetId': null as String?,
        'language': null as String?
      };
    }
  }

  /// Fix a WAV file header to ensure it's playable
  static Future<String?> fixWavHeader(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      // Read the file content
      final bytes = await file.readAsBytes();
      if (bytes.length < 44) {
        print("WAV file too small to fix: ${bytes.length} bytes");
        return null;
      }
      
      // Check if we need to fix the header
      final header = String.fromCharCodes(bytes.sublist(0, 4));
      if (header == 'RIFF') {
        print("WAV header already has RIFF signature, no fix needed");
        return filePath; // Header seems fine
      }
      
      print("WAV header doesn't have RIFF signature, fixing...");
      
      // Create a fixed file path
      final fixedPath = '${filePath.substring(0, filePath.length - 4)}_fixed.wav';
      final fixedFile = File(fixedPath);
      
      // Create a standard WAV header
      final outputData = ByteData(44 + bytes.length);
      
      // RIFF header
      outputData.setUint8(0, 82); // 'R'
      outputData.setUint8(1, 73); // 'I'
      outputData.setUint8(2, 70); // 'F'
      outputData.setUint8(3, 70); // 'F'
      
      // File size - 8
      outputData.setUint32(4, 36 + bytes.length, Endian.little);
      
      // WAVE header
      outputData.setUint8(8, 87);  // 'W'
      outputData.setUint8(9, 65);  // 'A'
      outputData.setUint8(10, 86); // 'V'
      outputData.setUint8(11, 69); // 'E'
      
      // 'fmt ' chunk
      outputData.setUint8(12, 102); // 'f'
      outputData.setUint8(13, 109); // 'm'
      outputData.setUint8(14, 116); // 't'
      outputData.setUint8(15, 32);  // ' '
      
      // fmt chunk size (16 for PCM)
      outputData.setUint32(16, 16, Endian.little);
      
      // Audio format (1 = PCM)
      outputData.setUint16(20, 1, Endian.little);
      
      // Number of channels (1 = mono)
      outputData.setUint16(22, 1, Endian.little);
      
      // Sample rate (44100 Hz)
      outputData.setUint32(24, 44100, Endian.little);
      
      // Byte rate (SampleRate * NumChannels * BitsPerSample/8)
      outputData.setUint32(28, 44100 * 1 * 16 ~/ 8, Endian.little);
      
      // Block align (NumChannels * BitsPerSample/8)
      outputData.setUint16(32, 1 * 16 ~/ 8, Endian.little);
      
      // Bits per sample (16 bits)
      outputData.setUint16(34, 16, Endian.little);
      
      // 'data' chunk
      outputData.setUint8(36, 100); // 'd'
      outputData.setUint8(37, 97);  // 'a'
      outputData.setUint8(38, 116); // 't'
      outputData.setUint8(39, 97);  // 'a'
      
      // Data size
      outputData.setUint32(40, bytes.length, Endian.little);
      
      // Copy the original data after the header
      for (int i = 0; i < bytes.length; i++) {
        outputData.setUint8(44 + i, bytes[i]);
      }
      
      // Write the fixed file
      await fixedFile.writeAsBytes(outputData.buffer.asUint8List());
      
      // Verify the file was written
      if (await fixedFile.exists()) {
        final size = await fixedFile.length();
        print("Fixed WAV file saved, size: $size bytes");
        return fixedPath;
      }
      
      return null;
    } catch (e) {
      print("Error fixing WAV header: $e");
      return null;
    }
  }
  
  /// Convert a WAV file to MP3 format if possible
  static Future<String?> convertToMp3(String wavPath) async {
    // This would need an external library to implement
    // For now, it returns null as we don't have a converter yet
    return null;
  }
} 