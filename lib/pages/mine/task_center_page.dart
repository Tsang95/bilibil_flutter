import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/task_models.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/toast.dart';

/// Legacy daily-sign-in and task centre.
class TaskCenterPage extends StatefulWidget {
  const TaskCenterPage({super.key});

  @override
  State<TaskCenterPage> createState() => _TaskCenterPageState();
}

class _TaskCenterPageState extends State<TaskCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  DailyTaskSummary? _summary;
  List<TaskItem>? _dailyTasks;
  List<TaskItem>? _permanentTasks;
  Object? _error;
  bool _signing = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        UserApi.getDailyTaskSummary(),
        UserApi.getTasks(type: 1),
        UserApi.getTasks(type: 0),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as DailyTaskSummary;
        _dailyTasks = results[1] as List<TaskItem>;
        _permanentTasks = results[2] as List<TaskItem>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _sign() async {
    final reward = _summary?.todayReward;
    if (_signing || _summary?.isSigned == true || reward == null) return;
    setState(() => _signing = true);
    try {
      await UserApi.signDailyTask(rewardId: reward.id);
      showToast('签到成功', type: ToastType.success);
      await _load();
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  void _completeTask(TaskItem task) {
    if (task.isComplete) return;
    switch (task.id) {
      // The legacy destinations are retained as distinct task types. They are
      // made reachable when their corresponding modules finish migration.
      case 6:
      case 7:
      case 9:
        showToast('相关功能正在重构中', type: ToastType.info);
        return;
      default:
        Get.offAllNamed<void>(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading =
        _summary == null || _dailyTasks == null || _permanentTasks == null;
    return Scaffold(
      appBar: const LegacyAppBar(title: '任务中心'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: loading
            ? _TaskState(error: _error, onRetry: _load)
            : Column(
                children: <Widget>[
                  _SignHeader(
                    summary: _summary!,
                    signing: _signing,
                    onSign: _sign,
                  ),
                  TabBar(
                    controller: _tabs,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textPrimary,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const <Tab>[
                      Tab(text: '每日任务'),
                      Tab(text: '永久任务'),
                    ],
                  ),
                  const Divider(height: .5),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: <Widget>[
                        _TaskList(tasks: _dailyTasks!, onTap: _completeTask),
                        _TaskList(
                          tasks: _permanentTasks!,
                          onTap: _completeTask,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SignHeader extends StatelessWidget {
  const _SignHeader({
    required this.summary,
    required this.signing,
    required this.onSign,
  });

  final DailyTaskSummary summary;
  final bool signing;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) => Container(
    height: 240,
    padding: const EdgeInsets.fromLTRB(10, 22, 10, 0),
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/v1/task_page_bg.png'),
        fit: BoxFit.fill,
        alignment: Alignment.topCenter,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '每日签到任务',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 21),
        GestureDetector(
          onTap: summary.isSigned || signing ? null : onSign,
          child: Container(
            width: 142,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  summary.isSigned
                      ? 'assets/images/v1/task_sign_un.png'
                      : 'assets/images/v1/task_sign_en.png',
                ),
                fit: BoxFit.fill,
              ),
            ),
            child: Text(
              summary.isSigned ? '已签到' : '立即签到',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: ColoredBox(
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                itemCount: summary.rewards.length,
                itemBuilder: (context, index) =>
                    _SignRewardCard(reward: summary.rewards[index]),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SignRewardCard extends StatelessWidget {
  const _SignRewardCard({required this.reward});
  final TaskSignReward reward;

  @override
  Widget build(BuildContext context) => Container(
    width: 110,
    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: LinearGradient(
        colors: reward.isSigned
            ? const <Color>[Color(0xFFFFAAA9), Color(0xFFFF5D90)]
            : const <Color>[Color(0xFFF0F0F0), Color(0xFFF0F0F0)],
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          reward.day,
          style: TextStyle(
            color: reward.isSigned ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/v1/ic_task_tag.png',
              width: 24,
              height: 20,
            ),
            Text(
              reward.name,
              style: TextStyle(
                fontSize: 14,
                color: reward.isSigned ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          reward.tips,
          style: TextStyle(
            color: reward.isSigned ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.onTap});
  final List<TaskItem> tasks;
  final ValueChanged<TaskItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('暂无任务', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const Divider(height: .5),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final completed = task.isComplete;
        return SizedBox(
          height: 63,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Text(
                          task.rule,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: task.isActionable ? () => onTap(task) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: completed
                          ? AppColors.inputBackground
                          : AppColors.primary,
                    ),
                    child: Text(
                      completed
                          ? '已完成'
                          : task.canComplete
                          ? '去完成'
                          : '未完成',
                      style: TextStyle(
                        fontSize: 14,
                        color: completed
                            ? AppColors.textSecondary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskState extends StatelessWidget {
  const _TaskState({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: <Widget>[
      const SizedBox(height: 220),
      Center(
        child: error == null
            ? const CircularProgressIndicator(color: AppColors.primary)
            : TextButton(onPressed: onRetry, child: const Text('加载失败，点击重试')),
      ),
    ],
  );
}
