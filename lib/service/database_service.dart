import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/sensor_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'sensor_data.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sensor_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        temperature REAL NOT NULL,
        humidity REAL NOT NULL,
        pressure REAL NOT NULL,
        timestamp TEXT NOT NULL,
        deviceId TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON sensor_data(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_deviceId ON sensor_data(deviceId)
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_timestamp ON sensor_data(timestamp)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_deviceId ON sensor_data(deviceId)
      ''');
    }
  }

  Future<int> insertSensorData(SensorData data) async {
    final db = await database;
    try {
      return await db.insert('sensor_data', data.toMap());
    } catch (e) {
      throw DatabaseException('Failed to insert sensor data: $e');
    }
  }

  Future<List<int>> insertMultipleSensorData(List<SensorData> dataList) async {
    final db = await database;
    final batch = db.batch();

    for (final data in dataList) {
      batch.insert('sensor_data', data.toMap());
    }

    try {
      final results = await batch.commit();
      return results.cast<int>();
    } catch (e) {
      throw DatabaseException('Failed to insert multiple sensor data: $e');
    }
  }

  Future<List<SensorData>> getAllSensorData({
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'sensor_data',
        orderBy: orderBy ?? 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) => SensorData.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get all sensor data: $e');
    }
  }

  Future<List<SensorData>> getSensorDataByDateRange({
    required DateTime start,
    required DateTime end,
    String? deviceId,
    int? limit,
  }) async {
    final db = await database;

    try {
      String whereClause = 'timestamp BETWEEN ? AND ?';
      List<dynamic> whereArgs = [start.toIso8601String(), end.toIso8601String()];

      if (deviceId != null) {
        whereClause += ' AND deviceId = ?';
        whereArgs.add(deviceId);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'sensor_data',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp ASC',
        limit: limit,
      );

      return maps.map((map) => SensorData.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get sensor data by date range: $e');
    }
  }

  Future<List<SensorData>> getRecentSensorData(int limit) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'sensor_data',
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((map) => SensorData.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get recent sensor data: $e');
    }
  }

  Future<SensorData?> getLatestSensorData({String? deviceId}) async {
    final db = await database;

    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (deviceId != null) {
        whereClause = 'deviceId = ?';
        whereArgs.add(deviceId);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'sensor_data',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      return maps.isNotEmpty ? SensorData.fromMap(maps.first) : null;
    } catch (e) {
      throw DatabaseException('Failed to get latest sensor data: $e');
    }
  }

  Future<int> deleteOldData(DateTime beforeDate) async {
    final db = await database;

    try {
      return await db.delete(
        'sensor_data',
        where: 'timestamp < ?',
        whereArgs: [beforeDate.toIso8601String()],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete old data: $e');
    }
  }

  Future<int> deleteSensorData(int id) async {
    final db = await database;

    try {
      return await db.delete(
        'sensor_data',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete sensor data: $e');
    }
  }

  Future<int> getDataCount({String? deviceId, DateTime? after}) async {
    final db = await database;

    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (deviceId != null) {
        whereClause = 'deviceId = ?';
        whereArgs.add(deviceId);
      }

      if (after != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'timestamp > ?';
        whereArgs.add(after.toIso8601String());
      }

      final result = await db.query(
        'sensor_data',
        columns: ['COUNT(*) as count'],
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
      );

      return result.first['count'] as int;
    } catch (e) {
      throw DatabaseException('Failed to get data count: $e');
    }
  }

  Future<void> clearAllData() async {
    final db = await database;

    try {
      await db.delete('sensor_data');
    } catch (e) {
      throw DatabaseException('Failed to clear all data: $e');
    }
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}