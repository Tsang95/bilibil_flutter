import 'package:dash_chat_2/dash_chat_2.dart' as dash;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/pages/message/message_chat_page.dart';

void main() {
  testWidgets('chat list follows the yes_flutter message row layout', (
    tester,
  ) async {
    final scrollController = ScrollController();
    final inputController = TextEditingController();
    final inputFocusNode = FocusNode();
    addTearDown(scrollController.dispose);
    addTearDown(inputController.dispose);
    addTearDown(inputFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageChatView(
            messages: const <ChatMessage>[
              ChatMessage(
                id: 1,
                fromId: 7,
                toId: 9,
                content: '我发出的消息',
                type: 'text',
                createdAt: '2026-09-01 09:00:00',
              ),
              ChatMessage(
                id: 2,
                fromId: 9,
                toId: 7,
                content: '',
                type: 'image',
                createdAt: '2026-09-01 09:01:00',
              ),
            ],
            currentUserId: 7,
            currentUserNickname: '当前用户',
            currentUserAvatarUrl: '',
            contact: const MessageMember(
              id: 9,
              nickname: '聊天对象',
              avatarUrl: '',
            ),
            scrollController: scrollController,
            inputController: inputController,
            inputFocusNode: inputFocusNode,
            submitting: false,
            onLoadEarlier: _completeAction,
            onSelectImage: _completeAction,
            onSendText: _completeSend,
          ),
        ),
      ),
    );

    expect(find.byType(dash.DashChat), findsOneWidget);
    expect(find.text('当前用户'), findsOneWidget);
    expect(find.text('聊天对象'), findsOneWidget);
    expect(find.byKey(const Key('message-chat-avatar')), findsNWidgets(2));

    final avatar = tester.widget<Container>(
      find.byKey(const Key('message-chat-avatar')).first,
    );
    expect(avatar.constraints?.maxWidth, 48);
    expect(avatar.constraints?.maxHeight, 48);

    final textBubble = tester.widget<Container>(
      find.byKey(const Key('message-chat-text-1')),
    );
    final textDecoration = textBubble.decoration! as BoxDecoration;
    expect(textDecoration.color, const Color(0xFF6A90FE));
    expect(textDecoration.borderRadius, BorderRadius.circular(12));

    final imageBubble = tester.widget<Container>(
      find.byKey(const Key('message-chat-image-2')),
    );
    expect(imageBubble.constraints?.maxWidth, 150);
    expect(imageBubble.constraints?.maxHeight, 150);

    final mineAvatar = find.descendant(
      of: find.byKey(const Key('message-chat-row-1')),
      matching: find.byKey(const Key('message-chat-avatar')),
    );
    final otherAvatar = find.descendant(
      of: find.byKey(const Key('message-chat-row-2')),
      matching: find.byKey(const Key('message-chat-avatar')),
    );
    expect(tester.getCenter(mineAvatar).dx,
        greaterThan(tester.getCenter(otherAvatar).dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat list offers a shortcut back to the newest message', (
    tester,
  ) async {
    final scrollController = ScrollController();
    final inputController = TextEditingController();
    final inputFocusNode = FocusNode();
    addTearDown(scrollController.dispose);
    addTearDown(inputController.dispose);
    addTearDown(inputFocusNode.dispose);
    final messages = List<ChatMessage>.generate(
      30,
      (index) => ChatMessage(
        id: index + 1,
        fromId: index.isEven ? 7 : 9,
        toId: index.isEven ? 9 : 7,
        content: '消息 $index',
        type: 'text',
        createdAt: '2026-09-01 09:00:00',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageChatView(
            messages: messages,
            currentUserId: 7,
            currentUserNickname: '当前用户',
            currentUserAvatarUrl: '',
            contact: const MessageMember(
              id: 9,
              nickname: '聊天对象',
              avatarUrl: '',
            ),
            scrollController: scrollController,
            inputController: inputController,
            inputFocusNode: inputFocusNode,
            submitting: false,
            onLoadEarlier: _completeAction,
            onSelectImage: _completeAction,
            onSendText: _completeSend,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('message-chat-scroll-to-bottom')),
      findsNothing,
    );

    scrollController.jumpTo(300);
    await tester.pump();
    expect(
      find.byKey(const Key('message-chat-scroll-to-bottom')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('message-chat-scroll-to-bottom')));
    await tester.pumpAndSettle();
    expect(
      scrollController.offset,
      closeTo(0, 0.1),
    );
  });

  testWidgets('dash chat input forwards and clears a text message', (
    tester,
  ) async {
    final scrollController = ScrollController();
    final inputController = TextEditingController();
    final inputFocusNode = FocusNode();
    addTearDown(scrollController.dispose);
    addTearDown(inputController.dispose);
    addTearDown(inputFocusNode.dispose);
    String sentText = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageChatView(
            messages: const <ChatMessage>[],
            currentUserId: 7,
            currentUserNickname: '当前用户',
            currentUserAvatarUrl: '',
            contact: const MessageMember(
              id: 9,
              nickname: '聊天对象',
              avatarUrl: '',
            ),
            scrollController: scrollController,
            inputController: inputController,
            inputFocusNode: inputFocusNode,
            submitting: false,
            onLoadEarlier: _completeAction,
            onSelectImage: _completeAction,
            onSendText: (value) async => sentText = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '  插件消息  ');
    await tester.tap(find.byKey(const Key('message-chat-send-action')));
    await tester.pump();

    expect(sentText, '插件消息');
    expect(inputController.text, isEmpty);
  });
}

Future<void> _completeAction() async {}

Future<void> _completeSend(String value) async {}
