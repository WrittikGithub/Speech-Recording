import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sdcp_rebuild/domain/databases/content_database_helper.dart';
import 'package:sdcp_rebuild/domain/databases/review_content_database_helper.dart';
import 'package:sdcp_rebuild/domain/databases/review_database_helper.dart';

import 'package:sdcp_rebuild/domain/databases/task_database_helper.dart';

class LocalDataCleaner {
  static final LocalDataCleaner _instance = LocalDataCleaner._internal();
  factory LocalDataCleaner() => _instance;
  LocalDataCleaner._internal();

  Future<void> clearAllLocalData() async {
    try {
      print("Starting to clear all local data...");

      // Clear SQLite databases
      await _clearDatabases();

      // Clear app directory files
      await _clearAppDirectoryFiles();

      print("Successfully cleared all local data");
    } catch (e) {
      print("Error clearing local data: $e");
      rethrow;
    }
  }

  Future<void> _clearDatabases() async {
    print("Clearing databases...");

    // Clear Tasks database
    final databaseHelper = DatabaseHelper();
    await databaseHelper.clearAllTasks();
    final reviewContentDbHelper = ReviewContentDatabaseHelper();
    await reviewContentDbHelper.clearAllContents();
    final contentDbHelper = ContentDatabaseHelper();
    await contentDbHelper.clearAllContents();
  final reviewdatabaseHelper = ReviewsDatabaseHelper();
  await reviewdatabaseHelper.clearAllReviews();
 
    // Clear Contents database (if you have one)
    //   final contentDbHelper = ContentDatabaseHelper();
    //   // ignore: unnecessary_null_comparison
    //   if (contentDbHelper != null) {
    //     final db = await contentDbHelper.database;
    //     await db.delete('contents');
    //   }
  }

  Future<void> _clearAppDirectoryFiles() async {
    print("Clearing app directory files...");
    final appDir = await getApplicationDocumentsDirectory();

    // List of directories to clear
    final directoriesToClear = [
      'recordings', // Add this for audio dashboard recordings
      'recording', // Audio recordings
      'review_audio_files', // Review audio files
      'review_image_files', // Review image files
      'base64_audio', // Base64 encoded audio files
    ];

    for (String dirName in directoriesToClear) {
      final dir = Directory('${appDir.path}/$dirName');
      if (await dir.exists()) {
        print("Clearing directory: $dirName");
        await dir.delete(recursive: true);
      }
    }

    // Optional: Clear temporary files
    final tempDir = await getTemporaryDirectory();
    if (await tempDir.exists()) {
      print("Clearing temporary directory");
      await tempDir.delete(recursive: true);
    }
  }
}
