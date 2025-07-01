import 'package:sdcp_rebuild/data/reviews_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class ReviewsDatabaseHelper {
  static final ReviewsDatabaseHelper _instance = ReviewsDatabaseHelper._internal();
  static Database? _database;

  factory ReviewsDatabaseHelper() => _instance;

  ReviewsDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'reviews_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE reviews(
            taskId TEXT PRIMARY KEY,
            taskTargetId TEXT,
            projectId TEXT,
            languageName TEXT,
            taskPrefix TEXT,
            taskTitle TEXT,
            taskType TEXT,
            status TEXT,
            createdDate TEXT,
            assignedTo TEXT,
            project TEXT,
            contents TEXT,
            lastSyncTime INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insertReview(ReviewsModel review) async {
    final Database db = await database;
    await db.insert(
      'reviews',
      {
        'taskId': review.taskId,
        'taskTargetId': review.taskTargetId,
        'projectId': review.projectId,
        'languageName': review.languageName,
        'taskPrefix': review.taskPrefix,
        'taskTitle': review.taskTitle,
        'taskType': review.taskType,
        'status': review.status,
        'createdDate': review.createdDate,
        'assignedTo': review.assignedTo,
        'project': review.project,
        'contents': review.contents,
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertReviews(List<ReviewsModel> reviews) async {
    final Database db = await database;
    final Batch batch = db.batch();

    for (var review in reviews) {
      batch.insert(
        'reviews',
        {
          'taskId': review.taskId,
          'taskTargetId': review.taskTargetId,
          'projectId': review.projectId,
          'languageName': review.languageName,
          'taskPrefix': review.taskPrefix,
          'taskTitle': review.taskTitle,
          'taskType': review.taskType,
          'status': review.status,
          'createdDate': review.createdDate,
          'assignedTo': review.assignedTo,
          'project': review.project,
          'contents': review.contents,
          'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ReviewsModel>> getAllReviews() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reviews');

    return List.generate(maps.length, (i) {
      return ReviewsModel(
        taskId: maps[i]['taskId'],
        taskTargetId: maps[i]['taskTargetId'],
        projectId: maps[i]['projectId'],
        languageName: maps[i]['languageName'],
        taskPrefix: maps[i]['taskPrefix'],
        taskTitle: maps[i]['taskTitle'],
        taskType: maps[i]['taskType'],
        status: maps[i]['status'],
        createdDate: maps[i]['createdDate'],
        assignedTo: maps[i]['assignedTo'],
        project: maps[i]['project'],
        contents: maps[i]['contents'],
      );
    });
  }

  Future<ReviewsModel?> getReviewById(String taskId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );

    if (maps.isEmpty) return null;

    return ReviewsModel(
      taskId: maps[0]['taskId'],
      taskTargetId: maps[0]['taskTargetId'],
      projectId: maps[0]['projectId'],
      languageName: maps[0]['languageName'],
      taskPrefix: maps[0]['taskPrefix'],
      taskTitle: maps[0]['taskTitle'],
      taskType: maps[0]['taskType'],
      status: maps[0]['status'],
      createdDate: maps[0]['createdDate'],
      assignedTo: maps[0]['assignedTo'],
      project: maps[0]['project'],
      contents: maps[0]['contents'],
    );
  }

  Future<void> deleteReview(String taskId) async {
    final Database db = await database;
    await db.delete(
      'reviews',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> clearAllReviews() async {
    final Database db = await database;
    await db.delete('reviews');
  }

  Future<void> updateReview(ReviewsModel review) async {
    final Database db = await database;
    await db.update(
      'reviews',
      {
        'taskTargetId': review.taskTargetId,
        'projectId': review.projectId,
        'languageName': review.languageName,
        'taskPrefix': review.taskPrefix,
        'taskTitle': review.taskTitle,
        'taskType': review.taskType,
        'status': review.status,
        'createdDate': review.createdDate,
        'assignedTo': review.assignedTo,
        'project': review.project,
        'contents': review.contents,
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'taskId = ?',
      whereArgs: [review.taskId],
    );
  }
}