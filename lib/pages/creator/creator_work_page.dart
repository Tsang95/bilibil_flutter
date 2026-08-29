import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/creator_publish_models.dart';
import 'package:b_flutter/pages/creator/creator_work_controller.dart';
import 'package:b_flutter/routes/app_routes.dart';

Future<int?> showCreatorOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> labels,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '请选择$title',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Divider(height: .5, thickness: .5),
            Flexible(
              child: ListView.separated(
                key: const ValueKey<String>('creator_option_sheet_list'),
                padding: EdgeInsets.zero,
                itemCount: labels.length,
                separatorBuilder: (context, index) => const Divider(
                  height: .5,
                  thickness: .5,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) => InkWell(
                  onTap: () => Navigator.of(context).pop(index),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CreatorWorkPage extends StatefulWidget {
  const CreatorWorkPage({super.key, this.initialTopicId});

  final int? initialTopicId;

  @override
  State<CreatorWorkPage> createState() => _CreatorWorkPageState();
}

class _CreatorWorkPageState extends State<CreatorWorkPage> {
  late final CreatorWorkController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreatorWorkController(initialTopicId: widget.initialTopicId);
    unawaited(_controller.load());
  }

  Future<void> _publish() async {
    final success = await _controller.publish();
    if (!success || !mounted) return;
    Get.offNamed<void>(AppRoutes.creatorHistory);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Scaffold(
          appBar: LegacyAppBar(
            title: '发布视频',
            trailing: SizedBox(
              width: 60,
              height: 28,
              child: InkWell(
                key: const ValueKey<String>('creator_work_publish'),
                onTap:
                    _controller.publishing ? null : () => unawaited(_publish()),
                borderRadius: BorderRadius.circular(4),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _controller.publishing ? '发布中' : '发布',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _controller.loading
              ? const Center(child: CircularProgressIndicator())
              : _controller.error != null
                  ? Center(
                      child: TextButton(
                        onPressed: () => _controller.load(forceRefresh: true),
                        child: const Text('加载失败，点击重试'),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _CreatorSelectRow<CreatorPlate>(
                            requiredField: true,
                            name: '板块',
                            placeholder: '板块名称',
                            items: _controller.options?.plates ??
                                const <CreatorPlate>[],
                            selected: _controller.selectedPlate,
                            label: (item) => item.name,
                            onSelected: _controller.selectPlate,
                          ),
                          _CreatorSelectRow<CreatorPublishOption>(
                            requiredField: true,
                            name: '分类',
                            placeholder: '分类名称',
                            items: _controller.selectedPlate?.categories ??
                                const <CreatorPublishOption>[],
                            selected: _controller.selectedCategory,
                            label: (item) => item.name,
                            onSelected: _controller.selectCategory,
                          ),
                          _CreatorSelectRow<CreatorPublishOption>(
                            requiredField: true,
                            name: '帖子类型',
                            placeholder: '类型名称',
                            items: _controller.options?.contentTypes ??
                                const <CreatorPublishOption>[],
                            selected: _controller.selectedContentType,
                            label: (item) => item.name,
                            onSelected: _controller.selectContentType,
                          ),
                          _CreatorSelectRow<CreatorPublishOption>(
                            name: '话题',
                            placeholder: '选择话题',
                            items: _controller.topics,
                            selected: _controller.selectedTopic,
                            label: (item) => item.name,
                            onSelected: _controller.selectTopic,
                          ),
                          _CreatorSelectRow<CreatorPublishOption>(
                            name: '合集类型',
                            placeholder: '选择类型',
                            items: _controller.options?.collectionTypes ??
                                const <CreatorPublishOption>[],
                            selected: _controller.selectedCollectionType,
                            label: (item) => item.name,
                            onSelected: _controller.selectCollectionType,
                          ),
                          if (_controller.showCollection)
                            _CreatorSelectRow<CreatorPublishOption>(
                              name: '合集',
                              placeholder: '选择合集（非必选）',
                              items: _controller.collections,
                              selected: _controller.selectedCollection,
                              label: (item) => item.name,
                              onSelected: _controller.selectCollection,
                            ),
                          if (_controller.showPaidOptions)
                            _CreatorSelectRow<CreatorPriceOption>(
                              name: '金额',
                              placeholder: '选择金额',
                              items: _controller.options?.prices ??
                                  const <CreatorPriceOption>[],
                              selected: _controller.selectedPrice,
                              label: (item) => item.label,
                              onSelected: _controller.selectPrice,
                            ),
                          if (_controller.showPaidOptions) ...<Widget>[
                            _CreatorRadioRow(
                              name: '是否VIP可看',
                              value: _controller.vipWatch,
                              onChanged: _controller.setVipWatch,
                            ),
                            _CreatorRadioRow(
                              name: '仅限VIP可评论',
                              value: _controller.vipComment,
                              onChanged: _controller.setVipComment,
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(fontSize: 14),
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                  TextSpan(text: '标题'),
                                  TextSpan(
                                    text: ' （标题内容长度8-36个字）',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                            child: TextField(
                              controller: _controller.titleController,
                              maxLines: 1,
                              maxLength: 36,
                              decoration: _inputDecoration('请输入标题'),
                            ),
                          ),
                          _ImageSection(
                            title: '封面图',
                            requiredField: true,
                            urls: _controller.coverUrls,
                            maxCount: 3,
                            localPath: _controller.localPath,
                            onAdd: () => _controller.addImage(
                                context, CreatorImageTarget.cover),
                            onRemove: (index) => _controller.removeImage(
                              CreatorImageTarget.cover,
                              index,
                            ),
                          ),
                          if (_controller.showHorizontalCover)
                            _ImageSection(
                              title: '横封面图',
                              requiredField: true,
                              urls: _controller.horizontalCoverUrls,
                              maxCount: 1,
                              localPath: _controller.localPath,
                              onAdd: () => _controller.addImage(
                                context,
                                CreatorImageTarget.horizontalCover,
                              ),
                              onRemove: (index) => _controller.removeImage(
                                CreatorImageTarget.horizontalCover,
                                index,
                              ),
                            ),
                          if (_controller.showComicImages)
                            _ImageSection(
                              title: '图片列表',
                              suffix: ' （最多30张）',
                              urls: _controller.comicUrls,
                              maxCount: 30,
                              localPath: _controller.localPath,
                              onAdd: () => _controller.addImage(
                                context,
                                CreatorImageTarget.comic,
                              ),
                              onRemove: (index) => _controller.removeImage(
                                CreatorImageTarget.comic,
                                index,
                              ),
                            ),
                          if (_controller.showMediaUpload)
                            _MediaUpload(controller: _controller),
                          _HtmlSection(
                            title: '介绍',
                            suffix: ' （可上传图片）',
                            controller: _controller.descriptionController,
                            onAddImage: () => _controller.addImage(
                              context,
                              CreatorImageTarget.description,
                            ),
                            bottomPadding: 280,
                          ),
                          if (_controller.showContentEditor)
                            _HtmlSection(
                              title: '富文本',
                              suffix: '（付费贴付费后才展示）',
                              controller: _controller.contentController,
                              onAddImage: () => _controller.addImage(
                                context,
                                CreatorImageTarget.content,
                              ),
                              bottomPadding: 280,
                            ),
                        ],
                      ),
                    ),
        ),
      );
}

InputDecoration _inputDecoration(String hint) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: AppColors.divider),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
    counterText: '',
    filled: false,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
  );
}

class _CreatorSelectRow<T> extends StatelessWidget {
  const _CreatorSelectRow({
    this.requiredField = false,
    required this.name,
    required this.placeholder,
    required this.items,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final bool requiredField;
  final String name;
  final String placeholder;
  final List<T> items;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  Future<void> _show(BuildContext context) async {
    if (items.isEmpty) return;
    final result = await showCreatorOptionSheet(
      context,
      title: name,
      labels: items.map(label).toList(growable: false),
    );
    if (result != null) onSelected(items[result]);
  }

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => unawaited(_show(context)),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 105,
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 14),
                          children: <InlineSpan>[
                            if (requiredField)
                              const TextSpan(
                                text: '*',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            TextSpan(text: name),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        selected == null ? placeholder : label(selected as T),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: .5, thickness: .5, indent: 10, endIndent: 10),
          ],
        ),
      );
}

class _CreatorRadioRow extends StatelessWidget {
  const _CreatorRadioRow({
    required this.name,
    required this.value,
    required this.onChanged,
  });

  final String name;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: Row(
          children: <Widget>[
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Radio<int>(
                  value: 1,
                  groupValue: value,
                  onChanged: (next) {
                    if (next != null) onChanged(next);
                  },
                  activeColor: AppColors.primary,
                ),
                const Text('是', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 10),
                Radio<int>(
                  value: 0,
                  groupValue: value,
                  onChanged: (next) {
                    if (next != null) onChanged(next);
                  },
                  activeColor: AppColors.primary,
                ),
                const Text('否', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
      );
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.title,
    this.suffix = '',
    this.requiredField = false,
    required this.urls,
    required this.maxCount,
    required this.localPath,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String suffix;
  final bool requiredField;
  final List<String> urls;
  final int maxCount;
  final String Function(String) localPath;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final count = urls.length < maxCount ? urls.length + 1 : maxCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14),
              children: <InlineSpan>[
                if (requiredField)
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                TextSpan(text: title),
                TextSpan(
                  text: suffix,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = (constraints.maxWidth - 10) / 3;
              return Wrap(
                spacing: 5,
                runSpacing: 5,
                children: <Widget>[
                  for (var index = 0; index < count; index++)
                    SizedBox(
                      width: size,
                      height: size,
                      child: index < urls.length
                          ? _SelectedImage(
                              path: localPath(urls[index]),
                              onRemove: () => onRemove(index),
                            )
                          : _AddImage(onTap: onAdd),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SelectedImage extends StatelessWidget {
  const _SelectedImage({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: InkWell(
              onTap: onRemove,
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

class _AddImage extends StatelessWidget {
  const _AddImage({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(4),
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

class _MediaUpload extends StatelessWidget {
  const _MediaUpload({required this.controller});

  final CreatorWorkController controller;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(controller.contentType == 4 ? '音频' : '视频'),
            const SizedBox(height: 5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                InkWell(
                  onTap: controller.uploadingVideo
                      ? null
                      : () => unawaited(controller.selectAndUploadMedia()),
                  child: Container(
                    width: 115,
                    height: 115,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SvgPicture.asset('assets/images/ic_empty_video.svg'),
                  ),
                ),
                if (controller.videoProgress > 0) ...<Widget>[
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              controller.videoProgress >= 1
                                  ? '上传完成'
                                  : '正在上传中...',
                            ),
                            const Spacer(),
                            Text(
                              '${(controller.videoProgress * 100).toStringAsFixed(2)}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: controller.videoProgress,
                          minHeight: 10,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                          backgroundColor: const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: controller.cancelMediaUpload,
                          child: const Text(
                            '取消上传',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
}

class _HtmlSection extends StatelessWidget {
  const _HtmlSection({
    required this.title,
    required this.suffix,
    required this.controller,
    required this.onAddImage,
    this.bottomPadding = 0,
  });

  final String title;
  final String suffix;
  final HtmlEditorController controller;
  final VoidCallback onAddImage;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(10, 20, 10, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(text: title, style: const TextStyle(fontSize: 14)),
                  TextSpan(
                    text: suffix,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            HtmlEditor(
              controller: controller,
              htmlEditorOptions:
                  const HtmlEditorOptions(shouldEnsureVisible: true),
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
                    onPressed: onAddImage,
                    icon: const Icon(Icons.image_outlined),
                  ),
                ],
                toolbarPosition: ToolbarPosition.aboveEditor,
                toolbarType: ToolbarType.nativeScrollable,
                mediaLinkInsertInterceptor: (url, attributes) async => true,
                mediaUploadInterceptor: (file, attributes) async => true,
              ),
            ),
          ],
        ),
      );
}
