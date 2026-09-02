import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:dash_chat_2/dash_chat_2.dart' as dash;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:b_flutter/api/active_api.dart';
import 'package:b_flutter/api/message_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/stores/message_socket_store.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/toast.dart';

class MessageChatPage extends StatefulWidget {
  const MessageChatPage({super.key, required this.contact});
  final MessageMember contact;
  @override
  State<MessageChatPage> createState() => _MessageChatPageState();
}

class _MessageChatPageState extends State<MessageChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription<ChatMessage>? _messageSubscription;
  List<ChatMessage> _messages = const <ChatMessage>[];
  Object? _error;
  String _errorMessage = '加载失败，点击重试';
  bool _loading = true;
  bool _sending = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MessageSocketStore>()) {
      final socketStore = Get.find<MessageSocketStore>();
      _messageSubscription = socketStore.messages.listen(_handleSocketMessage);
      socketStore.setActiveConversation(widget.contact.id);
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    if (Get.isRegistered<MessageSocketStore>()) {
      Get.find<MessageSocketStore>().clearActiveConversation(widget.contact.id);
    }
    unawaited(_messageSubscription?.cancel());
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSocketMessage(ChatMessage message) {
    if (!mounted) return;
    final currentUserId = Get.find<UserStore>().user.value?.id ?? 0;
    final belongsToConversation = (message.fromId == widget.contact.id &&
            message.toId == currentUserId) ||
        (message.fromId == currentUserId && message.toId == widget.contact.id);
    if (!belongsToConversation || _containsMessage(message)) return;
    setState(() => _messages = <ChatMessage>[..._messages, message]);
    _scrollToEnd();
  }

  bool _containsMessage(ChatMessage target) {
    return _messages.any((message) => _sameMessage(message, target));
  }

  List<ChatMessage> _mergeMessages(List<ChatMessage> loaded) {
    final merged = <ChatMessage>[...loaded];
    for (final message in _messages) {
      if (!merged.any((candidate) => _sameMessage(candidate, message))) {
        merged.add(message);
      }
    }
    return merged;
  }

  bool _sameMessage(ChatMessage message, ChatMessage target) {
    if (target.id > 0 && message.id > 0) return message.id == target.id;
    return message.fromId == target.fromId &&
        message.toId == target.toId &&
        message.type == target.type &&
        message.content == target.content &&
        message.createdAt == target.createdAt;
  }

  Future<void> _load({bool scrollToEnd = true}) async {
    if (widget.contact.id <= 0) {
      setState(() {
        _loading = false;
        _error = const FormatException('Invalid message contact');
        _errorMessage = '用户信息无效，无法加载聊天记录';
      });
      return;
    }
    final showInitialLoading = _messages.isEmpty;
    setState(() {
      _loading = showInitialLoading;
      _error = null;
      _errorMessage = '加载失败，点击重试';
    });
    try {
      final messages = await MessageApi.getChatMessages(
        memberId: widget.contact.id,
      );
      if (mounted) setState(() => _messages = _mergeMessages(messages));
      if (scrollToEnd) _scrollToEnd();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _errorMessage = '${error.message}，点击重试';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _errorMessage = '聊天记录加载失败，点击重试';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _send({
    required String content,
    required String type,
    bool allowWhileUploadingImage = false,
  }) async {
    if (content.isEmpty) {
      showToast('不能发送空白消息', type: ToastType.error);
      return;
    }
    if (_sending || (_uploadingImage && !allowWhileUploadingImage)) {
      if (type == 'text') _restoreMessageInput(content);
      return;
    }
    setState(() => _sending = true);
    try {
      final message = await MessageApi.sendMessage(
        memberId: widget.contact.id,
        content: content,
        type: type,
      );
      if (!mounted) return;
      setState(() {
        if (!_containsMessage(message)) {
          _messages = <ChatMessage>[..._messages, message];
        }
        _inputController.clear();
      });
      if (Get.isRegistered<MessageSocketStore>()) {
        final dispatch = Get.find<MessageSocketStore>().sendChatMessage(
          message,
        );
        if (dispatch == MessageSocketDispatch.unavailable) {
          showToast('消息已保存，但实时通讯暂不可用，对方刷新后可查看', type: ToastType.warning);
        } else if (dispatch == MessageSocketDispatch.queued) {
          showToast('消息已保存，正在等待实时连接恢复', type: ToastType.info);
        }
      }
      _scrollToEnd();
    } catch (_) {
      if (type == 'text') _restoreMessageInput(content);
      // ApiClient displays the legacy request failure toast.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _restoreMessageInput(String content) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _inputController.text.isNotEmpty) return;
      _inputController.value = TextEditingValue(
        text: content,
        selection: TextSelection.collapsed(offset: content.length),
      );
    });
  }

  Future<void> _selectAndSendImage() async {
    if (_sending || _uploadingImage) return;
    final source = await showModalActionSheet<String>(
      context: context,
      title: '选择',
      actions: const <SheetAction<String>>[
        SheetAction<String>(label: '照片', key: 'photo'),
        SheetAction<String>(label: '拍照', key: 'camera'),
        SheetAction<String>(label: '取消', key: 'cancel'),
      ],
    );
    if (source != 'photo' && source != 'camera') return;
    final file = await _imagePicker.pickImage(
      source: source == 'photo' ? ImageSource.gallery : ImageSource.camera,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final uploaded = await ActiveApi.uploadImage(
        filePath: file.path,
        fileName: file.name,
      );
      if (uploaded.url.isEmpty) {
        throw const FormatException('Empty chat image URL');
      }
      if (!mounted) return;
      await _send(
        content: uploaded.url,
        type: 'image',
        allowWhileUploadingImage: true,
      );
    } on ApiException catch (error) {
      showToast(error.message, type: ToastType.error);
    } catch (_) {
      showToast('图片上传失败，请稍后重试', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _chatPageBackground,
        appBar: LegacyAppBar(title: widget.contact.nickname),
        body: SafeArea(
          top: false,
          child: _buildChat(),
        ),
      );

  Widget _buildChat() {
    if (_loading) {
      return const ColoredBox(
        color: _chatPageBackground,
        child: Center(
          child: SizedBox.square(
            dimension: 30,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_error != null && _messages.isEmpty) {
      return ColoredBox(
        color: _chatPageBackground,
        child: Center(
          child: TextButton(
            onPressed: () => unawaited(_load()),
            child: Text(_errorMessage),
          ),
        ),
      );
    }
    final currentUser = Get.find<UserStore>().user.value;
    return MessageChatView(
      messages: _messages,
      currentUserId: currentUser?.id ?? 0,
      currentUserNickname: currentUser?.nickname ?? '',
      currentUserAvatarUrl: currentUser?.avatarUrl ?? '',
      contact: widget.contact,
      scrollController: _scrollController,
      inputController: _inputController,
      inputFocusNode: _inputFocusNode,
      submitting: _sending || _uploadingImage,
      onLoadEarlier: () => _load(scrollToEnd: false),
      onSelectImage: _selectAndSendImage,
      onSendText: (content) => _send(content: content, type: 'text'),
    );
  }
}

const Color _chatPageBackground = Color(0xFFF1F1F1);
const Color _myChatBubbleColor = Color(0xFF6A90FE);

class MessageChatView extends StatelessWidget {
  const MessageChatView({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.currentUserNickname,
    required this.currentUserAvatarUrl,
    required this.contact,
    required this.scrollController,
    required this.inputController,
    required this.inputFocusNode,
    required this.submitting,
    required this.onLoadEarlier,
    required this.onSelectImage,
    required this.onSendText,
  });

  final List<ChatMessage> messages;
  final int currentUserId;
  final String currentUserNickname;
  final String currentUserAvatarUrl;
  final MessageMember contact;
  final ScrollController scrollController;
  final TextEditingController inputController;
  final FocusNode inputFocusNode;
  final bool submitting;
  final Future<void> Function() onLoadEarlier;
  final Future<void> Function() onSelectImage;
  final Future<void> Function(String content) onSendText;

  @override
  Widget build(BuildContext context) {
    final currentUser = dash.ChatUser(
      id: currentUserId.toString(),
      firstName: currentUserNickname.isEmpty ? '我' : currentUserNickname,
      profileImage: currentUserAvatarUrl.isEmpty ? null : currentUserAvatarUrl,
    );
    final otherUser = dash.ChatUser(
      id: contact.id.toString(),
      firstName: contact.nickname.isEmpty ? '未知用户' : contact.nickname,
      profileImage: contact.avatarUrl.isEmpty ? null : contact.avatarUrl,
    );
    final chatMessages = messages.reversed
        .map((message) => _toDashMessage(message, currentUser, otherUser))
        .toList(growable: false);

    return ColoredBox(
      color: _chatPageBackground,
      child: Stack(
        children: <Widget>[
          dash.DashChat(
            key: const Key('message-chat-dash-chat'),
            currentUser: currentUser,
            messages: chatMessages,
            onSend: (message) => unawaited(onSendText(message.text.trim())),
            messageListOptions: dash.MessageListOptions(
              showDateSeparator: false,
              reverse: true,
              scrollController: scrollController,
              onLoadEarlier: onLoadEarlier,
              loadEarlierBuilder: const Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '正在加载历史消息...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              scrollPhysics: const BouncingScrollPhysics(),
            ),
            messageOptions: dash.MessageOptions(
              showCurrentUserAvatar: false,
              showOtherUsersAvatar: false,
              showOtherUsersName: false,
              showTime: false,
              containerColor: AppColors.surface,
              textColor: AppColors.textPrimary,
              currentUserContainerColor: _myChatBubbleColor,
              currentUserTextColor: Colors.white,
              borderRadius: 12,
              messagePadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              messageRowBuilder: (
                message,
                previousMessage,
                nextMessage,
                isAfterDateSeparator,
                isBeforeDateSeparator,
              ) =>
                  _DashMessageRow(
                message: message,
                currentUserId: currentUser.id,
              ),
            ),
            scrollToBottomOptions: dash.ScrollToBottomOptions(
              scrollToBottomBuilder: (controller) => Positioned(
                right: 10,
                bottom: 70,
                child: SizedBox.square(
                  dimension: 36,
                  child: RawMaterialButton(
                    key: const Key('message-chat-scroll-to-bottom'),
                    onPressed: () => controller.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    elevation: 4,
                    fillColor: AppColors.surface,
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            inputOptions: dash.InputOptions(
              textController: inputController,
              focusNode: inputFocusNode,
              inputDisabled: submitting,
              alwaysShowSend: true,
              sendOnEnter: true,
              textInputAction: TextInputAction.send,
              inputMaxLines: 5,
              inputToolbarStyle: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              inputDecoration: const InputDecoration(
                hintText: '请输入消息...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              inputTextStyle: const TextStyle(color: AppColors.textPrimary),
              trailing: <Widget>[
                GestureDetector(
                  key: const Key('message-chat-image-action'),
                  onTap: submitting ? null : () => unawaited(onSelectImage()),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      height: 36,
                      child: Icon(
                        Icons.image_outlined,
                        color: submitting
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
              showTraillingBeforeSend: true,
              sendButtonBuilder: (send) => SizedBox(
                height: 36,
                child: ElevatedButton(
                  key: const Key('message-chat-send-action'),
                  onPressed: submitting ? null : send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.textTertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(submitting ? '发送中' : '发送'),
                ),
              ),
            ),
          ),
          if (messages.isEmpty)
            const Positioned.fill(
              bottom: 68,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    '暂无聊天记录',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  dash.ChatMessage _toDashMessage(
    ChatMessage message,
    dash.ChatUser currentUser,
    dash.ChatUser otherUser,
  ) {
    final isImage = message.type == 'image';
    return dash.ChatMessage(
      text: isImage ? '' : message.content,
      user: message.isFrom(currentUserId) ? currentUser : otherUser,
      createdAt: _parseMessageTime(message.createdAt),
      medias: isImage
          ? <dash.ChatMedia>[
              dash.ChatMedia(
                url: message.content,
                fileName: 'image',
                type: dash.MediaType.image,
              ),
            ]
          : null,
      customProperties: <String, dynamic>{'legacyId': message.id},
    );
  }
}

class _DashMessageRow extends StatelessWidget {
  const _DashMessageRow({
    required this.message,
    required this.currentUserId,
  });

  final dash.ChatMessage message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final mine = message.user.id == currentUserId;
    final messageId = message.customProperties?['legacyId'] ?? 0;
    return Container(
      key: Key('message-chat-row-$messageId'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!mine) _DashAvatar(url: message.user.profileImage ?? ''),
          if (!mine) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.user.getFullName(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _DashMessageContent(message: message, mine: mine),
              ],
            ),
          ),
          if (mine) const SizedBox(width: 10),
          if (mine) _DashAvatar(url: message.user.profileImage ?? ''),
        ],
      ),
    );
  }
}

class _DashMessageContent extends StatelessWidget {
  const _DashMessageContent({required this.message, required this.mine});

  final dash.ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final messageId = message.customProperties?['legacyId'] ?? 0;
    if (message.medias?.isNotEmpty == true) {
      return Container(
        key: Key('message-chat-image-$messageId'),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: LegacyNetworkImage(
          url: message.medias!.first.url,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return Container(
      key: Key('message-chat-text-$messageId'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mine ? _myChatBubbleColor : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectionArea(
        child: Text(
          message.text,
          style: TextStyle(
            color: mine ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _DashAvatar extends StatelessWidget {
  const _DashAvatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('message-chat-avatar'),
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEAEAEA), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LegacyNetworkImage(
          url: url,
          borderRadius: BorderRadius.circular(10),
        ),
      );
}

DateTime _parseMessageTime(String value) {
  final normalized = value.trim().replaceAll('/', '-');
  final parsed = DateTime.tryParse(normalized);
  if (parsed != null) return parsed;
  final timestamp = int.tryParse(normalized);
  if (timestamp == null) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.fromMillisecondsSinceEpoch(
    normalized.length == 10 ? timestamp * 1000 : timestamp,
  );
}
