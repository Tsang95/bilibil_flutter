import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/post_barrage.dart';

void main() {
  test('PostBarrage normalizes legacy numeric and text fields', () {
    final barrage = PostBarrage.fromJson(<String, dynamic>{
      'id': '7',
      'post_content_id': 18.0,
      'content': '  测试弹幕  ',
      'play_time': '12',
    });

    expect(barrage.id, 7);
    expect(barrage.postId, 18);
    expect(barrage.content, '测试弹幕');
    expect(barrage.playTime, const Duration(seconds: 12));
  });

  test('PostBarrage supports backend aliases and fractional timestamps', () {
    final barrage = PostBarrage.fromJson(<String, dynamic>{
      'barrage_id': 8,
      'post_id': '19',
      'text': '  第二条弹幕 ',
      'playTime': '01:02.5',
    });
    final millisecondBarrage = PostBarrage.fromJson(<String, dynamic>{
      'id': 9,
      'postContentId': 19,
      'barrage': '第三条弹幕',
      'play_time_ms': '2300',
    });

    expect(barrage.id, 8);
    expect(barrage.postId, 19);
    expect(barrage.content, '第二条弹幕');
    expect(barrage.playTime, const Duration(milliseconds: 62500));
    expect(millisecondBarrage.playTime, const Duration(milliseconds: 2300));
  });
}
