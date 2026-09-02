final class MessageMember {
  const MessageMember({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
  });

  factory MessageMember.fromJson(Map<String, dynamic> json) => MessageMember(
        id: _integer(json['id'] ?? json['member_id']),
        nickname: _string(json['nickname']),
        avatarUrl: _string(json['head_sculpture'] ?? json['avatar']),
      );

  final int id;
  final String nickname;
  final String avatarUrl;
}

final class MessageInteraction {
  const MessageInteraction({
    required this.id,
    required this.operator,
    required this.postId,
    required this.postTitle,
    required this.content,
    required this.createdAt,
    this.postType = 0,
    this.postCollectionType = 0,
    this.postPrimaryCategoryId = 0,
    this.postHasCover = false,
    this.postHasHorizontalCover = false,
  });

  factory MessageInteraction.fromJson(Map<String, dynamic> json) {
    final member = json['member_obj'];
    final post = json['post_obj'];
    return MessageInteraction(
      id: _integer(json['id']),
      operator: member is Map
          ? MessageMember.fromJson(Map<String, dynamic>.from(member))
          : MessageMember.fromJson(const <String, dynamic>{}),
      postId: _integer(json['post_id'] ?? (post is Map ? post['id'] : null)),
      postTitle: _string(post is Map ? post['title'] : json['post_title']),
      content: _string(json['content']),
      createdAt: _string(json['created_at']),
      postType: _integer(post is Map ? post['type'] : null),
      postCollectionType:
          _integer(post is Map ? post['collection_type'] : null),
      postPrimaryCategoryId:
          _integer(post is Map ? post['plate_one_id'] : null),
      postHasCover: post is Map && _hasListValue(post['cover_images']),
      postHasHorizontalCover:
          post is Map && _hasListValue(post['horizontal_images']),
    );
  }

  final int id;
  final MessageMember operator;
  final int postId;
  final String postTitle;
  final String content;
  final String createdAt;
  final int postType;
  final int postCollectionType;
  final int postPrimaryCategoryId;
  final bool postHasCover;
  final bool postHasHorizontalCover;

  bool get isComment => content.isNotEmpty;
}

final class MessageConversation {
  const MessageConversation({
    required this.id,
    required this.contact,
    required this.content,
    required this.type,
    required this.lastChatAt,
  });

  factory MessageConversation.fromJson(
    Map<String, dynamic> json, {
    int currentUserId = 0,
  }) {
    final fromId = _integer(json['from_id']);
    final toId = _integer(json['to_id']);
    final rawContact = switch ((currentUserId, fromId, toId)) {
      (> 0, _, final recipientId) when recipientId == currentUserId =>
        json['from_member_obj'] ?? json['to_member_obj'],
      (> 0, final senderId, _) when senderId == currentUserId =>
        json['to_member_obj'] ?? json['from_member_obj'],
      _ => json['to_member_obj'] ?? json['from_member_obj'],
    };
    return MessageConversation(
      id: _integer(json['id']),
      contact: rawContact is Map
          ? MessageMember.fromJson(Map<String, dynamic>.from(rawContact))
          : MessageMember.fromJson(const <String, dynamic>{}),
      content: _string(json['content']),
      type: _string(json['type']),
      lastChatAt: _string(json['last_chat_time'] ?? json['updated_at']),
    );
  }

  final int id;
  final MessageMember contact;
  final String content;
  final String type;
  final String lastChatAt;

  String get preview => type == 'image' ? '[图片]' : content;
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: _integer(json['id']),
        fromId: _integer(json['from_id']),
        toId: _integer(json['to_id']),
        content: _string(json['content'] ?? json['data']),
        type: _string(json['type']),
        createdAt: _string(json['created_at'] ?? json['updated_at']),
      );

  final int id;
  final int fromId;
  final int toId;
  final String content;
  final String type;
  final String createdAt;

  bool isFrom(int memberId) => fromId == memberId;
}

final class MessageSocketEnvelope {
  const MessageSocketEnvelope({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedTime,
  });

  factory MessageSocketEnvelope.fromJson(Map<String, dynamic> json) {
    return MessageSocketEnvelope(
      id: _integer(json['id']),
      fromId: _integer(json['from_id']),
      toId: _integer(json['to_id']),
      type: _string(json['type']),
      data: _string(json['content'] ?? json['data']),
      createdAt: _string(json['created_at']),
      updatedAt: _string(json['updated_at']),
      updatedTime: _integer(json['update_time']),
    );
  }

  factory MessageSocketEnvelope.fromChatMessage(ChatMessage message) {
    final parsedTime = DateTime.tryParse(message.createdAt);
    return MessageSocketEnvelope(
      id: message.id,
      fromId: message.fromId,
      toId: message.toId,
      type: message.type,
      data: message.content,
      createdAt: message.createdAt,
      updatedAt: message.createdAt,
      updatedTime: parsedTime?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  final int id;
  final int fromId;
  final int toId;
  final String type;
  final String data;
  final String createdAt;
  final String updatedAt;
  final int updatedTime;

  bool get isChatMessage => type == 'text' || type == 'image';

  ChatMessage toChatMessage() => ChatMessage(
        id: id,
        fromId: fromId,
        toId: toId,
        content: data,
        type: type,
        createdAt: createdAt.isNotEmpty ? createdAt : updatedAt,
      );

  Map<String, Object?> toJson({String? groupId}) => <String, Object?>{
        'id': id,
        'from_id': fromId,
        'to_id': toId,
        'data': data,
        'type': type,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'update_time': updatedTime,
        if (groupId != null) 'groupId': groupId,
      };
}

String _string(Object? value) => value?.toString() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _hasListValue(Object? value) {
  return value is List && value.any((item) => _string(item).isNotEmpty);
}
