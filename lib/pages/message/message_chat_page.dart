import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/message_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/message_models.dart';
import 'package:b_flutter/stores/user_store.dart';

class MessageChatPage extends StatefulWidget {
  const MessageChatPage({super.key, required this.contact});
  final MessageMember contact;
  @override
  State<MessageChatPage> createState() => _MessageChatPageState();
}

class _MessageChatPageState extends State<MessageChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = const <ChatMessage>[];
  Object? _error;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await MessageApi.getChatMessages(
        memberId: widget.contact.id,
      );
      if (mounted) setState(() => _messages = messages);
      _scrollToEnd();
    } catch (error) {
      if (mounted) setState(() => _error = error);
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

  Future<void> _send() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final message = await MessageApi.sendMessage(
        memberId: widget.contact.id,
        content: content,
      );
      if (!mounted) return;
      setState(() {
        _messages = <ChatMessage>[..._messages, message];
        _inputController.clear();
      });
      _scrollToEnd();
    } catch (_) {
      // ApiClient displays the legacy request failure toast.
    } finally {
      if (mounted) setState(() => _sending = false);
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
            submitting: _sending,
            onSubmitted: _send,
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
          child: const Text('加载失败，点击重试'),
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
    final text = message.type == 'image' ? '[图片]' : message.content;
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: mine ? AppColors.primary : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (mine) const SizedBox(width: 8),
          if (mine) _Avatar(url: avatar),
        ],
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
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final bool submitting;
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
