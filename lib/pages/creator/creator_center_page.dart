import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/creator_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/common/creator_access_policy.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_prompt_dialog.dart';
import 'package:b_flutter/models/creator_models.dart';
import 'package:b_flutter/pages/vip/vip_center_page.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/user_store.dart';

typedef CreatorDashboardLoader = Future<CreatorDashboard> Function(
    {bool forceRefresh});

class CreatorCenterPage extends StatefulWidget {
  const CreatorCenterPage({super.key, this.loader, this.onPublish});

  final CreatorDashboardLoader? loader;
  final VoidCallback? onPublish;

  @override
  State<CreatorCenterPage> createState() => _CreatorCenterPageState();
}

class _CreatorCenterPageState extends State<CreatorCenterPage> {
  CreatorDashboard? _dashboard;
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
      final loader = widget.loader ?? CreatorApi.getDashboard;
      final dashboard = await loader(forceRefresh: forceRefresh);
      if (mounted) setState(() => _dashboard = dashboard);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _publish() {
    final override = widget.onPublish;
    if (override != null) {
      override();
      return;
    }
    final store = Get.find<UserStore>();
    if (CreatorAccessPolicy.allowPublishingWithoutVip ||
        store.user.value?.isCreatorVip == true) {
      Get.toNamed<void>(AppRoutes.creatorWork);
      return;
    }
    Get.dialog<void>(
      LegacyMessageDialog(
        title: '提示',
        message: '您不是UP主会员？发帖需要成为UP主会员,是否立即升级成为发帖UP主会员？',
        cancelLabel: '取消',
        confirmLabel: '确认',
        onConfirm: () {
          Get.back<void>();
          Get.toNamed<void>(AppRoutes.vipCenter, arguments: VipType.creator);
        },
      ),
    );
  }

  void _openHistory(int initialIndex) =>
      Get.toNamed<void>(AppRoutes.creatorHistory, arguments: initialIndex);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '创作者中心'),
        body: _loading && _dashboard == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _dashboard == null
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
                      padding: const EdgeInsets.only(bottom: 20),
                      children: <Widget>[
                        _PublishButton(onTap: _publish),
                        const _CreationNotice(),
                        const _SectionTitle('我的作品'),
                        const SizedBox(height: 4),
                        _WorkSummary(
                          dashboard: _dashboard ??
                              const CreatorDashboard(
                                allCount: 0,
                                reviewingCount: 0,
                                collectionCount: 0,
                                incomes: <CreatorIncome>[],
                              ),
                          onTap: _openHistory,
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: Row(
                            children: <Widget>[
                              Text(
                                '最近收益',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Spacer(),
                              Text(
                                '展示最近7天的收益',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _IncomeTable(incomes: _dashboard?.incomes ?? const []),
                      ],
                    ),
                  ),
      );
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            key: const ValueKey<String>('creator_publish_button'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/images/ic_edit.svg',
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '发布作品',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _CreationNotice extends StatelessWidget {
  const _CreationNotice();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle('创作必看'),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Text(
              '严禁发布幼女、童女、人兽等血腥、恐怖镜头的图片或视频！',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12),
                children: <InlineSpan>[
                  TextSpan(
                    text: '违规严重的封号',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: '处理，请珍惜你的账号。',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );
}

class _WorkSummary extends StatelessWidget {
  const _WorkSummary({required this.dashboard, required this.onTap});

  final CreatorDashboard dashboard;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int)>[
      ('全部', dashboard.allCount),
      ('待审核', dashboard.reviewingCount),
      ('合计', dashboard.collectionCount),
    ];
    return Container(
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${items[index].$2}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index].$1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IncomeTable extends StatelessWidget {
  const _IncomeTable({required this.incomes});

  final List<CreatorIncome> incomes;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 40,
              child:
                  _IncomeRow(date: '日期', post: '帖子', gold: '收益', header: true),
            ),
            for (final income in incomes) ...<Widget>[
              const Divider(height: .5, thickness: .5),
              SizedBox(
                height: 40,
                child: _IncomeRow(
                  date: income.createdAt,
                  post: income.postTitle,
                  gold: income.formattedGold,
                ),
              ),
            ],
          ],
        ),
      );
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({
    required this.date,
    required this.post,
    required this.gold,
    this.header = false,
  });

  final String date;
  final String post;
  final String gold;
  final bool header;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(flex: 2, child: _cell(date, TextAlign.center)),
          Expanded(flex: 2, child: _cell(post, TextAlign.start)),
          Expanded(child: _cell(gold, TextAlign.center, goldCell: true)),
        ],
      );

  Widget _cell(String value, TextAlign align, {bool goldCell = false}) => Text(
        value,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: header || goldCell ? 14 : 10),
      );
}
