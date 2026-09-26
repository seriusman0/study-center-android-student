import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/jurnal_config_model.dart';

class JurnalLifeItemsRepository {
  final Dio _dio;
  const JurnalLifeItemsRepository(this._dio);

  Future<List<JurnalLifeItem>> fetch() async {
    final response = await _dio.get(ApiConstants.adminJurnalLifeItems);
    final data = (response.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => JurnalLifeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> create(JurnalLifeItem item) async {
    await _dio.post(ApiConstants.adminJurnalLifeItems, data: item.toJson());
  }

  Future<void> update(int id, JurnalLifeItem item) async {
    await _dio.put(ApiConstants.adminJurnalLifeItemDetail(id), data: item.toJson());
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.adminJurnalLifeItemDetail(id));
  }
}

final jurnalLifeItemsRepositoryProvider =
    Provider((ref) => JurnalLifeItemsRepository(ref.read(dioProvider)));

class JurnalLifeItemsState {
  final bool loading;
  final List<JurnalLifeItem> items;
  final String? error;

  const JurnalLifeItemsState({this.loading = false, this.items = const [], this.error});
}

class JurnalLifeItemsNotifier extends Notifier<JurnalLifeItemsState> {
  @override
  JurnalLifeItemsState build() => const JurnalLifeItemsState();

  Future<void> load() async {
    state = JurnalLifeItemsState(loading: true, items: state.items);
    try {
      final items = await ref.read(jurnalLifeItemsRepositoryProvider).fetch();
      state = JurnalLifeItemsState(items: items);
    } catch (e) {
      state = JurnalLifeItemsState(error: extractErrorMessage(e), items: state.items);
    }
  }

  Future<bool> create(JurnalLifeItem item) async {
    try {
      await ref.read(jurnalLifeItemsRepositoryProvider).create(item);
      await load();
      return true;
    } catch (e) {
      state = JurnalLifeItemsState(error: extractErrorMessage(e), items: state.items);
      return false;
    }
  }

  Future<bool> update(int id, JurnalLifeItem item) async {
    try {
      await ref.read(jurnalLifeItemsRepositoryProvider).update(id, item);
      await load();
      return true;
    } catch (e) {
      state = JurnalLifeItemsState(error: extractErrorMessage(e), items: state.items);
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(jurnalLifeItemsRepositoryProvider).delete(id);
      await load();
      return true;
    } catch (e) {
      state = JurnalLifeItemsState(error: extractErrorMessage(e), items: state.items);
      return false;
    }
  }

  Future<bool> toggleActive(JurnalLifeItem item) async {
    return update(
      item.id,
      JurnalLifeItem(
        id: item.id,
        kategori: item.kategori,
        label: item.label,
        isDefault: item.isDefault,
        isActive: !item.isActive,
      ),
    );
  }
}

final jurnalLifeItemsProvider =
    NotifierProvider<JurnalLifeItemsNotifier, JurnalLifeItemsState>(JurnalLifeItemsNotifier.new);
