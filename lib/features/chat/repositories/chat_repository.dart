import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/chat_models.dart';

class ChatRepository {
  final Dio _dio;

  const ChatRepository(this._dio);

  Future<List<ConversationDto>> getConversations() async {
    final res = await _dio.get(ApiConstants.chatConversations);
    final data = res.data as Map<String, dynamic>;
    final list = data['data'] as List? ?? [];
    return list
        .where((e) => e is Map)
        .map((e) => ConversationDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getMessages(int convId, {int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.chatMessages(convId),
      queryParameters: {'page': page},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<int> startPrivateChat(int userId) async {
    final res = await _dio.post(ApiConstants.chatPrivate(userId));
    final data = res.data as Map<String, dynamic>;
    return data['conversation_id'] as int;
  }

  Future<int> createGroup(String name, List<int> userIds) async {
    final res = await _dio.post(ApiConstants.chatGroup, data: {
      'name': name,
      'user_ids': userIds,
    });
    final data = res.data as Map<String, dynamic>;
    return data['conversation_id'] as int;
  }

  Future<MessageDto> sendMessage({
    required int convId,
    required String type,
    String? body,
    int? replyToId,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    dynamic data;
    if (type == 'text') {
      data = {
        'type': 'text',
        'body': body,
        if (replyToId != null) 'reply_to_id': replyToId,
      };
    } else {
      data = FormData.fromMap({
        'type': type,
        if (body != null) 'body': body,
        if (replyToId != null) 'reply_to_id': replyToId.toString(),
        if (fileBytes != null && fileName != null)
          'attachment': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
    }

    final res = await _dio.post(ApiConstants.chatMessages(convId), data: data);
    final resData = res.data as Map<String, dynamic>;
    return MessageDto.fromJson(resData['message'] as Map<String, dynamic>);
  }

  Future<bool> deleteMessage(int msgId) async {
    final res = await _dio.delete(ApiConstants.chatMessageDelete(msgId));
    return res.statusCode == 200;
  }

  Future<bool> markRead(int convId) async {
    final res = await _dio.post(ApiConstants.chatMarkRead(convId));
    return res.statusCode == 200;
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get(ApiConstants.chatUnreadCount);
    final data = res.data as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }
}

final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.read(dioProvider)));
