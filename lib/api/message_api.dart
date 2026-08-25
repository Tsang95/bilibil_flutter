import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/request_cache.dart';

abstract final class MessageApi {
  static Future<List<MessageConversation>> getConversations({
    bool forceRefresh = false,
  }) => ApiClient().get<List<MessageConversation>>(
    'api/friendLists',
    parser: (data) {
      final values = data is Map ? data['list'] : data;
      if (values is! List) return const <MessageConversation>[];
      return values
          .whereType<Map>()
          .map(
            (item) =>
                MessageConversation.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
    cacheTags: const <String>{'message_conversations'},
  );

  static Future<PagedResult<MessageInteraction>> getInteractions({
    required int page,
    required bool forceRefresh,
  }) => ApiClient().get<PagedResult<MessageInteraction>>(
    'api/systemMsgs',
    data: <String, Object?>{'type': 1, 'page': page},
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid message page');
      return PagedResult<MessageInteraction>.fromJson(
        Map<String, dynamic>.from(data),
        MessageInteraction.fromJson,
      );
    },
    cachePolicy: forceRefresh
        ? const CachePolicy.networkFirst(ttl: Duration(minutes: 1))
        : const CachePolicy.cacheFirst(ttl: Duration(minutes: 1)),
    cacheTags: const <String>{'message_interactions'},
  );

  static Future<List<ChatMessage>> getChatMessages({required int memberId}) =>
      ApiClient().get<List<ChatMessage>>(
        'api/messageLoads',
        data: <String, Object?>{'to_id': memberId},
        parser: (data) {
          final values = data is Map ? data['list'] : data;
          if (values is! List) return const <ChatMessage>[];
          return values
              .whereType<Map>()
              .map(
                (item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false);
        },
        cachePolicy: const CachePolicy.networkFirst(ttl: Duration(seconds: 30)),
        cacheTags: <String>{'chat_$memberId'},
      );

  static Future<ChatMessage> sendMessage({
    required int memberId,
    required String content,
    String type = 'text',
  }) => ApiClient().post<ChatMessage>(
    'api/chatSaves',
    data: <String, Object?>{
      'to_id': memberId,
      'content': content,
      'type': type,
    },
    parser: (data) {
      if (data is! Map) throw const FormatException('Invalid chat message');
      return ChatMessage.fromJson(Map<String, dynamic>.from(data));
    },
    deduplicate: true,
    invalidateCacheTags: <String>{'message_conversations', 'chat_$memberId'},
  );
}
