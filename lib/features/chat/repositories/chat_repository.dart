import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/offline_service.dart';
import '../services/local_chat_database.dart';
import '../models/chat_models.dart';

final localChatDatabaseProvider = Provider((ref) => LocalChatDatabase());

class ChatRepository {
  final Dio _dio;
  final LocalChatDatabase _localDb;
  final OfflineService _offlineService;

  const ChatRepository(this._dio, this._localDb, this._offlineService);

  Future<List<ConversationDto>> getConversations() async {
    try {
      final res = await _dio.get(ApiConstants.chatConversations);
      final data = res.data as Map<String, dynamic>;
      final list = data['data'] as List? ?? [];
      final parsed = list
          .where((e) => e is Map)
          .map((e) => ConversationDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      
      // Save to local DB in background
      _localDb.saveConversations(parsed).ignore();
      return parsed;
    } catch (e) {
      // Fallback to local DB if offline
      final localData = await _localDb.getConversations();
      return localData.map((e) => ConversationDto.fromJson(e)).toList();
    }
  }

  Future<Map<String, dynamic>> getMessages(int convId, {int page = 1}) async {
    try {
      final res = await _dio.get(
        ApiConstants.chatMessages(convId),
        queryParameters: {'page': page},
      );
      final data = res.data as Map<String, dynamic>;
      final rawList = data['data'] as List? ?? [];
      final parsed = rawList
          .where((e) => e is Map)
          .map((e) => MessageDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      
      // Save to local DB in background
      _localDb.saveMessages(convId, parsed).ignore();
      
      return data;
    } catch (e) {
      if (page == 1) {
        // Fallback to local DB if offline (only for page 1 for simplicity in offline mode)
        final localData = await _localDb.getMessages(convId);
        return {
          'data': localData,
          'last_page': 1,
        };
      }
      rethrow;
    }
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
    // 1. Prepare local fake message and UUID
    final uuid = DateTime.now().millisecondsSinceEpoch.toString(); // Simple UUID
    final now = DateTime.now().toIso8601String();
    
    dynamic data;
    Map<String, dynamic> localPayload;
    
    if (type == 'text') {
      data = {
        'type': 'text',
        'body': body,
        if (replyToId != null) 'reply_to_id': replyToId,
      };
      localPayload = {
        'id': -(DateTime.now().millisecondsSinceEpoch % 1000000000), // Random negative ID
        'conversation_id': convId,
        'user_id': 0, // Should be actual user ID, but 0 works for pending UI if we don't know it
        'type': type,
        'body': body,
        'created_at': now,
        'status': 'pending',
        'uuid': uuid,
      };
    } else {
      data = FormData.fromMap({
        'type': type,
        if (body != null) 'body': body,
        if (replyToId != null) 'reply_to_id': replyToId.toString(),
        if (fileBytes != null && fileName != null)
          'attachment': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });
      localPayload = {
        'id': -(DateTime.now().millisecondsSinceEpoch % 1000000000),
        'conversation_id': convId,
        'user_id': 0,
        'type': type,
        'body': body,
        'created_at': now,
        'status': 'pending',
        'uuid': uuid,
      };
    }

    // 2. Save pending to LocalDB
    await _localDb.savePendingMessage(uuid, convId, localPayload, now);
    
    // 3. Queue in OfflineService (Note: file upload might need complex handling in queue, keeping it simple for text)
    int? opId;
    if (type == 'text') {
      opId = await _offlineService.enqueue(OfflineOpKind.sendChatMessage, {
        'uuid': uuid,
        'conv_id': convId.toString(),
        'type': type,
        'body': body ?? '',
        if (replyToId != null) 'reply_to_id': replyToId.toString(),
      });
    }

    // 4. Try sending immediately
    try {
      final res = await _dio.post(ApiConstants.chatMessages(convId), data: data);
      final resData = res.data as Map<String, dynamic>;
      final realMessage = MessageDto.fromJson(resData['message'] as Map<String, dynamic>);
      
      // Update local DB to 'sent'
      await _localDb.updateMessageStatus(uuid, realMessage.id, realMessage.toJson());
      
      // Remove from OfflineService queue
      if (opId != null) {
        await _offlineService.remove(opId);
      }
      
      return realMessage;
    } catch (e) {
      // If failed, return the pending message so UI can show it
      return MessageDto.fromJson(localPayload);
    }
  }

  Future<MessageDto> syncMessage({
    required String uuid,
    required int convId,
    required String type,
    String? body,
    int? replyToId,
  }) async {
    final data = {
      'type': type,
      'body': body,
      if (replyToId != null) 'reply_to_id': replyToId,
    };

    final res = await _dio.post(ApiConstants.chatMessages(convId), data: data);
    final resData = res.data as Map<String, dynamic>;
    final realMessage = MessageDto.fromJson(resData['message'] as Map<String, dynamic>);
    
    // Update local DB to 'sent'
    await _localDb.updateMessageStatus(uuid, realMessage.id, realMessage.toJson());
    return realMessage;
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

final chatRepositoryProvider = Provider((ref) => ChatRepository(
  ref.read(dioProvider),
  ref.read(localChatDatabaseProvider),
  ref.read(offlineServiceProvider),
));
