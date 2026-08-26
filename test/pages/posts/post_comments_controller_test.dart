import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/api/post_api.dart';
import 'package:b_flutter/models/paged_result.dart';
import 'package:b_flutter/models/post_comment.dart';
import 'package:b_flutter/pages/posts/post_comments_controller.dart';
import 'package:b_flutter/pages/posts/components/post_comment_item.dart';

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

  test('reply request preserves the legacy reply_content field', () {
    expect(
      PostApi.buildReplyPayload(commentId: 17, content: '回复正文'),
      <String, Object?>{'comment_id': 17, 'reply_content': '回复正文'},
    );
  });

  testWidgets(
    'comment card shows every legacy reply and hides self reply action',
    (tester) async {
      final value = PostComment.fromJson(<String, dynamic>{
        'id': 4,
        'post_id': 9,
        'content': '主评论',
        'created_member_id': 11,
        'created_member_obj': <String, dynamic>{'id': 11, 'nickname': '甲'},
        'son_reply_list': <String, dynamic>{
          'son_reply': List<Map<String, dynamic>>.generate(
            4,
            (index) => <String, dynamic>{
              'id': 20 + index,
              'content': '回复内容$index',
              'created_member_id': 20 + index,
              'created_member_obj': <String, dynamic>{
                'id': 20 + index,
                'nickname': '回复用户$index',
              },
              'target_member_obj': <String, dynamic>{'id': 11, 'nickname': '甲'},
            },
          ),
        },
      });
      PostComment? replyTarget;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCommentItem(
              comment: value,
              currentUserId: 11,
              onReply: (comment) => replyTarget = comment,
            ),
          ),
        ),
      );

      for (var index = 0; index < 4; index++) {
        expect(find.textContaining('回复内容$index'), findsOneWidget);
      }
      expect(find.text('共 4 条回复'), findsNothing);
      expect(find.text('  回复'), findsNothing);
      expect(find.text(' 回复'), findsNWidgets(4));

      await tester.tap(find.text(' 回复').last);
      expect(replyTarget?.id, 23);
      expect(tester.takeException(), isNull);
    },
  );
}
