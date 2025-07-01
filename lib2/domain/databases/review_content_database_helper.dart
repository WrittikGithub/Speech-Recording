import 'package:sdcp_rebuild/data/review_content_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ReviewContentDatabaseHelper {
  static final ReviewContentDatabaseHelper _instance = ReviewContentDatabaseHelper._internal();
  static Database? _database;
  static const String audioBaseUrl = 'https://speech.ldcil.org/';
  
  factory ReviewContentDatabaseHelper() => _instance;
  ReviewContentDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'review_content_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE review_contents(
            contentId TEXT PRIMARY KEY,
            taskId TEXT,
            csid TEXT,
            sourceContent TEXT,
            sourceWordCount TEXT,
            maxCharCount TEXT,
            sourceCharCount TEXT,
            contentReferenceUrl TEXT,
            contentReferencePath TEXT,
            targetLanguageId TEXT,
            targetContent TEXT,
            reviewedContent TEXT,
            targetWordCount TEXT,
            additionalNotes TEXT,
            var1 TEXT,
            var2 TEXT,
            var3 TEXT,
            digitizationStatus TEXT,
            reviewStatus TEXT,
            createdDate TEXT,
            lastModifiedDate TEXT,
            digitizedDate TEXT,
            reviewDate TEXT,
            characterCount TEXT,
            raiseIssue TEXT,
            transLastModifiedBy TEXT,
            revLastModifiedBy TEXT,
            transLastModifiedDate TEXT,
            revLastModifiedDate TEXT,
            reviewScoreStatus TEXT,
            pageTitle TEXT,
            totalComments TEXT,
            sourceLanguage TEXT,
            targetLanguage TEXT,
            targetTaskTargetId TEXT,
            targetTargetContentUrl TEXT,
            targetTargetContentPath TEXT,
            targetDigitizationStatus TEXT,
            ttargetWordCount TEXT,
            ttargetCharacterCount TEXT,
            commentExist TEXT,
            targetContentId TEXT,
            targetReviewStatus TEXT,
            projectName TEXT,
            lastSyncTime INTEGER
          )
        ''');
        print("Review contents table created successfully.");
      },
    );
  }

  Future<String> _getLocalPath(String type) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${directory.path}/review_${type}_files');
    if (!await mediaDir.exists()) {
      print("Creating directory for review $type files...");
      await mediaDir.create(recursive: true);
    }
    print("Review $type directory path: ${mediaDir.path}");
    return mediaDir.path;
  }

  bool _isAudioFile(String url) {
    return url.toLowerCase().endsWith('.wav') || 
           url.startsWith('uploads/') || 
           url.startsWith('rspeech/');
  }

  bool _isImageFile(String url) {
    final validImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final lowercaseUrl = url.toLowerCase();
    return url.startsWith('http') && 
           validImageExtensions.any((ext) => lowercaseUrl.endsWith(ext));
  }

  Future<String?> _downloadFile(String url, String type) async {
    try {
      print("Downloading review $type file from: $url");
      final client = http.Client();
      final Uri uri;
      
      if (type == 'audio' && !url.startsWith('http')) {
        uri = Uri.parse('$audioBaseUrl$url');
      } else {
        uri = Uri.parse(url);
      }

      final response = await client.get(uri);
      
      if (response.statusCode == 200) {
        final localPath = await _getLocalPath(type);
        final fileName = url.split('/').last;
        final filePath = '$localPath/$fileName';
        
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print("Review $type file downloaded and saved to: $filePath");
        return filePath;
      }
      return null;
    } catch (e) {
      print('Error downloading review $type file: $e');
      return null;
    }
  }

  Future<Map<String, String?>> _downloadMedia(String contentReferenceUrl, String targetTargetContentUrl) async {
    print("Downloading review media files...");
    String? contentReferencePath;
    String? targetTargetContentPath;

    if (_isImageFile(contentReferenceUrl)) {
      contentReferencePath = await _downloadFile(contentReferenceUrl, 'images');
    }

    if (_isAudioFile(targetTargetContentUrl)) {
      targetTargetContentPath = await _downloadFile(targetTargetContentUrl, 'audio');
    }
    print("Review media download complete. Reference path: $contentReferencePath, Target path: $targetTargetContentPath");
    return {
      'contentReferencePath': contentReferencePath,
      'targetTargetContentPath': targetTargetContentPath,
    };
  }

  Future<void> insertReviewContent(ReviewContentModel content) async {
    final Database db = await database;
    print("Inserting review content: ${content.contentId}");
    final mediaFiles = await _downloadMedia(content.contentReferenceUrl, content.targetTargetContentUrl);

    await db.insert(
      'review_contents',
      {
        'contentId': content.contentId,
        'taskId': content.taskId,
        'csid': content.csid,
        'sourceContent': content.sourceContent,
        'sourceWordCount': content.sourceWordCount,
        'maxCharCount': content.maxCharCount,
        'sourceCharCount': content.sourceCharCount,
        'contentReferenceUrl': content.contentReferenceUrl,
        'contentReferencePath': mediaFiles['contentReferencePath'] ?? content.contentReferencePath,
        'targetLanguageId': content.targetLanguageId,
        'targetContent': content.targetContent,
        'reviewedContent': content.reviewedContent,
        'targetWordCount': content.targetWordCount,
        'additionalNotes': content.additionalNotes,
        'var1': content.var1,
        'var2': content.var2,
        'var3': content.var3,
        'digitizationStatus': content.digitizationStatus,
        'reviewStatus': content.reviewStatus,
        'createdDate': content.createdDate,
        'lastModifiedDate': content.lastModifiedDate,
        'digitizedDate': content.digitizedDate,
        'reviewDate': content.reviewDate,
        'characterCount': content.characterCount,
        'raiseIssue': content.raiseIssue,
        'transLastModifiedBy': content.transLastModifiedBy,
        'revLastModifiedBy': content.revLastModifiedBy,
        'transLastModifiedDate': content.transLastModifiedDate,
        'revLastModifiedDate': content.revLastModifiedDate,
        'reviewScoreStatus': content.reviewScoreStatus,
        'pageTitle': content.pageTitle,
        'totalComments': content.totalComments,
        'sourceLanguage': content.sourceLanguage,
        'targetLanguage': content.targetLanguage,
        'targetTaskTargetId': content.targetTaskTargetId,
        'targetTargetContentUrl': content.targetTargetContentUrl,
        'targetTargetContentPath': mediaFiles['targetTargetContentPath'] ?? content.targetTargetContentPath,
        'targetDigitizationStatus': content.targetDigitizationStatus,
        'ttargetWordCount': content.ttargetWordCount,
        'ttargetCharacterCount': content.ttargetCharacterCount,
        'commentExist': content.commentExist,
        'targetContentId': content.targetContentId,
        'targetReviewStatus': content.targetReviewStatus,
        'projectName': content.projectName,
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Review content inserted successfully.");
  }

  Future<void> insertReviewContents(List<ReviewContentModel> contents) async {
    final Database db = await database;
    final Batch batch = db.batch();

    for (var content in contents) {
      final mediaFiles = await _downloadMedia(content.contentReferenceUrl, content.targetTargetContentUrl);

      batch.insert(
        'review_contents',
        {
          'contentId': content.contentId,
          'taskId': content.taskId,
          'csid': content.csid,
          'sourceContent': content.sourceContent,
          'sourceWordCount': content.sourceWordCount,
          'maxCharCount': content.maxCharCount,
          'sourceCharCount': content.sourceCharCount,
          'contentReferenceUrl': content.contentReferenceUrl,
          'contentReferencePath': mediaFiles['contentReferencePath'] ?? content.contentReferencePath,
          'targetLanguageId': content.targetLanguageId,
          'targetContent': content.targetContent,
          'reviewedContent': content.reviewedContent,
          'targetWordCount': content.targetWordCount,
          'additionalNotes': content.additionalNotes,
          'var1': content.var1,
          'var2': content.var2,
          'var3': content.var3,
          'digitizationStatus': content.digitizationStatus,
          'reviewStatus': content.reviewStatus,
          'createdDate': content.createdDate,
          'lastModifiedDate': content.lastModifiedDate,
          'digitizedDate': content.digitizedDate,
          'reviewDate': content.reviewDate,
          'characterCount': content.characterCount,
          'raiseIssue': content.raiseIssue,
          'transLastModifiedBy': content.transLastModifiedBy,
          'revLastModifiedBy': content.revLastModifiedBy,
          'transLastModifiedDate': content.transLastModifiedDate,
          'revLastModifiedDate': content.revLastModifiedDate,
          'reviewScoreStatus': content.reviewScoreStatus,
          'pageTitle': content.pageTitle,
          'totalComments': content.totalComments,
          'sourceLanguage': content.sourceLanguage,
          'targetLanguage': content.targetLanguage,
          'targetTaskTargetId': content.targetTaskTargetId,
          'targetTargetContentUrl': content.targetTargetContentUrl,
          'targetTargetContentPath': mediaFiles['targetTargetContentPath'] ?? content.targetTargetContentPath,
          'targetDigitizationStatus': content.targetDigitizationStatus,
          'ttargetWordCount': content.ttargetWordCount,
          'ttargetCharacterCount': content.ttargetCharacterCount,
          'commentExist': content.commentExist,
          'targetContentId': content.targetContentId,
          'targetReviewStatus': content.targetReviewStatus,
          'projectName': content.projectName,
          'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ReviewContentModel>> getContentsByTargetTaskTargetId(String targetTaskTargetId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'review_contents',
      where: 'targetTaskTargetId = ?',
      whereArgs: [targetTaskTargetId],
    );

    return List.generate(maps.length, (i) {
      return ReviewContentModel(
        contentId: maps[i]['contentId'] ?? '',
        taskId: maps[i]['taskId'] ?? '',
        csid: maps[i]['csid'] ?? '',
        sourceContent: maps[i]['sourceContent'] ?? '',
        sourceWordCount: maps[i]['sourceWordCount'] ?? '',
        maxCharCount: maps[i]['maxCharCount'] ?? '',
        sourceCharCount: maps[i]['sourceCharCount'] ?? '',
        contentReferenceUrl: maps[i]['contentReferenceUrl'] ?? '',
        contentReferencePath: maps[i]['contentReferencePath'] ?? '',
        targetLanguageId: maps[i]['targetLanguageId'] ?? '',
        targetContent: maps[i]['targetContent'],
        reviewedContent: maps[i]['reviewedContent'],
        targetWordCount: maps[i]['targetWordCount'] ?? '',
        additionalNotes: maps[i]['additionalNotes'],
        var1: maps[i]['var1'],
        var2: maps[i]['var2'],
        var3: maps[i]['var3'],
        digitizationStatus: maps[i]['digitizationStatus'] ?? '',
        reviewStatus: maps[i]['reviewStatus'],
        createdDate: maps[i]['createdDate'] ?? '',
        lastModifiedDate: maps[i]['lastModifiedDate'] ?? '',
        digitizedDate: maps[i]['digitizedDate'],
        reviewDate: maps[i]['reviewDate'],
        characterCount: maps[i]['characterCount'],
        raiseIssue: maps[i]['raiseIssue'],
        transLastModifiedBy: maps[i]['transLastModifiedBy'],
        revLastModifiedBy: maps[i]['revLastModifiedBy'],
        transLastModifiedDate: maps[i]['transLastModifiedDate'],
        revLastModifiedDate: maps[i]['revLastModifiedDate'],
        reviewScoreStatus: maps[i]['reviewScoreStatus'],
        pageTitle: maps[i]['pageTitle'] ?? '',
        totalComments: maps[i]['totalComments'] ?? '',
        sourceLanguage: maps[i]['sourceLanguage'] ?? '',
        targetLanguage: maps[i]['targetLanguage'] ?? '',
        targetTaskTargetId: maps[i]['targetTaskTargetId'] ?? '',
        targetTargetContentUrl: maps[i]['targetTargetContentUrl'] ?? '',
        targetTargetContentPath: maps[i]['targetTargetContentPath'] ?? '',
        targetDigitizationStatus: maps[i]['targetDigitizationStatus'] ?? '',
        ttargetWordCount: maps[i]['ttargetWordCount'] ?? '',
        ttargetCharacterCount: maps[i]['ttargetCharacterCount'] ?? '',
        commentExist: maps[i]['commentExist'] ?? '',
        targetContentId: maps[i]['targetContentId'] ?? '',
        targetReviewStatus: maps[i]['targetReviewStatus'],
        projectName: maps[i]['projectName'] ?? '',
      );
    });
  }

Future<void> deleteContentsByTargetTaskTargetId(String targetTaskTargetId) async {
    print("Deleting review contents for targetTaskTargetId: $targetTaskTargetId");
    final Database db = await database;
    
    // First get all contents for this targetTaskTargetId to delete their media files
    final List<Map<String, dynamic>> contents = await db.query(
      'review_contents',
      where: 'targetTaskTargetId = ?',
      whereArgs: [targetTaskTargetId],
    );

    // Delete associated media files
    for (var content in contents) {
      final contentReferencePath = content['contentReferencePath'];
      final targetTargetContentPath = content['targetTargetContentPath'];
      
      if (contentReferencePath != null) {
        final referenceFile = File(contentReferencePath);
        if (await referenceFile.exists()) {
          await referenceFile.delete();
        }
      }
      
      if (targetTargetContentPath != null) {
        final targetFile = File(targetTargetContentPath);
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
      }
    }

    // Delete the database records
    await db.delete(
      'review_contents',
      where: 'targetTaskTargetId = ?',
      whereArgs: [targetTaskTargetId],
    );
  }
 Future<void> clearAllContents() async {
    print("Clearing all review contents...");
    final Database db = await database;
    await db.delete('review_contents');
    
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
  ////////////
    Future<void> updateReviewStatus(String taskTargetId, String contentId, String reviewStatus) async {
    final Database db = await database;
    print("Updating review status for taskTargetId: $taskTargetId, contentId: $contentId");
    
    await db.update(
      'review_contents',
      {'targetReviewStatus': reviewStatus},
      where: 'targetTaskTargetId = ? AND contentId = ?',
      whereArgs: [taskTargetId, contentId],
    );
    print("Review status updated successfully");
  }
}