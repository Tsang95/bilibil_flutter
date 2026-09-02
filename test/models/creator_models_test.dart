import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/creator_models.dart';

void main() {
  test('creator dashboard preserves legacy count and income aliases', () {
    final dashboard = CreatorDashboard.fromJson(<String, dynamic>{
      'count': <String, dynamic>{
        'sun_count': '12',
        'ing_count': 3,
        'collection_count': '45',
      },
      'income': <String, dynamic>{
        'list': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '8',
            'gold_num': '6.5',
            'post_title': '收益帖子',
            'created_at': '2026-08-25',
          },
        ],
      },
    });

    expect(dashboard.allCount, 12);
    expect(dashboard.reviewingCount, 3);
    expect(dashboard.collectionCount, 45);
    expect(dashboard.incomes.single.id, 8);
    expect(dashboard.incomes.single.goldAmount, 6.5);
    expect(dashboard.incomes.single.formattedGold, '6.5');
  });

  test('creator work parses cover, category, metrics and review reason', () {
    final work = CreatorWork.fromJson(<String, dynamic>{
      'id': '9',
      'title': '我的作品',
      'cover_images': <String>['cover.jpg'],
      'is_vip_watch': '1',
      'sales_num': '2',
      'views_num': 30,
      'collect_num': '4',
      'reason': '封面不合规',
      'plate_two_obj': <String, dynamic>{'name': '动画'},
      'type': '5',
      'collection_type': '1',
      'plate_one_id': '6',
      'horizontal_images': <String>['wide.jpg'],
    });

    expect(work.id, 9);
    expect(work.preferredCoverUrl, 'cover.jpg');
    expect(work.vipOnly, isTrue);
    expect(work.salesCount, 2);
    expect(work.viewsCount, 30);
    expect(work.collectCount, 4);
    expect(work.categoryName, '动画');
    expect(work.reason, '封面不合规');
    expect(work.type, 5);
    expect(work.collectionType, 1);
    expect(work.primaryCategoryId, 6);
    expect(work.horizontalCoverUrls, <String>['wide.jpg']);
  });
}
