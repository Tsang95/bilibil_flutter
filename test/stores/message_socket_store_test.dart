import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/models/user_session.dart';
import 'package:b_flutter/stores/message_socket_store.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/stores/user_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserStore userStore;
  late _FakeMessageSocketConnection connection;
  late MessageSocketStore socketStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await TokenManager.instance.clear();
    userStore = UserStore();
    await userStore.activateSession(
      UserSession(
        token: 'test-token',
        user: UserInfo.fromJson(const <String, dynamic>{
          'id': 7,
          'nickname': '当前用户',
        }),
      ),
    );
    connection = _FakeMessageSocketConnection();
    socketStore = MessageSocketStore(
      userStore: userStore,
      socketUrl: 'wss://example.test/ws',
      connector: (_) => connection,
    );
    socketStore.onInit();
    await pumpEventQueue();
  });

  tearDown(() async {
    socketStore.onClose();
    await userStore.logout();
  });

  test('工程内置旧版即时通讯地址', () {
    expect(AppEnvironment.defaultWebSocketUrl, 'ws://chat.xbu75.com:9503');
  });

  test('收到 init 后绑定账号，并分发文本私信及同步未读数', () async {
    connection.receive(<String, Object?>{'type': 'init'});
    expect(connection.sentJson.single, <String, Object?>{
      'from_id': 7,
      'type': 'bind',
    });

    final received = socketStore.messages.first;
    connection.receive(<String, Object?>{
      'id': 31,
      'from_id': 9,
      'to_id': 7,
      'type': 'text',
      'content': '你好',
      'updated_at': '2026-08-25 10:00:00',
    });

    final message = await received;
    expect(message.id, 31);
    expect(message.content, '你好');
    expect(userStore.user.value?.likeMessageCount, 1);
  });

  test('当前会话不累计未读，并按旧协议发送 online 与落库消息', () async {
    socketStore.setActiveConversation(9);
    final dispatch = socketStore.sendChatMessage(
      const ChatMessage(
        id: 33,
        fromId: 7,
        toId: 9,
        content: '已发送',
        type: 'text',
        createdAt: '2026-08-25 10:01:00',
      ),
    );
    expect(dispatch, MessageSocketDispatch.queued);
    expect(connection.sentJson, isEmpty);

    connection.receive(<String, Object?>{'type': 'init'});
    expect(socketStore.status.value, MessageSocketStatus.bound);

    expect(connection.sentJson[0], <String, Object?>{
      'from_id': 7,
      'type': 'bind',
    });
    expect(connection.sentJson[1], <String, Object?>{
      'from_id': 7,
      'to_id': 9,
      'type': 'online',
    });
    final payload = connection.sentJson[2];
    expect(payload['id'], 33);
    expect(payload['data'], '已发送');
    expect(payload['type'], 'text');
    expect(payload['groupId'], md5.convert(utf8.encode('[7, 9]')).toString());

    connection.receive(<String, Object?>{
      'id': 32,
      'from_id': 9,
      'to_id': 7,
      'type': 'image',
      'data': '/uploads/chat.png',
    });
    expect(userStore.user.value?.likeMessageCount, 0);
  });

  test('传入空地址时明确标记不可用且不创建连接', () {
    var connectionCount = 0;
    final disabledStore = MessageSocketStore(
      userStore: userStore,
      socketUrl: '',
      connector: (_) {
        connectionCount++;
        return _FakeMessageSocketConnection();
      },
    );
    disabledStore.onInit();

    expect(disabledStore.status.value, MessageSocketStatus.disabled);
    expect(connectionCount, 0);
    expect(
      disabledStore.sendChatMessage(
        const ChatMessage(
          id: 40,
          fromId: 7,
          toId: 9,
          content: '不会静默丢失',
          type: 'text',
          createdAt: '',
        ),
      ),
      MessageSocketDispatch.unavailable,
    );
    disabledStore.onClose();
  });

  test('socket envelope 兼容 content/data 与时间字段', () {
    final envelope = MessageSocketEnvelope.fromJson(<String, dynamic>{
      'id': '12',
      'from_id': 4,
      'to_id': 8,
      'type': 'text',
      'content': 123,
      'created_at': '2026-08-25 09:00:00',
      'update_time': '99',
    });

    expect(envelope.isChatMessage, isTrue);
    expect(envelope.data, '123');
    expect(envelope.updatedTime, 99);
    expect(envelope.toChatMessage().createdAt, '2026-08-25 09:00:00');
  });
}

final class _FakeMessageSocketConnection implements MessageSocketConnection {
  final StreamController<Object?> _incoming =
      StreamController<Object?>.broadcast(sync: true);
  final List<String> sent = <String>[];

  List<Map<String, Object?>> get sentJson => sent
      .map(
        (value) => Map<String, Object?>.from(
          jsonDecode(value) as Map<dynamic, dynamic>,
        ),
      )
      .toList(growable: false);

  void receive(Map<String, Object?> message) {
    _incoming.add(jsonEncode(message));
  }

  @override
  Stream<Object?> get stream => _incoming.stream;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  void add(Object message) => sent.add(message.toString());

  @override
  Future<void> close() => _incoming.close();
}
