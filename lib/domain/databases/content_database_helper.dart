//////////////////////////////
library;
import 'package:sdcp_rebuild/data/content_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
// class ContentDatabaseHelper {
//   static final ContentDatabaseHelper _instance = ContentDatabaseHelper._internal();
//   static Database? _database;
//   static const String audioBaseUrl = 'https://vacha.langlex.com/';
  
//   factory ContentDatabaseHelper() => _instance;
//   ContentDatabaseHelper._internal();

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     String path = join(await getDatabasesPath(), 'content_database.db');
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: (Database db, int version) async {
//         await db.execute('''
//           CREATE TABLE contents(
//             contentId TEXT PRIMARY KEY,
//             taskId TEXT,
//             csid TEXT,
//             sourceContent TEXT,
//             sourceWordCount TEXT,
//             sourceCharCount TEXT,
//             contentReferenceUrl TEXT,
//             contentReferencePath TEXT,
//             targetLanguageId TEXT,
//             targetContentUrl TEXT,
//             targetContentPath TEXT,
//             reviewedContent TEXT,
//             additionalNotes TEXT,
//             raiseIssue TEXT,
//             transLastModifiedBy TEXT,
//             revLastModifiedBy TEXT,
//             transLastModifiedDate TEXT,
//             revLastModifiedDate TEXT,
//             reviewScoreStatus TEXT,
//             targetDigitizationStatus TEXT,
//             targetreviewerReviewStatus TEXT,
//             taskTargetId TEXT,
//             projectName TEXT,
//             lastSyncTime INTEGER
//           )
//         ''');
//            print("Contents table created successfully.");
//       },
//     );
//   }

//   Future<String> _getLocalPath(String type) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final mediaDir = Directory('${directory.path}/${type}_files');
//     if (!await mediaDir.exists()) {
//        print("Creating directory for $type files...");
//       await mediaDir.create(recursive: true);
//     }
//         print("$type directory path: ${mediaDir.path}");
//     return mediaDir.path;
//   }

//   bool _isAudioFile(String url) {
//     return url.toLowerCase().endsWith('.wav') || 
//            url.startsWith('uploads/') || 
//            url.startsWith('rspeech/');
//   }

//   bool _isImageFile(String url) {
//     final validImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
//     final lowercaseUrl = url.toLowerCase();
//     return url.startsWith('http') && 
//            validImageExtensions.any((ext) => lowercaseUrl.endsWith(ext));
//   }

//   Future<String?> _downloadFile(String url, String type) async {
//     try {
//          print("Downloading $type file from: $url");
//       final client = http.Client();
//       final Uri uri;
      
//       if (type == 'audio' && !url.startsWith('http')) {
//         uri = Uri.parse('$audioBaseUrl$url');
//       } else {
//         uri = Uri.parse(url);
//       }

//       final response = await client.get(uri);
      
//       if (response.statusCode == 200) {
//         final localPath = await _getLocalPath(type);
//         final fileName = url.split('/').last;
//         final filePath = '$localPath/$fileName';
        
//         File file = File(filePath);
//         await file.writeAsBytes(response.bodyBytes);
//           print("$type file downloaded and saved to: $filePath");
//         return filePath;
//       }
//       return null;
//     } catch (e) {
//       print('Error downloading $type file: $e');
//       return null;
//     }
//   }

//   Future<Map<String, String?>> _downloadMedia(String contentReferenceUrl, String targetContentUrl) async {
//        print("Downloading media files...");
//     String? contentReferencePath;
//     String? targetContentPath;

//     if (_isImageFile(contentReferenceUrl)) {
//       contentReferencePath = await _downloadFile(contentReferenceUrl, 'images');
//     }

//     if (_isAudioFile(targetContentUrl)) {
//       targetContentPath = await _downloadFile(targetContentUrl, 'audio');
//     }
//   print("Media download complete. Reference path: $contentReferencePath, Target path: $targetContentPath");
//     return {
//       'contentReferencePath': contentReferencePath,
//       'targetContentPath': targetContentPath,
//     };
//   }

//   Future<void> insertContent(ContentModel content) async {
//     final Database db = await database;
//         print("Inserting content: ${content.contentId}");
//     final mediaFiles = await _downloadMedia(content.contentReferenceUrl, content.targetContentUrl);

//     await db.insert(
//       'contents',
//       {
//         'contentId': content.contentId,
//         'taskId': content.taskId,
//         'csid': content.csid,
//         'sourceContent': content.sourceContent,
//         'sourceWordCount': content.sourceWordCount,
//         'sourceCharCount': content.sourceCharCount,
//         'contentReferenceUrl': content.contentReferenceUrl,
//         'contentReferencePath': mediaFiles['contentReferencePath'] ?? content.contentReferencePath,
//         'targetLanguageId': content.targetLanguageId,
//         'targetContentUrl': content.targetContentUrl,
//         'targetContentPath': mediaFiles['targetContentPath'] ?? content.targetContentPath,
//         'reviewedContent': content.reviewedContent,
//         'additionalNotes': content.additionalNotes,
//         'raiseIssue': content.raiseIssue,
//         'transLastModifiedBy': content.transLastModifiedBy,
//         'revLastModifiedBy': content.revLastModifiedBy,
//         'transLastModifiedDate': content.transLastModifiedDate,
//         'revLastModifiedDate': content.revLastModifiedDate,
//         'reviewScoreStatus': content.reviewScoreStatus,
//         'targetDigitizationStatus': content.targetDigitizationStatus,
//         'targetreviewerReviewStatus': content.targetreviewerReviewStatus,
//         'taskTargetId': content.taskTargetId,
//         'projectName': content.projectName,
//         'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
//       },
//       conflictAlgorithm: ConflictAlgorithm.replace,
      
//     );
//        print("Content inserted successfully.");
//   }

//   Future<void> insertContents(List<ContentModel> contents) async {
//     final Database db = await database;
//     final Batch batch = db.batch();

//     for (var content in contents) {
//       final mediaFiles = await _downloadMedia(content.contentReferenceUrl, content.targetContentUrl);

//       batch.insert(
//         'contents',
//         {
//           'contentId': content.contentId,
//           'taskId': content.taskId,
//           'csid': content.csid,
//           'sourceContent': content.sourceContent,
//           'sourceWordCount': content.sourceWordCount,
//           'sourceCharCount': content.sourceCharCount,
//           'contentReferenceUrl': content.contentReferenceUrl,
//           'contentReferencePath': mediaFiles['contentReferencePath'] ?? content.contentReferencePath,
//           'targetLanguageId': content.targetLanguageId,
//           'targetContentUrl': content.targetContentUrl,
//           'targetContentPath': mediaFiles['targetContentPath'] ?? content.targetContentPath,
//           'reviewedContent': content.reviewedContent,
//           'additionalNotes': content.additionalNotes,
//           'raiseIssue': content.raiseIssue,
//           'transLastModifiedBy': content.transLastModifiedBy,
//           'revLastModifiedBy': content.revLastModifiedBy,
//           'transLastModifiedDate': content.transLastModifiedDate,
//           'revLastModifiedDate': content.revLastModifiedDate,
//           'reviewScoreStatus': content.reviewScoreStatus,
//           'targetDigitizationStatus': content.targetDigitizationStatus,
//           'targetreviewerReviewStatus': content.targetreviewerReviewStatus,
//           'taskTargetId': content.taskTargetId,
//           'projectName': content.projectName,
//           'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
//     }

//     await batch.commit(noResult: true);
//   }

//   Future<List<ContentModel>> getContentsByTaskTargetId(String taskTargetId) async {
//     final Database db = await database;
//     final List<Map<String, dynamic>> maps = await db.query(
//       'contents',
//       where: 'taskTargetId = ?',
//       whereArgs: [taskTargetId],
//     );

//     return List.generate(maps.length, (i) {
//       return ContentModel(
//         contentId: maps[i]['contentId'] ?? '',
//         taskId: maps[i]['taskId'] ?? '',
//         csid: maps[i]['csid'] ?? '',
//         sourceContent: maps[i]['sourceContent'] ?? '',
//         sourceWordCount: maps[i]['sourceWordCount'] ?? '',
//         sourceCharCount: maps[i]['sourceCharCount'] ?? '',
//         contentReferenceUrl: maps[i]['contentReferenceUrl'] ?? '',
//         contentReferencePath: maps[i]['contentReferencePath'] ?? '',
//         targetLanguageId: maps[i]['targetLanguageId'] ?? '',
//         targetContentUrl: maps[i]['targetContentUrl'] ?? '',
//         targetContentPath: maps[i]['targetContentPath'] ?? '',
//         reviewedContent: maps[i]['reviewedContent'],
//         additionalNotes: maps[i]['additionalNotes'],
//         raiseIssue: maps[i]['raiseIssue'],
//         transLastModifiedBy: maps[i]['transLastModifiedBy'],
//         revLastModifiedBy: maps[i]['revLastModifiedBy'],
//         transLastModifiedDate: maps[i]['transLastModifiedDate'],
//         revLastModifiedDate: maps[i]['revLastModifiedDate'],
//         reviewScoreStatus: maps[i]['reviewScoreStatus'] ?? '',
//         targetDigitizationStatus: maps[i]['targetDigitizationStatus'] ?? '',
//         targetreviewerReviewStatus: maps[i]['targetreviewerReviewStatus'],
//         taskTargetId: maps[i]['taskTargetId'] ?? '',
//         projectName: maps[i]['projectName'] ?? '',
//       );
//     });
    
    
//   }
//   Future<void> deleteContentsByTaskTargetId(String taskTargetId) async {
//       print("Deleting contents for taskTargetId: $taskTargetId");
//   final Database db = await database;
  
//   // First get all contents for this taskTargetId to delete their media files
//   final List<Map<String, dynamic>> contents = await db.query(
//     'contents',
//     where: 'taskTargetId = ?',
//     whereArgs: [taskTargetId],
//   );

//   // Delete associated media files
//   for (var content in contents) {
//     final contentReferencePath = content['contentReferencePath'];
//     final targetContentPath = content['targetContentPath'];
    
//     if (contentReferencePath != null) {
//       final referenceFile = File(contentReferencePath);
//       if (await referenceFile.exists()) {
//         await referenceFile.delete();
//       }
//     }
    
//     if (targetContentPath != null) {
//       final targetFile = File(targetContentPath);
//       if (await targetFile.exists()) {
//         await targetFile.delete();
//       }
//     }
//   }

//   // Delete the database records
//   await db.delete(
//     'contents',
//     where: 'taskTargetId = ?',
//     whereArgs: [taskTargetId],
//   );
// }
// Future<void> clearAllContents() async {
//      print("Clearing all contents...");
//   final Database db = await database;
//   await db.delete('contents');
  
//   // Delete all downloaded files
//   final audioDir = Directory(await _getLocalPath('audio'));
//   final imagesDir = Directory(await _getLocalPath('images'));
  
//   if (await audioDir.exists()) {
//     await audioDir.delete(recursive: true);
//   }
//   if (await imagesDir.exists()) {
//     await imagesDir.delete(recursive: true);
//   }
// }
//  Future<String> getAudioDirectory() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final audioDir = Directory('${directory.path}/recorded_audio');
//     if (!await audioDir.exists()) {
//       await audioDir.create(recursive: true);
//     }
//     return audioDir.path;
//   }

//   // Add this method to handle moving the recorded file to permanent storage
//   Future<String> moveRecordingToPermanentStorage(String tempPath) async {
//     try {
//       final audioDir = await getAudioDirectory();
//       final fileName = path.basename(tempPath);
//       final permanentPath = '$audioDir/$fileName';

//       // Copy file to permanent location
//       await File(tempPath).copy(permanentPath);
      
//       return permanentPath;
//     } catch (e) {
//       print('Error moving recording: $e');
//       rethrow;
//     }
//   }
// }
class ContentDatabaseHelper {
  static final ContentDatabaseHelper _instance = ContentDatabaseHelper._internal();
  static Database? _database;
  
  factory ContentDatabaseHelper() => _instance;
  ContentDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'content_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE contents(
            contentId TEXT PRIMARY KEY,
            taskId TEXT,
            csid TEXT,
            sourceContent TEXT,
            sourceWordCount TEXT,
            sourceCharCount TEXT,
            contentReferenceUrl TEXT,
            contentReferencePath TEXT,
            targetLanguageId TEXT,
            targetContentUrl TEXT,
            targetContentPath TEXT,
            reviewedContent TEXT,
            additionalNotes TEXT,
            raiseIssue TEXT,
            transLastModifiedBy TEXT,
            revLastModifiedBy TEXT,
            transLastModifiedDate TEXT,
            revLastModifiedDate TEXT,
            reviewScoreStatus TEXT,
            targetDigitizationStatus TEXT,
            targetreviewerReviewStatus TEXT,
            taskTargetId TEXT,
            projectName TEXT,
            lastSyncTime INTEGER
          )
        ''');
        print("Contents table created successfully.");
      },
    );
  }

  Future<String> _getLocalPath(String type) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${directory.path}/${type}_files');
    if (!await mediaDir.exists()) {
      print("Creating directory for $type files...");
      await mediaDir.create(recursive: true);
    }
    print("$type directory path: ${mediaDir.path}");
    return mediaDir.path;
  }

  bool _isImageFile(String url) {
    final validImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final lowercaseUrl = url.toLowerCase();
    return url.startsWith('http') && 
           validImageExtensions.any((ext) => lowercaseUrl.endsWith(ext));
  }

  Future<String?> _downloadFile(String url) async {
    try {
      print("Downloading image file from: $url");
      final client = http.Client();
      final uri = Uri.parse(url);
      final response = await client.get(uri);
      
      if (response.statusCode == 200) {
        final localPath = await _getLocalPath('images');
        final fileName = url.split('/').last;
        final filePath = '$localPath/$fileName';
        
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print("Image file downloaded and saved to: $filePath");
        return filePath;
      }
      return null;
    } catch (e) {
      print('Error downloading image file: $e');
      return null;
    }
  }

  Future<String?> _downloadContentReferenceImage(String contentReferenceUrl) async {
    print("Checking content reference image...");
    if (_isImageFile(contentReferenceUrl)) {
      return await _downloadFile(contentReferenceUrl);
    }
    return null;
  }

  Future<void> insertContent(ContentModel content) async {
    final Database db = await database;
    print("Inserting content: ${content.contentId}");
    
    // Only download content reference image if it's an image file
    final contentReferencePath = await _downloadContentReferenceImage(content.contentReferenceUrl);

    await db.insert(
      'contents',
      {
        'contentId': content.contentId,
        'taskId': content.taskId,
        'csid': content.csid,
        'sourceContent': content.sourceContent,
        'sourceWordCount': content.sourceWordCount,
        'sourceCharCount': content.sourceCharCount,
        'contentReferenceUrl': content.contentReferenceUrl,
        'contentReferencePath': contentReferencePath ?? content.contentReferencePath,
        'targetLanguageId': content.targetLanguageId,
        'targetContentUrl': content.targetContentUrl,
        'targetContentPath': null, // Set targetContentPath as null by default
        'reviewedContent': content.reviewedContent,
        'additionalNotes': content.additionalNotes,
        'raiseIssue': content.raiseIssue,
        'transLastModifiedBy': content.transLastModifiedBy,
        'revLastModifiedBy': content.revLastModifiedBy,
        'transLastModifiedDate': content.transLastModifiedDate,
        'revLastModifiedDate': content.revLastModifiedDate,
        'reviewScoreStatus': content.reviewScoreStatus,
        'targetDigitizationStatus': content.targetDigitizationStatus,
        'targetreviewerReviewStatus': content.targetreviewerReviewStatus,
        'taskTargetId': content.taskTargetId,
        'projectName': content.projectName,
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Content inserted successfully.");
  }

  Future<void> insertContents(List<ContentModel> contents) async {
    final Database db = await database;
    final Batch batch = db.batch();

    for (var content in contents) {
      final contentReferencePath = await _downloadContentReferenceImage(content.contentReferenceUrl);

      batch.insert(
        'contents',
        {
          'contentId': content.contentId,
          'taskId': content.taskId,
          'csid': content.csid,
          'sourceContent': content.sourceContent,
          'sourceWordCount': content.sourceWordCount,
          'sourceCharCount': content.sourceCharCount,
          'contentReferenceUrl': content.contentReferenceUrl,
          'contentReferencePath': contentReferencePath ?? content.contentReferencePath,
          'targetLanguageId': content.targetLanguageId,
          'targetContentUrl': content.targetContentUrl,
          'targetContentPath': null, // Set targetContentPath as null by default
          'reviewedContent': content.reviewedContent,
          'additionalNotes': content.additionalNotes,
          'raiseIssue': content.raiseIssue,
          'transLastModifiedBy': content.transLastModifiedBy,
          'revLastModifiedBy': content.revLastModifiedBy,
          'transLastModifiedDate': content.transLastModifiedDate,
          'revLastModifiedDate': content.revLastModifiedDate,
          'reviewScoreStatus': content.reviewScoreStatus,
          'targetDigitizationStatus': content.targetDigitizationStatus,
          'targetreviewerReviewStatus': content.targetreviewerReviewStatus,
          'taskTargetId': content.taskTargetId,
          'projectName': content.projectName,
          'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

   Future<List<ContentModel>> getContentsByTaskTargetId(String taskTargetId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contents',
      where: 'taskTargetId = ?',
      whereArgs: [taskTargetId],
    );

    return List.generate(maps.length, (i) {
      return ContentModel(
        contentId: maps[i]['contentId'] ?? '',
        taskId: maps[i]['taskId'] ?? '',
        csid: maps[i]['csid'] ?? '',
        sourceContent: maps[i]['sourceContent'] ?? '',
        sourceWordCount: maps[i]['sourceWordCount'] ?? '',
        sourceCharCount: maps[i]['sourceCharCount'] ?? '',
        contentReferenceUrl: maps[i]['contentReferenceUrl'] ?? '',
        contentReferencePath: maps[i]['contentReferencePath'] ?? '',
        targetLanguageId: maps[i]['targetLanguageId'] ?? '',
        targetContentUrl: maps[i]['targetContentUrl'] ?? '',
        targetContentPath: maps[i]['targetContentPath'] ?? '',
        reviewedContent: maps[i]['reviewedContent'],
        additionalNotes: maps[i]['additionalNotes'],
        raiseIssue: maps[i]['raiseIssue'],
        transLastModifiedBy: maps[i]['transLastModifiedBy'],
        revLastModifiedBy: maps[i]['revLastModifiedBy'],
        transLastModifiedDate: maps[i]['transLastModifiedDate'],
        revLastModifiedDate: maps[i]['revLastModifiedDate'],
        reviewScoreStatus: maps[i]['reviewScoreStatus'] ?? '',
        targetDigitizationStatus: maps[i]['targetDigitizationStatus'] ?? '',
        targetreviewerReviewStatus: maps[i]['targetreviewerReviewStatus'],
        taskTargetId: maps[i]['taskTargetId'] ?? '',
        projectName: maps[i]['projectName'] ?? '',
        promptSpeechTime: null, // Not stored in database, will be available from fresh API data
      );
    });
    
    
  }
  Future<void> deleteContentsByTaskTargetId(String taskTargetId) async {
      print("Deleting contents for taskTargetId: $taskTargetId");
  final Database db = await database;
  
  // First get all contents for this taskTargetId to delete their media files
  final List<Map<String, dynamic>> contents = await db.query(
    'contents',
    where: 'taskTargetId = ?',
    whereArgs: [taskTargetId],
  );

  // Delete associated media files
  for (var content in contents) {
    final contentReferencePath = content['contentReferencePath'];
    final targetContentPath = content['targetContentPath'];
    
    if (contentReferencePath != null) {
      final referenceFile = File(contentReferencePath);
      if (await referenceFile.exists()) {
        await referenceFile.delete();
      }
    }
    
    if (targetContentPath != null) {
      final targetFile = File(targetContentPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
    }
  }

  // Delete the database records
  await db.delete(
    'contents',
    where: 'taskTargetId = ?',
    whereArgs: [taskTargetId],
  );
}
Future<void> clearAllContents() async {
     print("Clearing all contents...");
  final Database db = await database;
  await db.delete('contents');
  
  // Delete all downloaded files
  final audioDir = Directory(await _getLocalPath('audio'));
  final imagesDir = Directory(await _getLocalPath('images'));
  
  if (await audioDir.exists()) {
    await audioDir.delete(recursive: true);
  }
  if (await imagesDir.exists()) {
    await imagesDir.delete(recursive: true);
  }
}
 Future<String> getAudioDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/recorded_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  // Add this method to handle moving the recorded file to permanent storage
  Future<String> moveRecordingToPermanentStorage(String tempPath) async {
    try {
      final audioDir = await getAudioDirectory();
      final fileName = path.basename(tempPath);
      final permanentPath = '$audioDir/$fileName';
      
      print("📁 [moveRecordingToPermanentStorage] Moving file from $tempPath to $permanentPath");
      
      // First check if source file exists
      final sourceFile = File(tempPath);
      if (!await sourceFile.exists()) {
        throw Exception('Source audio file does not exist: $tempPath');
      }
      
      // Check if destination file already exists
      final destFile = File(permanentPath);
      if (await destFile.exists()) {
        print("📁 [moveRecordingToPermanentStorage] Destination file already exists, will overwrite");
        await destFile.delete();
      }

      // Copy file to permanent location - use copySync for more reliable operation
      final bytesCopied = await sourceFile.length();
      await sourceFile.copy(permanentPath);
      
      // Verify the copy succeeded by checking the file exists and has the correct size
      if (await File(permanentPath).exists()) {
        final destFileSize = await File(permanentPath).length();
        print("📁 [moveRecordingToPermanentStorage] File copied successfully: $bytesCopied bytes, destination size: $destFileSize bytes");
        
        if (destFileSize != bytesCopied) {
          print("📁 [moveRecordingToPermanentStorage] WARNING: File size mismatch after copy");
        }
      } else {
        print("📁 [moveRecordingToPermanentStorage] WARNING: File not found after copy operation");
        
        // Fallback - try using writeAsBytes instead
        print("📁 [moveRecordingToPermanentStorage] Attempting fallback copy method");
        final bytes = await sourceFile.readAsBytes();
        await File(permanentPath).writeAsBytes(bytes);
        
        if (await File(permanentPath).exists()) {
          print("📁 [moveRecordingToPermanentStorage] Fallback copy succeeded");
        } else {
          throw Exception('Failed to copy file using all methods');
        }
      }
      
      return permanentPath;
    } catch (e) {
      print('Error moving recording: $e');
      rethrow;
    }
  }

  Future<int> updateContent({
    required String contentId,
    required String audioPath,
    required String base64Audio,
    String? serverUrl,
  }) async {
    final db = await database;
    
    // Create a map with the values to update
    final Map<String, dynamic> values = {
      'targetContentPath': audioPath,  // Use targetContentPath, not audio_path
    };
    
    // Only add serverUrl if it's provided
    if (serverUrl != null && serverUrl.isNotEmpty) {
      values['targetContentUrl'] = serverUrl;
    }
    
    print("Updating or inserting content with ID: $contentId");
    print("Values to update: $values");
    
    try {
      // Check if the content exists
      final List<Map<String, dynamic>> existingContent = await db.query(
        'contents',
        where: 'contentId = ?',
        whereArgs: [contentId],
      );
      
      if (existingContent.isEmpty) {
        print("Content ID $contentId not found - INSERTING NEW RECORD");
        
        // We need to create a new record with the minimum required fields
        values['contentId'] = contentId;         // Primary key
        values['taskId'] = '';                   // Required field
        values['csid'] = '';                     // Required field
        values['sourceContent'] = '';            // Required field
        values['sourceWordCount'] = '0';         // Required field
        values['sourceCharCount'] = '0';         // Required field
        values['contentReferenceUrl'] = '';      // Required field
        values['targetLanguageId'] = '';         // Required field
        values['reviewScoreStatus'] = '';        // Required field
        values['targetDigitizationStatus'] = ''; // Required field
        values['taskTargetId'] = '';             // Required field
        values['projectName'] = '';              // Required field
        
        // Insert a new record
        final result = await db.insert('contents', values);
        
        // Verify the insert worked
        print("Insert result: $result");
        await dumpContentDetails(contentId);
        
        return result;
      } else {
        print("Found existing content - updating with new values");
        
        // Update existing record
        final result = await db.update(
          'contents',
          values,
          where: 'contentId = ?',
          whereArgs: [contentId],
        );
        
        // Verify the update worked
        print("Update result: $result");
        await dumpContentDetails(contentId);
        
        return result;
      }
    } catch (e) {
      print("DATABASE ERROR: $e");
      return 0;
    }
  }

  Future<void> ensureAudioColumnsExist() async {
    final db = await database;
    
    // Check if columns exist
    var tableInfo = await db.rawQuery("PRAGMA table_info(contents)");
    print("Table columns: $tableInfo");
    
    bool hasAudioPath = tableInfo.any((column) => column['name'] == 'audio_path');
    bool hasBase64Audio = tableInfo.any((column) => column['name'] == 'base64_audio');
    
    // Add columns if they don't exist
    if (!hasAudioPath) {
      print("Adding audio_path column");
      await db.execute("ALTER TABLE contents ADD COLUMN audio_path TEXT");
    }
    
    if (!hasBase64Audio) {
      print("Adding base64_audio column");
      await db.execute("ALTER TABLE contents ADD COLUMN base64_audio TEXT");
    }
  }

  Future<int> updateContentServerUrl({
    required String contentId,
    required String serverUrl,
  }) async {
    final db = await database;
    return await db.update(
      'contents',
      {
        'target_content_url': serverUrl, // This column should store the server URL
      },
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
  }

  Future<Map<String, String>?> getAudioPathsForContent(String contentId) async {
    try {
      final db = await database;
      
      // Query the database for this content
      final List<Map<String, dynamic>> results = await db.query(
        'contents',
        columns: ['targetContentPath', 'targetContentUrl'],
        where: 'contentId = ?',
        whereArgs: [contentId],
      );
      
      if (results.isEmpty) {
        return null;
      }
      
      final content = results.first;
      
      // Create a map with the paths
      Map<String, String> paths = {
        'localPath': content['targetContentPath'] ?? '',
        'serverUrl': content['targetContentUrl'] ?? ''
      };
      
      // Add debugging info
      print("📀 [getAudioPathsForContent] Paths for $contentId: localPath=${paths['localPath']}, serverUrl=${paths['serverUrl']}");
      
      // For local paths, verify the file exists
      if (paths['localPath']?.isNotEmpty == true) {
        final file = File(paths['localPath']!);
        if (!await file.exists()) {
          print("📀 [getAudioPathsForContent] WARNING: Local file does not exist: ${paths['localPath']}");
          paths['localPath'] = ''; // Clear invalid path
        } else {
          print("📀 [getAudioPathsForContent] Local file exists: ${paths['localPath']}");
        }
      }
      
      return paths;
    } catch (e) {
      print("Error getting audio paths for content $contentId: $e");
      return null;
    }
  }

  // Add this method to directly dump database content for debugging
  Future<void> dumpContentDetails(String contentId) async {
    final db = await database;
    
    print("\n--- DATABASE CONTENT DUMP FOR ID: $contentId ---");
    
    // Get table info
    final tableInfo = await db.rawQuery("PRAGMA table_info(contents)");
    print("TABLE SCHEMA:");
    for (var column in tableInfo) {
      print("  ${column['name']} (${column['type']})");
    }
    
    // Get the content record
    final contentRecord = await db.query(
      'contents',
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
    
    if (contentRecord.isEmpty) {
      print("NO RECORD FOUND WITH THIS ID");
    } else {
      print("\nCONTENT RECORD:");
      final record = contentRecord.first;
      for (var key in record.keys) {
        print("  $key: ${record[key]}");
      }
      
      // Check if audio file exists - add proper casting
      final audioPath = record['audio_path'] as String?;
      if (audioPath != null) {
        final file = File(audioPath);
        final exists = await file.exists();
        print("\nAUDIO FILE:");
        print("  Path: $audioPath");
        print("  Exists: $exists");
        if (exists) {
          print("  Size: ${await file.length()} bytes");
          print("  Last Modified: ${(await file.stat()).modified}");
        }
      }
      
      // Check if server URL is valid - add proper casting
      final serverUrl = record['targetContentUrl'] as String?;
      if (serverUrl != null && serverUrl.isNotEmpty) {
        print("\nSERVER URL:");
        print("  URL: $serverUrl");
      }
    }
    
    print("--- END DATABASE CONTENT DUMP ---\n");
  }

  // Add this method to force set an audio path for testing
  Future<bool> forceSetAudioPath(String contentId) async {
    final db = await database;
    
    print("\n=== FORCING AUDIO PATH FOR TESTING ===");
    
    // First check if the content exists
    final contentExists = await db.rawQuery(
      'SELECT COUNT(*) as count FROM contents WHERE contentId = ?', 
      [contentId]
    );
    
    int count = Sqflite.firstIntValue(contentExists) ?? 0;
    if (count == 0) {
      print("Content ID $contentId does not exist in database, creating it");
      // Create a new content record
      await db.insert('contents', {
        'contentId': contentId,
        'taskId': 'test',
        'targetContentUrl': 'https://example.com/test.wav',
        'audio_path': '/data/user/0/com.langlex.speech/app_flutter/test_audio.wav',
      });
      print("Created test content record");
      return true;
    }
    
    // Update the existing content record
    await db.update(
      'contents',
      {
        'targetContentUrl': 'https://example.com/test.wav',
        'audio_path': '/data/user/0/com.langlex.speech/app_flutter/test_audio.wav',
      },
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
    
    print("Updated content with test audio paths");
    return true;
  }

  Future<Map<String, dynamic>?> getContentDetails(String contentId) async {
    final db = await database;
    
    // Debug: print all tables in the database
    print("DEBUG: Listing all tables in database");
    final tablesQuery = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
    for (var table in tablesQuery) {
      print("Table found: ${table['name']}");
    }

    try {
      // Primary lookup in content table
      print("Looking for content_id=$contentId in content table");
      final contentResults = await db.query(
        'content',
        where: 'content_id = ?',
        whereArgs: [contentId],
      );
      
      // Debug: print column names from content table
      if (contentResults.isNotEmpty) {
        print("Content columns: ${contentResults.first.keys.join(', ')}");
      }
      
      Map<String, dynamic>? result;
      if (contentResults.isNotEmpty) {
        result = Map<String, dynamic>.from(contentResults.first);
        print("Found in content table: $result");
      }
      
      // Check all possible tables that might contain audio info
      final possibleTables = ['audio_files', 'content_data', 'audio_content', 'task_files', 'resources'];
      
      for (final tableName in possibleTables) {
        try {
          print("Checking table: $tableName for content_id=$contentId");
          final audioResults = await db.query(
            tableName,
            where: 'content_id = ?',
            whereArgs: [contentId],
            limit: 1,
          );
          
          if (audioResults.isNotEmpty) {
            print("Found in $tableName: ${audioResults.first}");
            result ??= {};
            
            // Merge results, prioritizing audio-specific fields
            for (var key in audioResults.first.keys) {
              // Only add if not empty
              if (audioResults.first[key] != null && audioResults.first[key].toString().isNotEmpty) {
                result[key] = audioResults.first[key];
              }
            }
          }
        } catch (e) {
          print("Note: Table $tableName lookup failed: $e");
        }
      }
      
      // Check for all possible audio path/URL fields
      if (result != null) {
        final possibleFields = [
          'audio_path', 'audio_url', 'audio_file_path', 'path', 'file_path',
          'server_audio_url', 'remote_audio_url', 'media_url', 'url',
          'audio_server_url', 'remote_url', 'cloud_url', 'resource_url'
        ];
        
        print("Checking for audio URLs in fields: ${possibleFields.join(', ')}");
        for (final field in possibleFields) {
          if (result.containsKey(field) && 
              result[field] != null && 
              result[field].toString().isNotEmpty) {
            print("Found audio URL/path in field '$field': ${result[field]}");
          }
        }
      }
      
      return result;
    } catch (e) {
      print("Error getting content details: $e");
      return null;
    }
  }

  // Add a method to update content status directly
  Future<int> updateContentStatus({
    required String contentId,
    required String status,
  }) async {
    final db = await database;
    
    // Create a map with the status to update
    final Map<String, dynamic> values = {
      'targetDigitizationStatus': status,
    };
    
    print("Updating content status: $contentId to $status");
    
    try {
      // Check if the content exists
      final List<Map<String, dynamic>> existingContent = await db.query(
        'contents',
        where: 'contentId = ?',
        whereArgs: [contentId],
      );
      
      if (existingContent.isEmpty) {
        print("Content ID $contentId not found - cannot update status");
        return 0;
      } else {
        print("Found existing content - updating status to $status");
        
        // Update existing record
        final result = await db.update(
          'contents',
          values,
          where: 'contentId = ?',
          whereArgs: [contentId],
        );
        
        print("Update result: $result");
        return result;
      }
    } catch (e) {
      print("Error updating content status: $e");
      return 0;
    }
  }
}