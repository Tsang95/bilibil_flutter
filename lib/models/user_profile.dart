import 'post_summary.dart';

final class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.backgroundUrl,
    required this.signature,
    required this.fanCount,
    required this.workCount,
    required this.likeCount,
    required this.isFollowing,
    required this.isSubscribed,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: _integer(json['id']),
        nickname: _string(json['nickname']),
        avatarUrl: _string(json['head_sculpture']),
        backgroundUrl: _string(json['background']),
        signature: _string(json['sign']),
        fanCount: _integer(json['fan_num']),
        workCount: _integer(json['work_num']),
        likeCount: _integer(json['like_num']),
        isFollowing: _integer(json['is_fans'] ?? json['is_force']) == 1,
        isSubscribed: _integer(json['is_sub']) == 1,
      );

  final int id;
  final String nickname;
  final String avatarUrl;
  final String backgroundUrl;
  final String signature;
  final int fanCount;
  final int workCount;
  final int likeCount;
  final bool isFollowing;
  final bool isSubscribed;

  UserProfile copyWith({bool? isFollowing}) => UserProfile(
        id: id,
        nickname: nickname,
        avatarUrl: avatarUrl,
        backgroundUrl: backgroundUrl,
        signature: signature,
        fanCount: fanCount,
        workCount: workCount,
        likeCount: likeCount,
        isFollowing: isFollowing ?? this.isFollowing,
        isSubscribed: isSubscribed,
      );
}

final class UserProfileHighlightGroup {
  const UserProfileHighlightGroup({required this.count, required this.posts});

  factory UserProfileHighlightGroup.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['data'];
    return UserProfileHighlightGroup(
      count: _integer(json['count']),
      posts: rawPosts is List
          ? rawPosts
              .whereType<Map>()
              .map((item) {
                final rawPost = item['post_content_obj'];
                return rawPost is Map
                    ? PostSummary.fromJson(Map<String, dynamic>.from(rawPost))
                    : PostSummary.fromJson(const <String, dynamic>{});
              })
              .where((item) => item.id > 0)
              .toList(growable: false)
          : const <PostSummary>[],
    );
  }

  final int count;
  final List<PostSummary> posts;
}

final class UserProfileHighlights {
  const UserProfileHighlights({
    required this.liked,
    required this.purchased,
    required this.collected,
    required this.coined,
  });

  factory UserProfileHighlights.fromJson(Map<String, dynamic> json) =>
      UserProfileHighlights(
        liked: _group(json['praise']),
        purchased: _group(json['buy']),
        collected: _group(json['collect']),
        coined: _group(json['coin']),
      );

  final UserProfileHighlightGroup liked;
  final UserProfileHighlightGroup purchased;
  final UserProfileHighlightGroup collected;
  final UserProfileHighlightGroup coined;

  static UserProfileHighlightGroup _group(Object? value) => value is Map
      ? UserProfileHighlightGroup.fromJson(Map<String, dynamic>.from(value))
      : const UserProfileHighlightGroup(count: 0, posts: <PostSummary>[]);
}

String _string(Object? value) => value?.toString() ?? '';

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
