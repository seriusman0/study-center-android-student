import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_models.dart';

class LocalChatDatabase {
  static const _dbName = 'sc_chat_local.db';
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    
    final path = await getDatabasesPath();
    _db = await openDatabase(
      '$path/$_dbName',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id INTEGER PRIMARY KEY,
            payload TEXT NOT NULL,
            last_updated TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            uuid TEXT PRIMARY KEY,
            id INTEGER,
            conversation_id INTEGER NOT NULL,
            payload TEXT NOT NULL,
            status TEXT DEFAULT 'sent',
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<Database> get _database async {
    await init();
    return _db!;
  }

  // --- Conversations ---
  
  Future<void> saveConversations(List<ConversationDto> convs) async {
    final db = await _database;
    final batch = db.batch();
    for (final c in convs) {
      final payload = jsonEncode(c.toJson());
      batch.insert(
        'conversations',
        {
          'id': c.id,
          'payload': payload,
          'last_updated': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await _database;
    final rows = await db.query('conversations', orderBy: 'last_updated DESC');
    return rows.map((r) => jsonDecode(r['payload'] as String) as Map<String, dynamic>).toList();
  }

  // --- Messages ---
  
  Future<void> saveMessages(int convId, List<MessageDto> messages) async {
    final db = await _database;
    final batch = db.batch();
    for (final m in messages) {
      final payload = jsonEncode(m.toJson());
      batch.insert(
        'messages',
        {
          'uuid': m.id.toString(), // For server messages, UUID is just the ID
          'id': m.id,
          'conversation_id': convId,
          'payload': payload,
          'status': 'sent',
          'created_at': m.createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> savePendingMessage(String uuid, int convId, Map<String, dynamic> payload, String createdAt) async {
    final db = await _database;
    await db.insert(
      'messages',
      {
        'uuid': uuid,
        'id': null,
        'conversation_id': convId,
        'payload': jsonEncode(payload),
        'status': 'pending',
        'created_at': createdAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessageStatus(String uuid, int newId, Map<String, dynamic> payload) async {
    final db = await _database;
    await db.update(
      'messages',
      {
        'id': newId,
        'payload': jsonEncode(payload),
        'status': 'sent',
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(int convId) async {
    final db = await _database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [convId],
      orderBy: 'created_at DESC',
    );
    
    return rows.map((r) {
      final payload = jsonDecode(r['payload'] as String) as Map<String, dynamic>;
      payload['status'] = r['status']; // inject status
      payload['uuid'] = r['uuid']; // inject uuid
      return payload;
    }).toList();
  }
}
