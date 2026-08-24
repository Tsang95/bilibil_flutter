import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/banner_item.dart';
import 'package:b_flutter/models/home_category.dart';
import 'package:b_flutter/models/home_content_section.dart';
import 'package:b_flutter/models/home_label.dart';
import 'package:b_flutter/models/game_category.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/models/topic_summary.dart';

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

  test('message models accept legacy session and interaction fields', () {
    final interaction = MessageInteraction.fromJson(<String, dynamic>{
      'id': '7',
      'post_id': '22',
      'content': '很喜欢',
      'member_obj': <String, dynamic>{
        'id': 2,
        'nickname': '评论用户',
        'head_sculpture': '/avatar.png',
      },
      'post_obj': <String, dynamic>{'title': '旧版帖子'},
    });
    final session = MessageConversation.fromJson(<String, dynamic>{
      'id': 8,
      'content': '你好',
      'type': 'text',
      'to_member_obj': <String, dynamic>{'id': 3, 'nickname': '私信用户'},
    });

    expect(interaction.postId, 22);
    expect(interaction.operator.nickname, '评论用户');
    expect(interaction.isComment, isTrue);
    expect(session.contact.id, 3);
    expect(session.preview, '你好');
  });

  test('GameCategory preserves legacy nested game entries', () {
    final category = GameCategory.fromJson(<String, dynamic>{
      'id': '9',
      'name': '电子竞技',
      'thumb': '/category.png',
      'child': <Map<String, dynamic>>[
        <String, dynamic>{'id': '12', 'name': '测试游戏', 'thumb': '/game.png'},
      ],
    });

    expect(category.id, 9);
    expect(category.games.single.id, 12);
    expect(category.games.single.thumbnailUrl, '/game.png');
  });

  test('GameActivity preserves legacy timing and announcement content', () {
    final activity = GameActivity.fromJson(<String, dynamic>{
      'id': '4',
      'title': '周末优惠',
      'thumb': '/activity.png',
      'start_time': '1700000000',
      'end_time': 1700100000,
      'content': '<p>活动说明</p>',
    });

    expect(activity.id, 4);
    expect(activity.startTime, 1700000000);
    expect(activity.html, '<p>活动说明</p>');
  });

  test('GameLaunch keeps legacy URL, orientation and platform fields', () {
    final launch = GameLaunch.fromJson(<String, dynamic>{
      'jump_url': 'https://game.example.test/play',
      'show_type': '2',
      'platform_id': '31',
    });

    expect(launch.url, 'https://game.example.test/play');
    expect(launch.isLandscape, isTrue);
    expect(launch.platformId, 31);
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
          'member_obj': <String, Object>{
            'nickname': '作者',
            'head_sculpture': '/avatar.jpg',
          },
          'is_online': 1,
        },
      ],
    }, PostSummary.fromJson);

    expect(page.hasMore, isTrue);
    expect(page.items.single.price, 2.5);
    expect(page.items.single.preferredCoverUrl, 'cover.jpg');
    expect(page.items.single.authorNickname, '作者');
    expect(page.items.single.authorAvatarUrl, '/avatar.jpg');
    expect(page.items.single.isOnline, isTrue);
  });

  test('TopicSummary preserves legacy participation metadata', () {
    final topic = TopicSummary.fromJson(<String, dynamic>{
      'id': '8',
      'title': '测试话题',
      'describe': '话题说明',
      'view_num': '12000',
      'comment_num': 30,
      'last_time': '1724457600',
    });

    expect(topic.id, 8);
    expect(topic.description, '话题说明');
    expect(topic.viewCount, 12000);
    expect(topic.commentCount, 30);
    expect(topic.lastParticipatedAt, isNotNull);
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

  test('HomeLabel accepts the legacy classify label fields', () {
    final label = HomeLabel.fromJson(<String, dynamic>{
      'id': '12',
      'name': '精选',
    });

    expect(label.id, 12);
    expect(label.name, '精选');
  });
}
