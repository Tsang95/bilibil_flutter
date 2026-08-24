import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/game_category.dart';
import 'package:b_flutter/routes/app_routes.dart';

class GameActivityPage extends StatefulWidget {
  const GameActivityPage({super.key});

  @override
  State<GameActivityPage> createState() => _GameActivityPageState();
}

class _GameActivityPageState extends State<GameActivityPage> {
  List<GameActivity> _items = const <GameActivity>[];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await GameApi.getActivities(forceRefresh: true);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const LegacyAppBar(title: '优惠活动'),
    body: _loading && _items.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _items.isEmpty
        ? Center(
            child: TextButton(
              onPressed: () => unawaited(_load()),
              child: const Text('加载失败，点击重试'),
            ),
          )
        : _items.isEmpty
        ? const Center(
            child: Text(
              '暂无活动',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _GameActivityCard(item: _items[index]),
            ),
          ),
  );
}

class _GameActivityCard extends StatelessWidget {
  const _GameActivityCard({required this.item});
  final GameActivity item;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.html.trim().isEmpty
        ? null
        : () => Get.toNamed<void>(AppRoutes.bannerHtml, arguments: item.html),
    borderRadius: BorderRadius.circular(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 140,
          width: double.infinity,
          child: LegacyNetworkImage(
            url: item.thumbnailUrl,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if (item.title.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '活动时间：${_date(item.startTime)} - ${_date(item.endTime)}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}

String _date(int epochSeconds) {
  if (epochSeconds <= 0) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
