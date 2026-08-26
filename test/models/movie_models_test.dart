import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/movie_models.dart';

void main() {
  test('movie keyword groups parse legacy string and numeric fields', () {
    final group = MovieKeywordGroup.fromJson(<String, dynamic>{
      'id': '3',
      'p_id': 0,
      'keyword': '题材',
      'son_keyword': <Map<String, dynamic>>[
        <String, dynamic>{'id': 31, 'keyword': '剧情'},
        <String, dynamic>{'id': '32', 'keyword': '喜剧'},
      ],
    });

    expect(group.id, 3);
    expect(group.parentId, 0);
    expect(group.keyword, '题材');
    expect(group.children.map((item) => item.id), <int>[31, 32]);
    expect(group.children.map((item) => item.keyword), <String>['剧情', '喜剧']);
  });

  test('movie actor groups preserve legacy work covers and vip status', () {
    final actor = MovieActorGroup.fromJson(<String, dynamic>{
      'id': 8,
      'name': '演员甲',
      'post_number': '12',
      'post_obj': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 81,
          'cover_images': <String>['cover.jpg'],
          'title': '作品甲',
          'is_vip_watch': 1,
        },
      ],
    });

    expect(actor.id, 8);
    expect(actor.name, '演员甲');
    expect(actor.workCount, 12);
    expect(actor.works, hasLength(1));
    expect(actor.works.single.coverUrl, 'cover.jpg');
    expect(actor.works.single.isVipOnly, isTrue);
  });
}
