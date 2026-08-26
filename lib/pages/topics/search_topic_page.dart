import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/topic_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/topic_summary.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/legacy_display_format.dart';

class SearchTopicPage extends StatefulWidget {
  const SearchTopicPage({super.key});

  @override
  State<SearchTopicPage> createState() => _SearchTopicPageState();
}

class _SearchTopicPageState extends State<SearchTopicPage> {
  final TextEditingController _inputController = TextEditingController();
  List<TopicSummary> _topics = const <TopicSummary>[];
  bool _loading = true;
  String _keyword = '';
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _keyword = _inputController.text;
    });
    try {
      final topics = await TopicApi.searchTopics(
        keyword: _inputController.text,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _topics = topics;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LegacyAppBar(title: '话题中心'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 10),
                    SvgPicture.asset(
                      'assets/images/ic_search.svg',
                      width: 14,
                      height: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(fontSize: 14),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => unawaited(_load()),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '查找相关话题',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
          if (_keyword.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10, left: 10),
              child: Text(
                '热门话题',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _topics.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _topics.isEmpty) {
      return Center(
        child: TextButton(onPressed: _load, child: const Text('加载失败，点击重试')),
      );
    }
    if (_topics.isEmpty) {
      return const Center(
        child: Text(
          '暂无相关话题',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(forceRefresh: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _topics.length,
        itemBuilder: (context, index) => _TopicSearchItem(
          topic: _topics[index],
          onTap: () =>
              Get.toNamed<void>(AppRoutes.topicList, arguments: _topics[index]),
        ),
      ),
    );
  }
}

class _TopicSearchItem extends StatelessWidget {
  const _TopicSearchItem({required this.topic, required this.onTap});

  final TopicSummary topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 10),
              child: SvgPicture.asset(
                'assets/images/ic_hot_huati.svg',
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 9),
                  Text(
                    topic.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${formatLegacyRelativeTime(topic.lastParticipatedAt)}有人参与 • ${formatLegacyCompactCount(topic.commentCount)}+讨论',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  const Divider(height: 0.5),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
