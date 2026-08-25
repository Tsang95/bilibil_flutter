import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/vip_models.dart';

class RechargeHistoryPage extends StatefulWidget {
  const RechargeHistoryPage({super.key});
  @override
  State<RechargeHistoryPage> createState() => _RechargeHistoryPageState();
}

class _RechargeHistoryPageState extends State<RechargeHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  List<RechargeHistoryRecord> _items = const <RechargeHistoryRecord>[];
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(refresh: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 160) unawaited(_load());
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loadingMore || (!refresh && (!_hasMore || _loading))) return;
    final page = refresh ? 1 : _page + 1;
    setState(() {
      if (refresh) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await UserApi.getRechargeHistory(
        page: page,
        forceRefresh: refresh,
      );
      if (mounted) {
        setState(() {
          _page = page;
          _items = refresh
              ? result.items
              : <RechargeHistoryRecord>[..._items, ...result.items];
          _hasMore = result.hasMore;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const LegacyAppBar(title: '充值记录'),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _items.isEmpty
        ? Center(
            child: TextButton(
              onPressed: () => _load(refresh: true),
              child: const Text('加载失败，点击重试'),
            ),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _load(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _items.length + 1,
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: Text('暂无数据')),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        _hasMore ? '' : '没有更多了',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                final item = _items[index];
                return Container(
                  height: 70,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('充值', style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          Text(
                            item.amount.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: <Widget>[
                          Text(
                            item.createdAt,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.isPaid ? '已支付' : '处理中',
                            style: TextStyle(
                              color: item.isPaid
                                  ? AppColors.success
                                  : AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
  );
}
