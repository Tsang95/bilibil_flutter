import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/pages/active/create_active_controller.dart';

class CreateActivePage extends StatefulWidget {
  const CreateActivePage({super.key});

  @override
  State<CreateActivePage> createState() => _CreateActivePageState();
}

class _CreateActivePageState extends State<CreateActivePage>
    with WidgetsBindingObserver {
  final CreateActiveController _controller = CreateActiveController();
  final GlobalKey _editorKey = GlobalKey();
  bool _keyboardWasVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _keyboardWasVisible = View.of(context).viewInsets.bottom > 0;
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final keyboardVisible = View.of(context).viewInsets.bottom > 0;
    final keyboardClosed = _keyboardWasVisible && !keyboardVisible;
    _keyboardWasVisible = keyboardVisible;
    if (keyboardClosed) unawaited(_controller.clearEditorFocus());
  }

  void _handlePointerDown(PointerDownEvent event) {
    final renderObject =
        _editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderObject == null || !renderObject.hasSize) return;
    final localPosition = renderObject.globalToLocal(event.position);
    final editorBounds = Offset.zero & renderObject.size;
    if (!editorBounds.contains(localPosition)) {
      unawaited(_controller.clearEditorFocus());
    }
  }

  Future<void> _publish() async {
    final success = await _controller.publish();
    if (success && mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        child: Scaffold(
          appBar: LegacyAppBar(
            title: '发布动态',
            trailing: SizedBox(
              width: 56,
              height: 32,
              child: InkWell(
                onTap: _controller.posting ? null : () => unawaited(_publish()),
                borderRadius: BorderRadius.circular(4),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.primary,
                  ),
                  child: const Center(
                    child: Text(
                      '发布',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: '封面图', style: TextStyle(fontSize: 14)),
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.coverItemCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: _buildCover,
                  ),
                  const SizedBox(height: 12),
                  _buildVideo(),
                  const SizedBox(height: 12),
                  const Text('发布您的想法', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _editorKey,
                    child: HtmlEditor(
                      controller: _controller.contentController,
                      htmlEditorOptions: const HtmlEditorOptions(
                        shouldEnsureVisible: true,
                      ),
                      otherOptions: const OtherOptions(height: 600),
                      htmlToolbarOptions: HtmlToolbarOptions(
                        defaultToolbarButtons: const <Toolbar>[
                          FontButtons(clearAll: false),
                          ColorButtons(),
                          ListButtons(listStyles: false),
                          ParagraphButtons(
                            textDirection: false,
                            lineHeight: false,
                            caseConverter: false,
                          ),
                        ],
                        customToolbarButtons: <Widget>[
                          IconButton(
                            onPressed: _controller.uploadingImage
                                ? null
                                : () => unawaited(
                                      _controller.addEditorImage(context),
                                    ),
                            icon: const Icon(Icons.image_outlined),
                          ),
                        ],
                        toolbarPosition: ToolbarPosition.aboveEditor,
                        toolbarType: ToolbarType.nativeScrollable,
                        mediaLinkInsertInterceptor: (url, attributes) async =>
                            true,
                        mediaUploadInterceptor: (file, attributes) async =>
                            true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context, int index) {
    if (index >= _controller.coverUrls.length) {
      return InkWell(
        onTap: _controller.uploadingImage
            ? null
            : () => unawaited(_controller.addCover(context)),
        borderRadius: BorderRadius.circular(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFFF7F7F7),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/ic_empty_pic.svg',
              width: 32,
              height: 32,
            ),
          ),
        ),
      );
    }
    final url = _controller.coverUrls[index];
    final localPath = _controller.localPath(url);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(File(localPath), fit: BoxFit.cover),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: InkWell(
            onTap: () => _controller.removeCoverAt(index),
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: const Icon(
                CupertinoIcons.multiply,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('视频', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: _controller.uploadingVideo
                  ? null
                  : () => unawaited(_controller.selectAndUploadVideo()),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 115,
                height: 115,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFFF7F7F7),
                ),
                child: SvgPicture.asset('assets/images/ic_empty_video.svg'),
              ),
            ),
            if (_controller.videoProgress > 0) ...<Widget>[
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          _controller.videoProgress >= 1 ? '上传完成' : '正在上传中...',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          '${(_controller.videoProgress * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: _controller.videoProgress,
                      minHeight: 10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      backgroundColor: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _controller.cancelVideoUpload,
                      child: const Text(
                        '取消上传',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}
