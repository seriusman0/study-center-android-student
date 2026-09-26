class UserDto {
  final int id;
  final String name;
  final String? avatar;

  const UserDto({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory UserDto.fromJson(Map<String, dynamic> j) => UserDto(
        id: j['id'] as int,
        name: j['name']?.toString() ?? '',
        avatar: j['avatar']?.toString(),
      );
}

class ReplyToDto {
  final int id;
  final String? body;
  final int userId;

  const ReplyToDto({
    required this.id,
    this.body,
    required this.userId,
  });

  factory ReplyToDto.fromJson(Map<String, dynamic> j) => ReplyToDto(
        id: j['id'] as int,
        body: j['body']?.toString(),
        userId: j['user_id'] as int,
      );
}

class MessageDto {
  final int id;
  final int conversationId;
  final int userId;
  final int? replyToId;
  final String type;
  final String? body;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMime;
  final int? attachmentSize;
  final String? thumbnailUrl;
  final ReplyToDto? replyTo;
  final String? deletedAt;
  final String createdAt;
  final UserDto? user;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.replyToId,
    required this.type,
    this.body,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMime,
    this.attachmentSize,
    this.thumbnailUrl,
    this.replyTo,
    this.deletedAt,
    required this.createdAt,
    this.user,
  });

  factory MessageDto.fromJson(Map<String, dynamic> j) => MessageDto(
        id: j['id'] as int,
        conversationId: j['conversation_id'] as int,
        userId: j['user_id'] as int,
        replyToId: j['reply_to_id'] as int?,
        type: j['type']?.toString() ?? 'text',
        body: j['body']?.toString(),
        attachmentUrl: j['attachment_url']?.toString(),
        attachmentName: j['attachment_name']?.toString(),
        attachmentMime: j['attachment_mime']?.toString(),
        attachmentSize: j['attachment_size'] as int?,
        thumbnailUrl: j['thumbnail_url']?.toString(),
        replyTo: j['reply_to'] != null ? ReplyToDto.fromJson(Map<String, dynamic>.from(j['reply_to'] as Map)) : null,
        deletedAt: j['deleted_at']?.toString(),
        createdAt: j['created_at']?.toString() ?? '',
        user: j['user'] != null ? UserDto.fromJson(Map<String, dynamic>.from(j['user'] as Map)) : null,
      );
}

class ConversationDto {
  final int id;
  final String type;
  final String? name;
  final String? avatar;
  final String displayName;
  final int unreadCount;
  final String? lastMessageAt;
  final MessageDto? lastMessage;
  final List<UserDto> participants;

  const ConversationDto({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    required this.displayName,
    required this.unreadCount,
    this.lastMessageAt,
    this.lastMessage,
    required this.participants,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> j) => ConversationDto(
        id: j['id'] as int,
        type: j['type']?.toString() ?? 'private',
        name: j['name']?.toString(),
        avatar: j['avatar']?.toString(),
        displayName: j['display_name']?.toString() ?? '',
        unreadCount: j['unread_count'] as int? ?? 0,
        lastMessageAt: j['last_message_at']?.toString(),
        lastMessage: j['last_message'] != null ? MessageDto.fromJson(Map<String, dynamic>.from(j['last_message'] as Map)) : null,
        participants: (j['participants'] as List?)
                ?.where((e) => e is Map)
                .map((e) => UserDto.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
}
