import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSocketMessage(ChatMessage message) {
    if (!mounted) return;
    final currentUserId = Get.find<UserStore>().user.value?.id ?? 0;
    final belongsToConversation =
        (message.fromId == widget.contact.id &&
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

  Future<void> _load() async {
    if (widget.contact.id <= 0) {
      setState(() {
        _loading = false;
        _error = const FormatException('Invalid message contact');
        _errorMessage = '用户信息无效，无法加载聊天记录';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _errorMessage = '加载失败，点击重试';
    });
    try {
      final messages = await MessageApi.getChatMessages(
        memberId: widget.contact.id,
      );
      if (mounted) setState(() => _messages = _mergeMessages(messages));
      _scrollToEnd();
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
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendText() {
    return _send(content: _inputController.text.trim(), type: 'text');
  }

  Future<void> _send({
    required String content,
    required String type,
    bool allowWhileUploadingImage = false,
  }) async {
    if (content.isEmpty ||
        _sending ||
        (_uploadingImage && !allowWhileUploadingImage)) {
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
      // ApiClient displays the legacy request failure toast.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
    appBar: LegacyAppBar(title: widget.contact.nickname),
    body: SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          Expanded(child: _buildMessages()),
          _ChatInput(
            controller: _inputController,
            submitting: _sending || _uploadingImage,
            onSelectImage: _selectAndSendImage,
            onSubmitted: _sendText,
          ),
        ],
      ),
    ),
  );

  Widget _buildMessages() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: () => unawaited(_load()),
          child: Text(_errorMessage),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          '暂无聊天记录',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }
    final currentUser = Get.find<UserStore>().user.value;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: _messages.length,
        itemBuilder: (context, index) => _ChatBubble(
          message: _messages[index],
          mine: _messages[index].isFrom(currentUser?.id ?? 0),
          contact: widget.contact,
          myAvatar: currentUser?.avatarUrl ?? '',
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.mine,
    required this.contact,
    required this.myAvatar,
  });
  final ChatMessage message;
  final bool mine;
  final MessageMember contact;
  final String myAvatar;
  @override
  Widget build(BuildContext context) {
    final avatar = mine ? myAvatar : contact.avatarUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!mine) _Avatar(url: avatar),
          if (!mine) const SizedBox(width: 8),
          Flexible(
            child: _MessageContent(message: message, mine: mine),
          ),
          if (mine) const SizedBox(width: 8),
          if (mine) _Avatar(url: avatar),
        ],
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    if (message.type == 'image') {
      return Container(
        width: 200,
        height: 200,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF54C2F3) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: LegacyNetworkImage(
          url: message.content,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: mine ? Colors.white : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 36,
    child: LegacyNetworkImage(
      url: url,
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.submitting,
    required this.onSelectImage,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final bool submitting;
  final Future<void> Function() onSelectImage;
  final Future<void> Function() onSubmitted;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      10,
      8,
      10,
      8 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider, width: .5)),
    ),
    child: Row(
      children: <Widget>[
        InkWell(
          onTap: submitting ? null : () => unawaited(onSelectImage()),
          child: SizedBox.square(
            dimension: 24,
            child: SvgPicture.asset('assets/images/v1/ic_picture_ph.svg'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => unawaited(onSubmitted()),
            decoration: InputDecoration(
              hintText: '发送消息',
              hintStyle: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 36,
          child: TextButton(
            onPressed: submitting ? null : () => unawaited(onSubmitted()),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(submitting ? '发送中' : '发送'),
          ),
        ),
      ],
    ),
  );
}
