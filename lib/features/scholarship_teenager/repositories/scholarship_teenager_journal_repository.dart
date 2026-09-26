import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../college/models/college_journal_model.dart';

/// Repository for scholarship_teenager journal API.
/// Reuses [CollegeJournalSnapshot] — the response shape is identical
/// (bible PL/PB, life_items with check/boolean, config, foto_belajar).
/// The only difference from college: NO study_log time_range items.
class ScholarshipTeenagerJournalRepository {
  final Dio _dio;
  const ScholarshipTeenagerJournalRepository(this._dio);

  Future<CollegeJournalSnapshot> today({String? date}) async {
    final res = await _dio.get(
      ApiConstants.scholarshipJurnalToday,
      queryParameters: date != null ? {'date': date} : null,
    );
    final data = res.data as Map<String, dynamic>;
    return CollegeJournalSnapshot.fromJson(data);
  }

  Future<CollegeJournalSnapshot> check({
    required String itemType,
    int? itemId,
    bool? checked,
    String? date,
    String? verseRef,
  }) async {
    final res = await _dio.post(ApiConstants.scholarshipJurnalCheck, data: {
      'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (checked != null) 'checked': checked,
      if (date != null) 'date': date,
      if (verseRef != null) 'verse_ref': verseRef,
    });
    final data = res.data as Map<String, dynamic>;
    final payload = data['state'] ?? data;
    return CollegeJournalSnapshot.fromJson(payload as Map<String, dynamic>);
  }

  Future<CollegeJournalSnapshot> uploadPhoto(
      List<int> bytes, String filename, String date) async {
    final formData = FormData.fromMap({
      'date': date,
      'foto': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post(ApiConstants.scholarshipJurnalFoto, data: formData);
    final data = res.data as Map<String, dynamic>;
    final statePayload = data['state'] ?? data;
    return CollegeJournalSnapshot.fromJson(statePayload as Map<String, dynamic>);
  }

  Future<CollegeJournalSnapshot> deletePhoto(String date) async {
    final res = await _dio.delete(
        ApiConstants.scholarshipJurnalFoto, data: {'date': date});
    final data = res.data as Map<String, dynamic>;
    final statePayload = data['state'] ?? data;
    return CollegeJournalSnapshot.fromJson(statePayload as Map<String, dynamic>);
  }
}

final scholarshipTeenagerJournalRepositoryProvider = Provider(
  (ref) => ScholarshipTeenagerJournalRepository(ref.read(dioProvider)),
);
