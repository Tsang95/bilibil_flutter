import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_comment.dart';
import 'package:b_flutter/pages/posts/post_comments_controller.dart';

void main() {
  PostComment comment(int id) => PostComment.fromJson(<String, dynamic>{
    'id': id,
    'post_id': 9,
    'content': '评论$id',
    'created_member_id': id + 10,
    'created_member_obj': <String, dynamic>{'id': id + 10, 'nickname': '用户$id'},
  });

  PagedResult<PostComment> page({
    required int number,
    required int totalPages,
    required List<PostComment> items,
  }) => PagedResult<PostComment>(
    page: number,
    totalPages: totalPages,
    totalItems: items.length,
    isLastPage: number >= totalPages,
    items: items,
  );

  test('comments append next page and remove duplicate ids', () async {
    final requestedPages = <int>[];
    final controller = PostCommentsController(
      9,
      loader: (number, _) async {
        requestedPages.add(number);
        return number == 1
            ? page(number: 1, totalPages: 2, items: <PostComment>[comment(1)])
            : page(
                number: 2,
                totalPages: 2,
                items: <PostComment>[comment(1), comment(2)],
              );
      },
    );

    await controller.load();
    await controller.loadMore();

    expect(requestedPages, <int>[1, 2]);
    expect(controller.items.map((item) => item.id), <int>[1, 2]);
    expect(controller.hasMore, isFalse);
    controller.dispose();
  });

  test('comment model parses reply previews safely', () {
    final value = PostComment.fromJson(<String, dynamic>{
      'id': '4',
      'post_id': 9,
      'content': '主评论',
      'created_member_obj': <String, dynamic>{'id': 2, 'nickname': '甲'},
      'son_reply_list': <String, dynamic>{
        'son_reply': <Object?>[
          <String, dynamic>{
            'id': 5,
            'content': '回复内容',
            'created_member_obj': <String, dynamic>{'id': 3, 'nickname': '乙'},
            'target_member_obj': <String, dynamic>{'id': 2, 'nickname': '甲'},
          },
        ],
      },
    });

    expect(value.id, 4);
    expect(value.author.nickname, '甲');
    expect(value.replies.single.content, '回复内容');
    expect(value.replies.single.targetAuthor.nickname, '甲');
  });
}
