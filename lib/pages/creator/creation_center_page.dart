import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/creator_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/creator_access_policy.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/models/creation_topic.dart';
import 'package:b_flutter/models/post_summary.dart';
import 'package:b_flutter/pages/vip/vip_center_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/user_store.dart';

typedef CreationTopicsLoader =
    Future<List<CreationTopicGroup>> Function({bool forceRefresh});
typedef CreationSchoolLoader =
    Future<List<PostSummary>> Function({bool forceRefresh});

class CreationCenterPage extends StatefulWidget {
  const CreationCenterPage({super.key, this.topicsLoader, this.schoolLoader});

  final CreationTopicsLoader? topicsLoader;
  final CreationSchoolLoader? schoolLoader;

  @override
  State<CreationCenterPage> createState() => _CreationCenterPageState();
}

class _CreationCenterPageState extends State<CreationCenterPage>
    with SingleTickerProviderStateMixin {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  TabController? _tabController;
  List<CreationTopicGroup> _groups = const <CreationTopicGroup>[];
  List<PostSummary> _schoolPosts = const <PostSummary>[];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final topicsLoader = widget.topicsLoader ?? CreatorApi.getCreationTopics;
      final schoolLoader =
          widget.schoolLoader ?? CreatorApi.getCreationSchoolPosts;
      final results = await Future.wait<Object>(<Future<Object>>[
        topicsLoader(forceRefresh: forceRefresh).then<Object>((value) => value),
        schoolLoader(forceRefresh: forceRefresh).then<Object>((value) => value),
      ]);
      if (!mounted) return;
      final groups = results[0] as List<CreationTopicGroup>;
      final schoolPosts = results[1] as List<PostSummary>;
      final previousTabs = _tabController;
      final nextTabs = previousTabs?.length == groups.length
          ? previousTabs
          : groups.isEmpty
          ? null
          : TabController(length: groups.length, vsync: this);
      setState(() {
        _tabController = nextTabs;
        _groups = groups;
        _schoolPosts = schoolPosts;
      });
      if (previousTabs != null && !identical(previousTabs, nextTabs)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          previousTabs.dispose();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submitToTopic(CreationTopic topic) {
    final user = Get.find<UserStore>().user.value;
    if (CreatorAccessPolicy.allowPublishingWithoutVip ||
        user?.isCreatorVip == true) {
      Get.toNamed<void>(AppRoutes.creatorWork, arguments: topic.id);
      return;
    }
    Get.dialog<void>(
      LegacyMessageDialog(
        title: '提示',
        message: '您不是UP主会员？发帖需要成为UP主会员,是否立即升级成为发帖UP主会员？',
        cancelLabel: '取消',
        confirmLabel: '确认',
        onCancel: Get.back,
        onConfirm: () {
          Get.back<void>();
          Get.toNamed<void>(AppRoutes.vipCenter, arguments: VipType.creator);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surfaceMuted,
    appBar: const LegacyAppBar(title: '创作中心'),
    body: _loading && _groups.isEmpty && _schoolPosts.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _groups.isEmpty && _schoolPosts.isEmpty
        ? Center(
            child: TextButton(
              onPressed: () => _load(forceRefresh: true),
              child: const Text('加载失败，点击重试'),
            ),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _load(forceRefresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: <Widget>[
                _InspirationSection(
                  groups: _groups,
                  tabController: _tabController,
                  carouselController: _carouselController,
                  onSubmit: _submitToTopic,
                ),
                _SchoolSection(posts: _schoolPosts),
              ],
            ),
          ),
  );
}

class _InspirationSection extends StatelessWidget {
  const _InspirationSection({
    required this.groups,
    required this.tabController,
    required this.carouselController,
    required this.onSubmit,
  });

  final List<CreationTopicGroup> groups;
  final TabController? tabController;
  final CarouselSliderController carouselController;
  final ValueChanged<CreationTopic> onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '创作灵感',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                '暂无创作灵感',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else ...<Widget>[
          SizedBox(
            height: 24,
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(1),
              indicator: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textPrimary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              onTap: carouselController.animateToPage,
              tabs: groups.map((group) => Tab(text: group.name)).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CarouselSlider.builder(
              carouselController: carouselController,
              itemCount: groups.length,
              itemBuilder: (context, index, _) =>
                  _TopicGroupCard(group: groups[index], onSubmit: onSubmit),
              options: CarouselOptions(
                viewportFraction: 1,
                enableInfiniteScroll: groups.length > 1,
                onPageChanged: (index, _) {
                  final tabs = tabController;
                  if (tabs != null && tabs.index != index) tabs.index = index;
                },
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _TopicGroupCard extends StatelessWidget {
  const _TopicGroupCard({required this.group, required this.onSubmit});

  final CreationTopicGroup group;
  final ValueChanged<CreationTopic> onSubmit;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
    ),
    child: group.topics.isEmpty
        ? const Center(
            child: Text(
              '暂无话题',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            itemCount: group.topics.length,
            itemBuilder: (context, index) => _TopicRow(
              topic: group.topics[index],
              onSubmit: () => onSubmit(group.topics[index]),
            ),
          ),
  );
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, required this.onSubmit});

  final CreationTopic topic;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                topic.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/images/v1/ic_fire.svg',
                    width: 10,
                    height: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${topic.viewCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onSubmit,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              '投稿',
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SchoolSection extends StatelessWidget {
  const _SchoolSection({required this.posts});

  final List<PostSummary> posts;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '创作学院',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: posts.isEmpty
              ? const Center(
                  child: Text(
                    '暂无学院内容',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: posts.length,
                  itemBuilder: (context, index) =>
                      _SchoolPostCard(post: posts[index]),
                ),
        ),
      ],
    ),
  );
}

class _SchoolPostCard extends StatelessWidget {
  const _SchoolPostCard({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: post.id <= 0
        ? null
        : () => Get.toNamed<void>(AppRoutes.postDetailPath(post.id)),
    borderRadius: BorderRadius.circular(5),
    child: SizedBox(
      width: 130,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 90,
              child: LegacyNetworkImage(
                url: post.preferredCoverUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
