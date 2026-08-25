import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/creation_topic.dart';

void main() {
  test('creation topics preserve legacy groups and numeric aliases', () {
    final group = CreationTopicGroup.fromJson(<String, dynamic>{
      'id': '2',
      'name': '热门',
      'topic_obj': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '8',
          'title': '夏日投稿',
          'describe': '活动说明',
          'view_num': '999',
          'comment_num': 12,
          'label_id': '5',
        },
      ],
    });

    expect(group.id, 2);
    expect(group.name, '热门');
    expect(group.topics.single.id, 8);
    expect(group.topics.single.viewCount, 999);
    expect(group.topics.single.labelId, 5);
  });
}
