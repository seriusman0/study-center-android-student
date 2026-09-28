import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE api_cache(
            url TEXT PRIMARY KEY,
            response TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  Future<void> saveCache(String url, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'api_cache',
      {
        'url': url,
        'response': jsonEncode(data),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCache(String url) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'api_cache',
      where: 'url = ?',
      whereArgs: [url],
    );

    if (maps.isNotEmpty) {
      final responseStr = maps.first['response'] as String;
      try {
        return jsonDecode(responseStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLatestCacheByPrefix(String urlPrefix) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'api_cache',
      where: 'url LIKE ?',
      whereArgs: ['$urlPrefix%'],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final responseStr = maps.first['response'] as String;
      try {
        return jsonDecode(responseStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('api_cache');
  }
}
