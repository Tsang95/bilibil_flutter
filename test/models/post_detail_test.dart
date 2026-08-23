import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_detail.dart';

void main() {
  test('PostDetail normalizes mixed legacy fields and nested objects', () {
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': '18',
      'member_id': 7,
      'plate_one_id': '6',
      'type': 1,
      'collection_type': 0,
      'collection_id': '[18,19]',
      'video_id': '99',
      'duration': 125,
      'title': '测试内容',
      'describe': '<p>简介</p>',
      'content': <Object?>['/a.jpg', '', null, '/b.jpg'],
      'cover_images': <Object?>['/cover.jpg'],
      'price': '2.5',
      'sales_num': '3',
      'views_num': 12.0,
      'collect_num': 4,
      'like_num': '5',
      'coin_num': 6,
      'is_buy': 1,
      'is_collect': 1,
      'is_like': 0,
      'is_tip_coin': 1,
      'is_buy_download': 1,
      'download_price': '8',
      'jump_register': 1,
      'share_url': 'https://example.test/post/18',
      'created_at': '2026-08-23 10:00:00',
      'member_obj': <String, dynamic>{
        'id': 7,
        'nickname': '作者',
        'head_sculpture': '/avatar.jpg',
        'sign': '签名',
        'fan_num': 8,
        'work_num': 9,
        'isForce': 1,
      },
      'labelObj': <Object?>[
        <String, dynamic>{'id': 2, 'name': '标签'},
      ],
      'play_video_url': <Object?>[
        <String, dynamic>{'title': '线路一', 'url': 'https://video.test/a'},
      ],
      'advertise_obj': <Object?>[
        <String, dynamic>{
          'id': 3,
          'advertise_image': '/ad.jpg',
          'jump_url': 'https://example.test/ad',
        },
      ],
    });

    expect(detail.id, 18);
    expect(detail.price, 2.5);
    expect(detail.imageContent, <String>['/a.jpg', '/b.jpg']);
    expect(detail.isPurchased, isFalse);
    expect(detail.requiresCoinUnlock, isTrue);
    expect(detail.requiresRegistration, isTrue);
    expect(detail.isCollected, isTrue);
    expect(detail.videoId, 99);
    expect(detail.durationSeconds, 125);
    expect(detail.collectionId, '[18,19]');
    expect(detail.isCollection, isTrue);
    expect(detail.hasDownloadAccess, isTrue);
    expect(detail.downloadPrice, 8);
    expect(detail.author.nickname, '作者');
    expect(detail.author.isFollowing, isTrue);
    expect(detail.labels.single.name, '标签');
    expect(detail.videoChannels.single.title, '线路一');
    expect(detail.advertisements.single.imageUrl, '/ad.jpg');
    expect(detail.hasVideo, isTrue);
  });

  test('PostDetail falls back to legacy VIP access field', () {
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': 20,
      'price': 0,
      'is_vip_watch': 1,
    });

    expect(detail.unlockType, 2);
    expect(detail.requiresVipUnlock, isTrue);
  });

  test('PostDetail copyWith updates interaction state immutably', () {
    final detail = PostDetail.fromJson(<String, dynamic>{
      'id': 1,
      'content': '<p>正文</p>',
      'collect_num': 2,
      'like_num': 3,
      'coin_num': 4,
      'member_obj': <String, dynamic>{'id': 6, 'is_fans': 0},
    });
    final updated = detail.copyWith(
      collectCount: 3,
      likeCount: 4,
      coinCount: 5,
      isCollected: true,
      isLiked: true,
      hasTippedCoin: true,
      author: detail.author.copyWith(isFollowing: true),
    );

    expect(detail.isCollected, isFalse);
    expect(detail.author.isFollowing, isFalse);
    expect(updated.collectCount, 3);
    expect(updated.likeCount, 4);
    expect(updated.coinCount, 5);
    expect(updated.isCollected, isTrue);
    expect(updated.isLiked, isTrue);
    expect(updated.hasTippedCoin, isTrue);
    expect(updated.author.isFollowing, isTrue);
    expect(updated.htmlContent, '<p>正文</p>');
  });
}
