// ignore_for_file: avoid_print

/// Helper untuk test offline: setup in-memory SQLite + factory untuk
/// OfflineService yang benar-benar pakai sqflite_common_ffi (tidak perlu
/// emulator/device).
library offline_test_helper;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sc_student/core/services/offline_service.dart';

/// Panggil sekali di setUpAll() sebelum test pertama yang memakai SQLite.
void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Buat OfflineService segar yang memakai database in-memory.
/// Setiap call menghasilkan instance baru dengan DB kosong.
Future<OfflineService> makeTestOfflineService() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE offline_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0
          )
        ''');
      },
    ),
  );
  return OfflineService.withDatabase(db);
}
