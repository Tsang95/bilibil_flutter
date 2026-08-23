import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/pages/search/components/search_history_view.dart';
import 'package:b_flutter/pages/search/components/search_posts_view.dart';
import 'package:b_flutter/pages/search/components/search_users_view.dart';
import 'package:b_flutter/stores/search_history_store.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PageController _pageController = PageController();
  List<String> _history = const <String>[];
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    final history = await SearchHistoryStore.instance.getHistory();
    if (mounted) setState(() => _history = history);
  }

  Future<void> _search([String? input]) async {
    final keyword = (input ?? _textController.text).trim();
    if (keyword.isEmpty) {
      showToast('请输入搜索内容', type: ToastType.warning);
      _focusNode.requestFocus();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    _textController
      ..text = keyword
      ..selection = TextSelection.collapsed(offset: keyword.length);
    final history = await SearchHistoryStore.instance.add(keyword);
    if (!mounted) return;
    setState(() {
      _keyword = keyword;
      _history = history;
    });
    await _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _clearHistory() async {
    try {
      await SubmissionFeedback.run<void>(
        action: SearchHistoryStore.instance.clear,
        successMessage: '搜索历史已清空',
        fallbackErrorMessage: '搜索历史清空失败',
        lock: false,
      );
      if (mounted) setState(() => _history = const <String>[]);
    } catch (_) {}
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  SearchHistoryView(
                    history: _history,
                    onSearch: (value) => unawaited(_search(value)),
                    onClear: _clearHistory,
                  ),
                  if (_keyword.isEmpty)
                    const SizedBox.shrink()
                  else
                    _SearchResults(
                      key: ValueKey<String>(_keyword),
                      keyword: _keyword,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            InkResponse(
              onTap: () => Navigator.of(context).maybePop(),
              radius: 22,
              child: const SizedBox.square(
                dimension: 32,
                child: Icon(Icons.chevron_left_rounded, size: 28),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: SizedBox(
                height: 30,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => unawaited(_search(value)),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '请输入关键搜索词',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 9, right: 5),
                      child: SvgPicture.asset(
                        'assets/images/ic_search.svg',
                        width: 14,
                        height: 14,
                      ),
                    ),
                    contentPadding: const EdgeInsets.only(right: 10),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 58,
              height: 28,
              child: FilledButton(
                onPressed: () => unawaited(_search()),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text('搜索', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({super.key, required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 42,
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: TextStyle(fontSize: 13),
              tabs: <Widget>[
                Tab(text: '帖子'),
                Tab(text: '用户'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                SearchPostsView(keyword: keyword),
                SearchUsersView(keyword: keyword),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
