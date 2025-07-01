

import 'package:sdcp_rebuild/data/savereview_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SaveReviewDatabaseHelper {
  static const _databaseName = "ReviewDatabase.db";
  static const _databaseVersion = 1;
  static const table = 'pending_reviews';

  // Static instance
  static final SaveReviewDatabaseHelper _instance = SaveReviewDatabaseHelper._internal();

  // Factory constructor
  factory SaveReviewDatabaseHelper() => _instance;

  // Private constructor
  SaveReviewDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reviewStatus TEXT NOT NULL,
        taskTargetId TEXT NOT NULL,
        comment TEXT,
        selectedOption TEXT,
        tContentId TEXT NOT NULL,
        contentId TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertPendingReview(SaveReviewModel review) async {
    Database db = await database;
    Map<String, dynamic> row = {
      'reviewStatus': review.reviewStatus,
      'taskTargetId': review.taskTargetId,
      'comment': review.comment,
      'selectedOption': review.selectedOption,
      'tContentId': review.tContentId,
      'contentId': review.contentId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await db.insert(table, row);
  }

  Future<List<SaveReviewModel>> getPendingReviews() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'timestamp ASC');
    return List.generate(maps.length, (i) {
      return SaveReviewModel(
        reviewStatus: maps[i]['reviewStatus'],
        taskTargetId: maps[i]['taskTargetId'],
        comment: maps[i]['comment'],
        selectedOption: maps[i]['selectedOption'],
        tContentId: maps[i]['tContentId'],
        contentId: maps[i]['contentId'],
      );
    });
  }

  Future<void> deletePendingReview(String contentId, String taskTargetId) async {
    Database db = await database;
    await db.delete(
      table,
      where: 'contentId = ? AND taskTargetId = ?',
      whereArgs: [contentId, taskTargetId],
    );
  }
}