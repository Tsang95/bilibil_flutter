import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/follow_user.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/pages/follow/follow_list_controller.dart';

void main() {
  FollowUser user(int id) =>
      FollowUser(id: id, nickname: '用户$id', avatarUrl: '');

  PagedResult<FollowUser> page({
    required int number,
    required int totalPages,
    required List<FollowUser> items,
  }) => PagedResult<FollowUser>(
    page: number,
    totalPages: totalPages,
    totalItems: items.length,
    isLastPage: number >= totalPages,
    items: items,
  );

  test('follow list preserves selected sort and de-duplicates pages', () async {
    final requested = <(String, FollowListSort, int)>[];
    final controller = FollowListController(
      loader: (keyword, sort, number, _) async {
        requested.add((keyword, sort, number));
        return number == 1
            ? page(number: 1, totalPages: 2, items: <FollowUser>[user(1)])
            : page(
                number: 2,
                totalPages: 2,
                items: <FollowUser>[user(1), user(2)],
              );
      },
    );

    await controller.search('  关键字  ');
    await controller.changeSort(FollowListSort.recent);
    await controller.loadMore();

    expect(requested, <(String, FollowListSort, int)>[
      ('关键字', FollowListSort.recommend, 1),
      ('关键字', FollowListSort.recent, 1),
      ('关键字', FollowListSort.recent, 2),
    ]);
    expect(controller.items.map((item) => item.id), <int>[1, 2]);
    expect(controller.hasMore, isFalse);
    controller.dispose();
  });
}
