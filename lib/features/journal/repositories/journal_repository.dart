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
    final data = res.data;
    // API may return data directly or wrapped in a 'data' key
    final payload = (data is Map && data.containsKey('data') && data['data'] is Map)
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return JournalSnapshot.fromJson(payload);
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
    // Return updated snapshot from 'state' key or the data itself
    final statePayload = data['state'] ?? data;
    return JournalSnapshot.fromJson(statePayload as Map<String, dynamic>);
  }

  Future<JournalSnapshot> uploadPhoto(List<int> bytes, String filename, String date) async {
    final formData = FormData.fromMap({
      'date': date,
      'foto': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post(ApiConstants.jurnalFoto, data: formData);
    final data = res.data as Map<String, dynamic>;
    final statePayload = data['state'] ?? data;
    return JournalSnapshot.fromJson(statePayload as Map<String, dynamic>);
  }

  Future<JournalSnapshot> deletePhoto(String date) async {
    final res = await _dio.delete(ApiConstants.jurnalFoto, data: {'date': date});
    final data = res.data as Map<String, dynamic>;
    final statePayload = data['state'] ?? data;
    return JournalSnapshot.fromJson(statePayload as Map<String, dynamic>);
  }
}

final journalRepositoryProvider =
    Provider((ref) => JournalRepository(ref.read(dioProvider)));
