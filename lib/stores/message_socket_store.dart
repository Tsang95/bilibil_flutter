import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/logger_util.dart';

abstract interface class MessageSocketConnection {
  Stream<Object?> get stream;
  Future<void> get ready;
  void add(Object message);
  Future<void> close();
}

typedef MessageSocketConnector = MessageSocketConnection Function(Uri uri);

enum MessageSocketStatus {
  disabled,
  disconnected,
  connecting,
  connected,
  bound,
}

enum MessageSocketDispatch { sent, queued, unavailable }

final class _WebSocketMessageSocketConnection
    implements MessageSocketConnection {
  _WebSocketMessageSocketConnection(Uri uri)
      : _channel = WebSocketChannel.connect(uri);

  final WebSocketChannel _channel;

  @override
  Stream<Object?> get stream => _channel.stream;

  @override
  Future<void> get ready => _channel.ready;

  @override
  void add(Object message) => _channel.sink.add(message);

  @override
  Future<void> close() => _channel.sink.close();
}

final class MessageSocketStore extends GetxService {
  MessageSocketStore({
    UserStore? userStore,
    String? socketUrl,
    MessageSocketConnector? connector,
  })  : _providedUserStore = userStore,
        _socketUrl = socketUrl ?? AppEnvironment.webSocketUrl,
        _connector = connector ?? _WebSocketMessageSocketConnection.new;

  static const Duration heartbeatInterval = Duration(seconds: 20);
  static const Duration reconnectDelay = Duration(seconds: 2);

  final UserStore? _providedUserStore;
  final String _socketUrl;
  final MessageSocketConnector _connector;
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast(sync: true);
  final List<Map<String, Object?>> _pendingPayloads = <Map<String, Object?>>[];

  late final UserStore _userStore;
  final status = MessageSocketStatus.disconnected.obs;
  Worker? _userWorker;
  MessageSocketConnection? _connection;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _connectionVersion = 0;
  int? _activePeerId;
  bool _connecting = false;
  bool _connectionReady = false;
  bool _bound = false;
  bool _closed = false;

  Stream<ChatMessage> get messages => _messageController.stream;
  bool get isConfigured {
    final uri = Uri.tryParse(_socketUrl.trim());
    return uri != null && (uri.scheme == 'ws' || uri.scheme == 'wss');
  }

  @override
  void onInit() {
    super.onInit();
    _userStore = _providedUserStore ?? Get.find<UserStore>();
    _userWorker = ever<UserInfo?>(_userStore.user, (_) => _syncSession());
    if (!isConfigured) {
      status.value = MessageSocketStatus.disabled;
      logger.w('私信实时连接地址无效，请检查工程默认地址或 WS_URL 覆盖值');
    }
    _syncSession();
  }

  void setActiveConversation(int memberId) {
    _activePeerId = memberId;
    sendOnline(memberId);
  }

  void clearActiveConversation(int memberId) {
    if (_activePeerId == memberId) _activePeerId = null;
  }

  void sendOnline(int memberId) {
    final currentUserId = _userStore.user.value?.id ?? 0;
    if (currentUserId <= 0 || memberId <= 0) return;
    _dispatch(_onlinePayload(memberId));
  }

  MessageSocketDispatch sendChatMessage(ChatMessage message) {
    final currentUserId = _userStore.user.value?.id ?? 0;
    if (currentUserId <= 0 || message.toId <= 0) {
      return MessageSocketDispatch.unavailable;
    }
    final envelope = MessageSocketEnvelope.fromChatMessage(message);
    final peerId =
        message.fromId == currentUserId ? message.toId : message.fromId;
    return _dispatch(envelope.toJson(groupId: _groupId(currentUserId, peerId)));
  }

  void _syncSession() {
    if (_closed) return;
    if (_userStore.isLoggedIn) {
      unawaited(_connect());
    } else {
      _activePeerId = null;
      _disconnect(clearPending: true);
    }
  }

  Future<void> _connect() async {
    if (_closed ||
        !_userStore.isLoggedIn ||
        _connecting ||
        _connection != null) {
      return;
    }
    final uri = Uri.tryParse(_socketUrl.trim());
    if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
      status.value = MessageSocketStatus.disabled;
      return;
    }

