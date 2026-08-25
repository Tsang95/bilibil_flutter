import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/vip_models.dart';
import 'package:b_flutter/utils/toast.dart';

class WithdrawHistoryPage extends StatefulWidget {
  const WithdrawHistoryPage({super.key});

  @override
  State<WithdrawHistoryPage> createState() => _WithdrawHistoryPageState();
}

class _WithdrawHistoryPageState extends State<WithdrawHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  List<WithdrawRecord> _records = const <WithdrawRecord>[];
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
      final result = await UserApi.getWithdrawHistory(
        page: page,
        forceRefresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _records = refresh
            ? result.items
            : <WithdrawRecord>[..._records, ...result.items];
        _hasMore = result.hasMore;
      });
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
    appBar: const LegacyAppBar(title: '提现记录'),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _records.isEmpty
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
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _records.length + 1,
              itemBuilder: (context, index) {
                if (index == _records.length) {
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (_records.isEmpty) {
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
                return _WithdrawRecordCard(record: _records[index]);
              },
            ),
          ),
  );
}

class _WithdrawRecordCard extends StatelessWidget {
  const _WithdrawRecordCard({required this.record});

  final WithdrawRecord record;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: AppColors.surfaceMuted,
    ),
    child: Column(
      children: <Widget>[
        _RecordRow(label: '提现金币：', value: '${record.goldAmount}', bold: true),
        const SizedBox(height: 10),
        _RecordRow(
          label: '到手金额：',
          value: record.actualAmount.toStringAsFixed(2),
          bold: true,
        ),
        const SizedBox(height: 10),
        _RecordRow(
          label: '到手USDT：',
          value: record.actualCoin.toStringAsFixed(0),
          bold: true,
        ),
        const SizedBox(height: 10),
        _RecordRow(label: '汇率：', value: record.exchangeRate.toStringAsFixed(1)),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const Text('提现地址：', style: TextStyle(fontSize: 14)),
            const Spacer(),
            Flexible(
              child: Text(
                record.coinAddress,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () async {
                await Clipboard.setData(
                  ClipboardData(text: record.coinAddress),
                );
                showToast('复制成功', type: ToastType.success);
              },
              child: const Icon(Icons.copy, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RecordRow(label: '提现链：', value: record.linkType.label),
        const SizedBox(height: 10),
        _RecordRow(label: '时间：', value: record.updatedAt),
        const SizedBox(height: 10),
        _RecordRow(
          label: '提现状态：',
          value: record.status.label,
          valueColor: _statusColor(record.status),
        ),
        const SizedBox(height: 10),
        _RecordRow(label: '备注：', value: record.notes),
      ],
    ),
  );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: valueColor,
          ),
        ),
      ),
    ],
  );
}

Color _statusColor(WithdrawStatus status) => switch (status) {
  WithdrawStatus.processing => Colors.blueAccent,
  WithdrawStatus.success => Colors.greenAccent,
  WithdrawStatus.failed => Colors.redAccent,
};
