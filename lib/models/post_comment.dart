import 'package:b_flutter/models/post_detail.dart';

final class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.parentId,
    required this.createdMemberId,
    required this.targetMemberId,
    required this.content,
    required this.createdAt,
    required this.author,
    required this.targetAuthor,
    required this.replies,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final rawReplyContainer = json['son_reply_list'];
    final rawReplies = rawReplyContainer is Map
        ? rawReplyContainer['son_reply']
        : null;
    return PostComment(
      id: _integer(json['id']),
      postId: _integer(json['post_id']),
      parentId: _integer(json['p_id']),
      createdMemberId: _integer(json['created_member_id']),
      targetMemberId: _integer(json['target_member_id']),
      content: _string(json['content']),
      createdAt: DateTime.tryParse(_string(json['created_at'])),
      author: PostAuthor.fromJson(_map(json['created_member_obj'])),
      targetAuthor: PostAuthor.fromJson(_map(json['target_member_obj'])),
      replies: rawReplies is List
          ? rawReplies
                .whereType<Map>()
                .map(
                  (item) =>
                      PostComment.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <PostComment>[],
    );
  }

  final int id;
  final int postId;
  final int parentId;
  final int createdMemberId;
  final int targetMemberId;
  final String content;
  final DateTime? createdAt;
  final PostAuthor author;
  final PostAuthor targetAuthor;
  final List<PostComment> replies;

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _map(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }
}
