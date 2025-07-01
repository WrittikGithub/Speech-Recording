import 'package:sdcp_rebuild/data/task_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasks_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE tasks(
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
            lastSyncTime INTEGER
          )
        ''');
      },
    );
  }

  Future<void> insertTask(TaskModel task) async {
    final Database db = await database;
    await db.insert(
      'tasks',
      {
        'taskId': task.taskId,
        'taskTargetId': task.taskTargetId,
        'projectId': task.projectId,
        'languageName': task.languageName,
        'taskPrefix': task.taskPrefix,
        'taskTitle': task.taskTitle,
        'taskType': task.taskType,
        'status': task.status,
        'createdDate': task.createdDate,
        'assignedTo': task.assignedTo,
        'project': task.project,
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTasks(List<TaskModel> tasks) async {
    final Database db = await database;
    final Batch batch = db.batch();
    
    for (var task in tasks) {
      batch.insert(
        'tasks',
        {
          'taskId': task.taskId,
          'taskTargetId': task.taskTargetId,
          'projectId': task.projectId,
          'languageName': task.languageName,
          'taskPrefix': task.taskPrefix,
          'taskTitle': task.taskTitle,
          'taskType': task.taskType,
          'status': task.status,
          'createdDate': task.createdDate,
          'assignedTo': task.assignedTo,
          'project': task.project,
          'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<TaskModel>> getAllTasks() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    
    return List.generate(maps.length, (i) {
      return TaskModel(
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
      );
    });
  }

  Future<void> deleteTask(String taskId) async {
    final Database db = await database;
    await db.delete(
      'tasks',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> clearAllTasks() async {
    final Database db = await database;
    await db.delete('tasks');
  }
}