    _connecting = true;
    _connectionReady = false;
    _bound = false;
    status.value = MessageSocketStatus.connecting;
    _reconnectTimer?.cancel();
    final version = ++_connectionVersion;
    MessageSocketConnection? connection;
    try {
      connection = _connector(uri);
      if (_closed || version != _connectionVersion) {
        unawaited(connection.close());
        return;
      }
      _connection = connection;
      connection.stream.listen(
        (message) {
          if (_closed ||
              version != _connectionVersion ||
              !identical(_connection, connection)) {
            return;
          }
          _handleRawMessage(message);
        },
        onDone: () => _handleConnectionEnd(version, connection!),
        onError: (Object error, StackTrace stackTrace) {
          if (_connectionReady) {
            logger.w('私信实时连接异常', error: error, stackTrace: stackTrace);
          }
          _handleConnectionEnd(version, connection!);
        },
      );
      await connection.ready;
      if (_closed ||
          version != _connectionVersion ||
          !identical(_connection, connection)) {
        return;
      }
      _connectionReady = true;
      if (!_bound) status.value = MessageSocketStatus.connected;
      _startHeartbeat();
    } catch (error, stackTrace) {
      if (version == _connectionVersion && !_closed) {
        logger.w('私信实时连接失败', error: error, stackTrace: stackTrace);
        if (connection != null) unawaited(connection.close());
        _connection = null;
        _connectionReady = false;
        _bound = false;
        status.value = MessageSocketStatus.disconnected;
        _scheduleReconnect();
      }
    } finally {
      if (version == _connectionVersion) _connecting = false;
    }
  }

  void _handleRawMessage(Object? rawMessage) {
    try {
      final text = switch (rawMessage) {
        String value => value,
        List<int> value => utf8.decode(value),
        _ => '',
      };
      if (text.isEmpty) return;
      final decoded = jsonDecode(text);
      if (decoded is! Map) return;
      final envelope = MessageSocketEnvelope.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (envelope.type == 'init') {
        _connectionReady = true;
        if (!_sendImmediately(_controlPayload('bind'))) return;
        _bound = true;
        status.value = MessageSocketStatus.bound;
        final activePeerId = _activePeerId;
        if (activePeerId != null) {
          _enqueue(_onlinePayload(activePeerId));
        }
        _flushPending();
        return;
      }
      if (!envelope.isChatMessage) return;
      final message = envelope.toChatMessage();
      final currentUserId = _userStore.user.value?.id ?? 0;
      if (message.toId == currentUserId &&
          message.fromId != currentUserId &&
          message.fromId != _activePeerId) {
        _userStore.incrementPrivateMessageCount();
      }
      if (!_messageController.isClosed) _messageController.add(message);
    } catch (error, stackTrace) {
      logger.w('忽略无法解析的私信实时消息', error: error, stackTrace: stackTrace);
    }
  }

  Map<String, Object?> _controlPayload(String type) {
    final currentUserId = _userStore.user.value?.id ?? 0;
    return <String, Object?>{'from_id': currentUserId, 'type': type};
  }

  Map<String, Object?> _onlinePayload(int memberId) {
    final currentUserId = _userStore.user.value?.id ?? 0;
    return <String, Object?>{
      'from_id': currentUserId,
      'to_id': memberId,
      'type': 'online',
    };
  }

  MessageSocketDispatch _dispatch(Map<String, Object?> payload) {
    if (_closed || !_userStore.isLoggedIn || !isConfigured) {
      return MessageSocketDispatch.unavailable;
    }
    if (_connectionReady && _bound && _sendImmediately(payload)) {
      return MessageSocketDispatch.sent;
    }
    _enqueue(payload);
    unawaited(_connect());
    return MessageSocketDispatch.queued;
  }

  void _enqueue(Map<String, Object?> payload) {
    if (payload['type'] == 'online') {
      _pendingPayloads.removeWhere((item) => item['type'] == 'online');
      if (_pendingPayloads.length >= 100) _pendingPayloads.removeLast();
      _pendingPayloads.insert(0, Map<String, Object?>.from(payload));
      return;
    }
    if (_pendingPayloads.length >= 100) _pendingPayloads.removeAt(0);
    _pendingPayloads.add(Map<String, Object?>.from(payload));
  }

  void _flushPending() {
    while (_connectionReady && _bound && _pendingPayloads.isNotEmpty) {
      if (!_sendImmediately(_pendingPayloads.first)) return;
      _pendingPayloads.removeAt(0);
    }
  }

  bool _sendImmediately(Map<String, Object?> payload) {
    final connection = _connection;
    if (connection == null || !_connectionReady) return false;
    try {
      connection.add(jsonEncode(payload));
      return true;
    } catch (error, stackTrace) {
      logger.w('私信实时消息发送失败', error: error, stackTrace: stackTrace);
      _handleConnectionEnd(_connectionVersion, connection);
      return false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      heartbeatInterval,
      (_) => _sendImmediately(_controlPayload('heart')),
    );
  }

  void _handleConnectionEnd(int version, MessageSocketConnection connection) {
    if (_closed || version != _connectionVersion) return;
    if (identical(_connection, connection)) {
      _connection = null;
      unawaited(connection.close());
    }
    _connectionReady = false;
    _bound = false;
    status.value = MessageSocketStatus.disconnected;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _connecting = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed ||
        !_userStore.isLoggedIn ||
        _reconnectTimer?.isActive == true) {
      return;
    }
    _reconnectTimer = Timer(reconnectDelay, () => unawaited(_connect()));
  }

  void _disconnect({bool clearPending = false}) {
    _connectionVersion += 1;
    _connecting = false;
    _connectionReady = false;
    _bound = false;
    if (clearPending) _pendingPayloads.clear();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final connection = _connection;
    _connection = null;
    if (connection != null) unawaited(connection.close());
    status.value = isConfigured
        ? MessageSocketStatus.disconnected
        : MessageSocketStatus.disabled;
  }

  String _groupId(int currentUserId, int peerId) {
    final characters = '$peerId$currentUserId'.split('')..sort();
    return md5.convert(utf8.encode(characters.toString())).toString();
  }

  @override
  void onClose() {
    _closed = true;
    _userWorker?.dispose();
    _disconnect(clearPending: true);
    unawaited(_messageController.close());
    super.onClose();
  }
}
