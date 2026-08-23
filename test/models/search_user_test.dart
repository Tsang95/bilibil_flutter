import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/search_user.dart';

void main() {
  test('SearchUser parses legacy fields and supports follow updates', () {
    final user = SearchUser.fromJson(<String, dynamic>{
      'id': '7',
      'nickname': '测试用户',
      'head_sculpture': '/avatar.png',
      'movie_level': 2,
      'fan_num': '18',
      'work_num': 4,
      'is_force': 1,
    });

    expect(user.id, 7);
    expect(user.nickname, '测试用户');
    expect(user.movieLevel, 2);
    expect(user.fanCount, 18);
    expect(user.isFollowing, isTrue);
    expect(user.copyWith(isFollowing: false).isFollowing, isFalse);
  });
}
