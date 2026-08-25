import 'package:b_flutter/models/advertising_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('advertising dashboard parses legacy statistics and nested records', () {
    final dashboard = AdvertisingDashboard.fromJson(<String, dynamic>{
      'total': <String, dynamic>{
        'success_num': '3',
        'ing_num': 2,
        'fail_num': 1,
        'invalidation_num': 4,
      },
      'advertiseObj': <String, dynamic>{
        'page': 1,
        'totalPage': 1,
        'totalSize': 1,
        'list': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 9,
            'duration': '6',
            'type': 2,
            'price': '1800',
            'jump_url': 'https://example.com',
            'advertise_image': '/upload/ad.png',
            'click_num': '12',
            'status': 1,
            'created_at': '2026-08-25',
            'deadline_time': '2027-02-25',
            'plate_obj': <String, dynamic>{
              'id': 3,
              'name': '详情页横幅',
              'nickname': '广告位',
              'head_sculpture': '/upload/avatar.png',
            },
          },
        ],
      },
    });

    expect(dashboard.summary.successCount, 3);
    expect(dashboard.summary.pendingCount, 2);
    expect(dashboard.summary.failedCount, 1);
    expect(dashboard.summary.expiredCount, 4);
    expect(dashboard.records.items, hasLength(1));
    expect(dashboard.records.items.single.location.name, '详情页横幅');
    expect(dashboard.records.items.single.durationMonths, 6);
    expect(dashboard.records.items.single.clickCount, 12);
  });

  test('advertising placement and price accept legacy fields', () {
    final placement = AdvertisingPlacement.fromJson(<String, dynamic>{
      'id': '4',
      'name': '列表广告',
      'cover_image_tips': '建议尺寸 350×196',
      'preview_image': '/preview.png',
      'width': '350',
      'height': 196,
    });
    final price = AdvertisingPrice.fromJson(<String, dynamic>{
      'id': 6,
      'month_num': '3',
      'money': '999',
    });

    expect(placement.width, 350);
    expect(placement.height, 196);
    expect(price.months, 3);
    expect(price.amount, 999);
  });
}
