import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/college_journal_model.dart';
import '../models/college_profile_model.dart';
import '../models/college_review_list_model.dart';
import '../models/college_review_model.dart';

class CollegeJournalRepository {
  final Dio _dio;
  const CollegeJournalRepository(this._dio);

  Future<CollegeJournalSnapshot> today({String? date}) async {
    final res = await _dio.get(
      ApiConstants.collegeJurnalToday,
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
    String? jamMulai,
    String? jamSelesai,
    String? tipe,
  }) async {
    final res = await _dio.post(ApiConstants.collegeJurnalCheck, data: {
      'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (checked != null) 'checked': checked,
      if (date != null) 'date': date,
      if (jamMulai != null) 'jam_mulai': jamMulai,
      if (jamSelesai != null) 'jam_selesai': jamSelesai,
      if (tipe != null) 'tipe': tipe,
    });
    final data = res.data as Map<String, dynamic>;
    final payload = data['state'] ?? data;
    return CollegeJournalSnapshot.fromJson(payload as Map<String, dynamic>);
  }

  Future<CollegeJournalSnapshot> uploadPhoto(List<int> bytes, String filename, String date) async {
    final formData = FormData.fromMap({
      'date': date,
      'foto': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post(ApiConstants.collegeJurnalFoto, data: formData);
    final data = res.data as Map<String, dynamic>;
    final statePayload = data['state'] ?? data;
    return CollegeJournalSnapshot.fromJson(statePayload as Map<String, dynamic>);
  }

  Future<CollegeJournalSnapshot> deletePhoto(String date) async {
    final res = await _dio.delete(ApiConstants.collegeJurnalFoto, data: {'date': date});
    final data = res.data as Map<String, dynamic>;
    final statePayload = data['state'] ?? data;
    return CollegeJournalSnapshot.fromJson(statePayload as Map<String, dynamic>);
  }

  Future<CollegeJournalHistory> history({required String from, required String to}) async {
    final res = await _dio.get(
      ApiConstants.collegeJurnalHistory,
      queryParameters: {'from': from, 'to': to},
    );
    final data = res.data as Map<String, dynamic>;
    final list = (data['data'] as List? ?? []);
    return CollegeJournalHistory.fromJson(list);
  }

  Future<CollegeProfile?> profile() async {
    final res = await _dio.get(ApiConstants.collegeProfile);
    return CollegeProfile.fromJson(res.data as Map<String, dynamic>);
  }
}

class CollegeReviewRepository {
  final Dio _dio;
  const CollegeReviewRepository(this._dio);

  Future<CollegeReviewList> list({
    String? status, String? q, String? campus,
    int page = 1, int perPage = 20,
  }) async {
    final res = await _dio.get(
      ApiConstants.collegeReviewList,
      queryParameters: {
        if (status != null) 'status': status,
        if (q != null) 'q': q,
        if (campus != null) 'campus': campus,
        'page': page,
        'per_page': perPage,
      },
    );
    return CollegeReviewList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ScholarshipJournalDetail> detail(int id) async {
    final res = await _dio.get(ApiConstants.collegeReviewDetail(id));
    return ScholarshipJournalDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> submitReview(int id, {required String action, String? notes}) async {
    await _dio.post(ApiConstants.collegeReviewDetail(id), data: {
      'action': action,
      if (notes != null) 'reviewer_notes': notes,
    });
    return true;
  }
}

final collegeJournalRepositoryProvider = Provider(
  (ref) => CollegeJournalRepository(ref.read(dioProvider)),
);

final collegeReviewRepositoryProvider = Provider(
  (ref) => CollegeReviewRepository(ref.read(dioProvider)),
);
