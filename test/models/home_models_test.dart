import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/home_content_section.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';

void main() {
  test('BannerItem preserves the legacy advertisement tracking id', () {
    final banner = BannerItem.fromJson(<String, dynamic>{
      'id': 1,
      'picture_url': '/detail-ad.jpg',
      'advertise_order_id ': '42',
    });

    expect(banner.pictureUrl, '/detail-ad.jpg');
    expect(banner.advertiseOrderId, 42);
  });

  test('HomeCategory parses nested legacy navigation values safely', () {
    final category = HomeCategory.fromJson(<String, dynamic>{
      'id': '19',
      'name': '影视',
      'son_type': <Map<String, Object>>[
        <String, Object>{'id': 20, 'name': '电影'},
      ],
    });

    expect(category.id, 19);
    expect(category.name, '影视');
    expect(category.children.single.id, 20);
  });

  test('PagedResult and PostSummary normalize mixed backend data', () {
    final page = PagedResult<PostSummary>.fromJson(<String, dynamic>{
      'page': 1,
      'totalPage': 2,
      'list': <Map<String, Object>>[
        <String, Object>{
          'id': 7,
          'title': '测试内容',
          'price': '2.5',
          'cover_images': <String>['cover.jpg'],
          'member_obj': <String, Object>{'nickname': '作者'},
        },
      ],
    }, PostSummary.fromJson);

    expect(page.hasMore, isTrue);
    expect(page.items.single.price, 2.5);
    expect(page.items.single.preferredCoverUrl, 'cover.jpg');
    expect(page.items.single.authorNickname, '作者');
  });

  test('HomeContentSection preserves category metadata and forum flags', () {
    final section = HomeContentSection.fromJson(<String, dynamic>{
      'twoObj': <String, Object>{
        'id': 6,
        'name': '竖版分区',
        'style_type': 2,
        'show_model': 5,
      },
      'detailList': <Map<String, Object>>[
        <String, Object>{
          'id': 1,
          'title': '会员内容',
          'sales_num': 12,
          'is_vip_watch': 1,
        },
      ],
    });

    expect(section.category.styleType, 2);
    expect(section.category.showModel, 5);
    expect(section.items.single.salesCount, 12);
    expect(section.items.single.isVipOnly, isTrue);
  });
}
