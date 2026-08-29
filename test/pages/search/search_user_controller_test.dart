import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/search_user.dart';
import 'package:b_flutter/pages/search/search_user_controller.dart';

void main() {
  SearchUser user(int id) => SearchUser(
        id: id,
        nickname: '用户$id',
        avatarUrl: '',
        movieLevel: 0,
        fanCount: 0,
        workCount: 0,
        isFollowing: false,
      );

  PagedResult<SearchUser> page({
    required int number,
    required int totalPages,
    required List<SearchUser> items,
  }) =>
      PagedResult<SearchUser>(
        page: number,
        totalPages: totalPages,
        totalItems: items.length,
        isLastPage: number >= totalPages,
        items: items,
      );

  test(
    'user search loads subsequent pages and removes duplicate ids',
    () async {
      final requestedPages = <int>[];
      final controller = SearchUserController(
        '测试',
        loader: (number, _) async {
          requestedPages.add(number);
          return number == 1
              ? page(number: 1, totalPages: 2, items: <SearchUser>[user(1)])
              : page(
                  number: 2,
                  totalPages: 2,
                  items: <SearchUser>[user(1), user(2)],
                );
        },
      );

      await controller.load();
      await controller.loadMore();

      expect(requestedPages, <int>[1, 2]);
      expect(controller.items.map((item) => item.id), <int>[1, 2]);
      expect(controller.hasMore, isFalse);
      controller.dispose();
    },
  );

  test('an empty next page stops repeated bottom requests', () async {
    var calls = 0;
    final controller = SearchUserController(
      '测试',
      loader: (number, _) async {
        calls++;
        return number == 1
            ? page(number: 1, totalPages: 3, items: <SearchUser>[user(1)])
            : page(number: number, totalPages: 3, items: <SearchUser>[]);
      },
    );

    await controller.load();
    await controller.loadMore();
    await controller.loadMore();

    expect(calls, 2);
    expect(controller.hasMore, isFalse);
    controller.dispose();
  });
}
