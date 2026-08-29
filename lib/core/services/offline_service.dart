import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// Kinds of queued operations that can be replayed when online.
enum OfflineOpKind {
  checkLife, checkBible, saveVerse, uploadFoto,
  // Journal verse check (per-day)
  checkVerseCheck,
  // College-specific operations
  collegeCheck, collegeStudyLog, collegeFoto,
  // Scholarship teenager-specific operations
  scholarshipCheck, scholarshipFoto
}

/// One queued mutation waiting to be sent to the server.
class OfflineOperation {
  final int? id; // null = not yet persisted
  final OfflineOpKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int? retryCount;

  const OfflineOperation({
    this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'payload': _encodePayload(payload),
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount ?? 0,
      };

  factory OfflineOperation.fromMap(Map<String, dynamic> m) {
    return OfflineOperation(
      id: m['id'] as int,
      kind: OfflineOpKind.values.firstWhere(
        (k) => k.name == m['kind'],
        orElse: () => OfflineOpKind.checkLife,
      ),
      payload: _decodePayload(m['payload'] as String),
      createdAt: DateTime.parse(m['created_at'] as String),
      retryCount: m['retry_count'] as int? ?? 0,
    );
  }
}

String _encodePayload(Map<String, dynamic> p) =>
    p.entries.map((e) => '${e.key}=${e.value}').join('&');

Map<String, dynamic> _decodePayload(String s) {
  final result = <String, dynamic>{};
  for (final pair in s.split('&')) {
    final idx = pair.indexOf('=');
    if (idx > 0) {
      result[pair.substring(0, idx)] = pair.substring(idx + 1);
    }
  }
  return result;
}

/// Provider tag so Riverpod can auto-dispose cleanly.
final offlineServiceProvider = Provider<OfflineService>((ref) {
  throw UnimplementedError('override in ProviderScope');
});

/// Singleton SQLite-backed queue for offline mutations.
///
/// Usage:
///   await ref.read(offlineServiceProvider).enqueue(OfflineOpKind.checkLife, {
///     'journal_id': '123',
///     'item_id': '456',
///     'checked': '1',
///   });
class OfflineService {
  static const _databaseName = 'sc_offline.db';
  static const _table = 'offline_queue';
  static const _maxRetries = 3;

  Database? _database;
  bool _initialized = false;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Enqueue an operation for later replay. Returns the operation's DB id.
  Future<int> enqueue(OfflineOpKind kind, Map<String, dynamic> payload) async {
    final db = await _db();
    final op = OfflineOperation(
      kind: kind,
      payload: Map.from(payload),
      createdAt: DateTime.now(),
    );
    final id = await db.insert(_table, op.toMap());
    debugPrint('[OfflineService] Enqueued $kind (id=$id): $payload');
    return id;
  }

  /// Returns all pending operations ordered oldest-first.
  Future<List<OfflineOperation>> pending() async {
    final db = await _db();
    final rows = await db.query(_table, orderBy: 'created_at ASC');
    return rows.map((r) => OfflineOperation.fromMap(r)).toList();
  }

  /// Returns the count of pending operations.
  Future<int> pendingCount() async {
    final db = await _db();
    final r = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_table'),
    );
    return r ?? 0;
  }

  /// Remove a successfully-flushed operation.
  Future<void> remove(int id) async {
    final db = await _db();
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    debugPrint('[OfflineService] Removed id=$id');
  }

  /// Increment retry count; returns true if max retries exceeded.
  Future<bool> markRetry(int id, int retries) async {
    if (retries >= _maxRetries) return true;
    final db = await _db();
    await db.update(_table, {'retry_count': retries + 1},
        where: 'id = ?', whereArgs: [id]);
    return false;
  }

  /// Clear everything (e.g. after full sync or logout).
  Future<void> clear() async {
    final db = await _db();
    await db.delete(_table);
    debugPrint('[OfflineService] Queue cleared');
  }

  /// Close the database handle.
  Future<void> close() async {
    final db = _database;
    _database = null;
    _initialized = false;
    await db?.close();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<Database> _db() async {
    if (!_initialized) await _init();
    final db = _database;
    if (db == null) throw StateError('OfflineService already closed');
    return db;
  }

  Future<void> _init() async {
    final path = await initDatabasePath(_databaseName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0
          )
        ''');
        debugPrint('[OfflineService] Table created at $path');
      },
    );
    _initialized = true;
  }
}

@visibleForTesting
Future<String> initDatabasePath(String name) async {
  // sqflite resolves this relative to the default database directory.
  return name;
}
