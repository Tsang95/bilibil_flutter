import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/game_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/game_category.dart';

class GameRechargeRecordPage extends StatefulWidget {
  const GameRechargeRecordPage({super.key});
  @override
  State<GameRechargeRecordPage> createState() => _GameRechargeRecordPageState();
}

class _GameRechargeRecordPageState extends State<GameRechargeRecordPage> {
  final _controller = ScrollController();
  final _records = <GameRechargeRecord>[];
  Object? _error;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.extentAfter < 240) unawaited(_loadMore());
    });
    unawaited(_reload());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _hasMore = true;
    await _loadMore(reload: true);
  }

  Future<void> _loadMore({bool reload = false}) async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await GameApi.getRechargeRecords(
        lastId: reload || _records.isEmpty ? 0 : _records.last.id,
      );
      if (!mounted) return;
      setState(() {
        if (reload) _records.clear();
        final ids = _records.map((item) => item.id).toSet();
        _records.addAll(next.where((item) => ids.add(item.id)));
        _hasMore = next.length >= 20;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '充值记录'),
        body: _loading && _records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _records.isEmpty
                ? Center(
                    child: TextButton(
                      onPressed: () => unawaited(_reload()),
                      child: const Text('加载失败，点击重试'),
                    ),
                  )
                : _records.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无充值记录',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _reload,
                        color: AppColors.primary,
                        child: ListView.builder(
                          controller: _controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _records.length + 1,
                          itemBuilder: (context, index) =>
                              index == _records.length
                                  ? _footer()
                                  : _RecordTile(record: _records[index]),
                        ),
                      ),
      );

  Widget _footer() => _loading
      ? const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      : _hasMore
          ? TextButton(
              onPressed: () => unawaited(_loadMore()),
              child: const Text('加载更多'),
            )
          : const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '没有更多记录',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            );
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final GameRechargeRecord record;
  @override
  Widget build(BuildContext context) => Container(
        height: 70,
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.divider, width: .5)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('充值', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(
                    _time(record.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  (record.amountInCents / 100).toStringAsFixed(2),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  record.statusText,
                  style: TextStyle(
                    color: record.status == 3
                        ? Colors.lightGreen
                        : record.status == 1 || record.status == 2
                            ? Colors.blueAccent
                            : Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

String _time(int epoch) {
  if (epoch <= 0) return '';
  final value = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
