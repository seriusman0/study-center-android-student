import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/journal_model.dart';

class JournalRepository {
  final Dio _dio;

  const JournalRepository(this._dio);

  Future<JournalSnapshot> today() async {
    final res = await _dio.get(ApiConstants.jurnalToday);
    return JournalSnapshot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<JournalSnapshot> check({
    required String itemType,
    int? itemId,
    bool? checked,
    String? verseRef,
    String? date,
  }) async {
    final res = await _dio.post(ApiConstants.jurnalCheck, data: {
      'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (checked != null) 'checked': checked,
      if (verseRef != null) 'verse_ref': verseRef,
      if (date != null) 'date': date,
    });
    final data = res.data as Map<String, dynamic>;
    return JournalSnapshot.fromJson(data['state'] as Map<String, dynamic>);
  }
}

final journalRepositoryProvider = Provider((ref) => JournalRepository(ref.read(dioProvider)));
