import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sdcp_rebuild/data/submit_task_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    try {
      debugPrint('Checking network connectivity...');
      
      // Check basic connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnectivity = connectivityResult == ConnectivityResult.mobile || 
                            connectivityResult == ConnectivityResult.wifi ||
                            connectivityResult == ConnectivityResult.ethernet;
      
      if (!hasConnectivity) {
        debugPrint('No network connectivity detected (no WiFi, ethernet or mobile data)');
        return false;
      }
      
      debugPrint('Basic connectivity detected: $connectivityResult');
      
      // Try to actually reach an internet endpoint to verify real internet connectivity
      try {
        final response = await http.get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 5));
        final hasInternet = response.statusCode == 200;
        debugPrint('Internet connectivity test: ${hasInternet ? 'Success' : 'Failed'}');
        return hasInternet;
      } catch (e) {
        // If we can't reach Google, try one other domain
        try {
          final response = await http.get(Uri.parse('https://www.cloudflare.com'))
              .timeout(const Duration(seconds: 5));
          final hasInternet = response.statusCode == 200;
          debugPrint('Fallback internet connectivity test: ${hasInternet ? 'Success' : 'Failed'}');
          return hasInternet;
        } catch (e) {
          // If we can't reach either domain but we have WiFi/mobile data,
          // assume we have internet to avoid blocking the user unnecessarily
          debugPrint('Internet connectivity test failed, but basic connectivity is available');
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error checking network connectivity: $e');
      // Return true by default to avoid blocking downloads due to check errors
      return true;
    }
  }
  
  // Optional method to check if we have any form of connectivity without making a network request
  static Future<bool> hasConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile || 
             connectivityResult == ConnectivityResult.wifi ||
             connectivityResult == ConnectivityResult.ethernet;
    } catch (e) {
      debugPrint('Error checking basic connectivity: $e');
      return true; // Default to true to avoid blocking operations
    }
  }
}