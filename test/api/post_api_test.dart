import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/api/post_api.dart';

void main() {
  test('user profile video page unwraps legacy post_content_obj records', () {
    final page = PostApi.parseUserProfileVideoPage(<String, dynamic>{
      'page': 2,
      'totalPage': 3,
      'totalSize': 5,
      'is_last': false,
      'list': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 90,
          'member_id': 7,
          'post_content_id': 18,
          'type': 1,
          'post_content_obj': <String, dynamic>{
            'id': 18,
            'title': '旧版点赞视频列表项',
            'cover_images': <String>['/cover.jpg'],
            'views_num': '12',
            'collect_num': 3,
          },
        },
      ],
    });

    expect(page.page, 2);
    expect(page.totalPages, 3);
    expect(page.totalItems, 5);
    expect(page.hasMore, isTrue);
    expect(page.items.single.id, 18);
    expect(page.items.single.title, '旧版点赞视频列表项');
    expect(page.items.single.viewCount, 12);
    expect(page.items.single.collectCount, 3);
  });

  test('user profile video page ignores records without a valid post', () {
    final page = PostApi.parseUserProfileVideoPage(<String, dynamic>{
      'page': 1,
      'totalPage': 1,
      'is_last': true,
      'list': <Map<String, dynamic>>[
        <String, dynamic>{'post_content_obj': <String, dynamic>{}},
      ],
    });

    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
  });
}
