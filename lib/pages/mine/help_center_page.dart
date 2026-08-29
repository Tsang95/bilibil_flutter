import 'dart:async';

import 'package:flutter/material.dart';

import 'package:b_flutter/api/help_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/help_item.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  List<HelpItem> _items = const <HelpItem>[];
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
      final items = await HelpApi.getItems(forceRefresh: forceRefresh);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '帮助中心'),
        body: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _error != null && _items.isEmpty
                ? Center(
                    child: TextButton(
                      onPressed: () => unawaited(_load(forceRefresh: true)),
                      child: const Text('加载失败，点击重试'),
                    ),
                  )
                : _items.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无数据',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => _load(forceRefresh: true),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) =>
                              _HelpTile(item: _items[index]),
                        ),
                      ),
      );
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.item});
  final HelpItem item;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: AppColors.divider, width: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(item.content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
}
