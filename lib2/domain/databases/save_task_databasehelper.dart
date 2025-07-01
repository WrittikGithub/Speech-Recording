import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SaveTaskDatabasehelper {
  static const _databaseName = "TaskDatabase.db";
  static const _databaseVersion = 1;
  static const table = 'pending_tasks';
  

 
  SaveTaskDatabasehelper._privateConstructor();
  static final SaveTaskDatabasehelper _instance = SaveTaskDatabasehelper._privateConstructor();

  static Database? _database;
   factory SaveTaskDatabasehelper() => _instance;
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
        contentId TEXT NOT NULL,
        taskTargetId TEXT NOT NULL,
        targetContent TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertPendingTask(SubmitTaskModel task) async {
    Database db = await database;
    Map<String, dynamic> row = {
      'contentId': task.contentId,
      'taskTargetId': task.taskTargetId,
      'targetContent': task.targetContent,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return await db.insert(table, row);
  }

  Future<List<SubmitTaskModel>> getPendingTasks() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'timestamp ASC');
    return List.generate(maps.length, (i) {
      return SubmitTaskModel(
        contentId: maps[i]['contentId'],
        taskTargetId: maps[i]['taskTargetId'],
        targetContent: maps[i]['targetContent'],
      );
    });
  }

  Future<void> deletePendingTask(String contentId, String taskTargetId) async {
    Database db = await database;
    await db.delete(
      table,
      where: 'contentId = ? AND taskTargetId = ?',
      whereArgs: [contentId, taskTargetId],
    );
  }
}
/////////////////////////
class NetworkChecker {
  static Future<bool> hasNetwork() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final results =  connectivityResult;
    return results.contains(ConnectivityResult.mobile) || 
           results.contains(ConnectivityResult.wifi);
  }
}