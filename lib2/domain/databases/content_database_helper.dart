
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
//   static const String audioBaseUrl = 'https://speech.ldcil.org/';
  
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

      // Copy file to permanent location
      await File(tempPath).copy(permanentPath);
      
      return permanentPath;
    } catch (e) {
      print('Error moving recording: $e');
      rethrow;
    }
  }}