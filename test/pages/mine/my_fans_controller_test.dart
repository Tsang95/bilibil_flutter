import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/fan_user.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/pages/mine/my_fans_controller.dart';

void main() {
  FanUser fan(int relationId) => FanUser(
    relationId: relationId,
    id: relationId + 100,
    nickname: '粉丝$relationId',
    avatarUrl: '',
    fanCount: 0,
    lastActiveAt: null,
    isFollowing: false,
  );

  test('fans list de-duplicates relation records across pages', () async {
    final calls = <int>[];
    final controller = MyFansController(
      loader: (page, _) async {
        calls.add(page);
        return PagedResult<FanUser>(
          page: page,
          totalPages: 2,
          totalItems: 2,
          isLastPage: page >= 2,
          items: page == 1 ? <FanUser>[fan(1)] : <FanUser>[fan(1), fan(2)],
        );
      },
    );

    await controller.loadInitial();
    await controller.loadMore();

    expect(calls, <int>[1, 2]);
    expect(controller.items.map((item) => item.relationId), <int>[1, 2]);
    expect(controller.hasMore, isFalse);
    controller.dispose();
  });
}
