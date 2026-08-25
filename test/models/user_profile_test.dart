import 'package:b_flutter/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user profile and legacy highlight sections parse safely', () {
    final profile = UserProfile.fromJson(<String, dynamic>{
      'id': '8',
      'nickname': '测试 UP 主',
      'head_sculpture': '/avatar.png',
      'background': '/background.png',
      'sign': '简介',
      'fan_num': '12',
      'work_num': 3,
      'like_num': '45',
      'is_fans': 1,
      'is_sub': 1,
    });
    final highlights = UserProfileHighlights.fromJson(<String, dynamic>{
      'praise': <String, dynamic>{
        'count': '1',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'post_content_obj': <String, dynamic>{
              'id': 10,
              'title': '旧版点赞视频',
              'cover_images': <String>['/cover.png'],
            },
          },
        ],
      },
    });

    expect(profile.id, 8);
    expect(profile.isFollowing, isTrue);
    expect(profile.likeCount, 45);
    expect(highlights.liked.count, 1);
    expect(highlights.liked.posts.single.title, '旧版点赞视频');
    expect(highlights.purchased.posts, isEmpty);
  });
}
