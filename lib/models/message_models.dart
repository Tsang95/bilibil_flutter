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
    );
  }

  final int id;
  final MessageMember operator;
  final int postId;
  final String postTitle;
  final String content;
  final String createdAt;

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

  factory MessageConversation.fromJson(Map<String, dynamic> json) {
    final rawContact = json['to_member_obj'] ?? json['from_member_obj'];
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

String _string(Object? value) => value?.toString() ?? '';

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
