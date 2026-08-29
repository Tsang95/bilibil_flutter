import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:b_flutter/api/creator_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/models/creator_data_center_models.dart';

typedef CreatorDataReportLoader = Future<CreatorDataReport> Function(
    {required int type, bool forceRefresh});
typedef CreatorDataChartLoader = Future<List<CreatorChartPoint>> Function({
  required int kind,
  bool forceRefresh,
});

class CreatorDataCenterPage extends StatefulWidget {
  const CreatorDataCenterPage({
    super.key,
    this.reportLoader = CreatorApi.getDataReport,
    this.chartLoader = CreatorApi.getDataChart,
  });

  final CreatorDataReportLoader reportLoader;
  final CreatorDataChartLoader chartLoader;

  @override
  State<CreatorDataCenterPage> createState() => _CreatorDataCenterPageState();
}

class _CreatorDataCenterPageState extends State<CreatorDataCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const LegacyAppBar(title: '数据中心'),
        body: Column(
          children: <Widget>[
            SizedBox(
              height: 40,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                dividerColor: AppColors.divider,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textPrimary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs: const <Tab>[
                  Tab(text: '数据概览'),
                  Tab(text: '创作收益'),
                  Tab(text: '粉丝分析'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  _DataOverviewPage(
                    reportLoader: widget.reportLoader,
                    chartLoader: widget.chartLoader,
                  ),
                  _DataEarningsPage(chartLoader: widget.chartLoader),
                  _FansAnalysisPage(
                    reportLoader: widget.reportLoader,
                    chartLoader: widget.chartLoader,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DataOverviewPage extends StatefulWidget {
  const _DataOverviewPage({
    required this.reportLoader,
    required this.chartLoader,
  });

  final CreatorDataReportLoader reportLoader;
  final CreatorDataChartLoader chartLoader;

  @override
  State<_DataOverviewPage> createState() => _DataOverviewPageState();
}

class _DataOverviewPageState extends State<_DataOverviewPage>
    with AutomaticKeepAliveClientMixin<_DataOverviewPage> {
  CreatorDataReport? _report;
  List<CreatorChartPoint> _chart = const <CreatorChartPoint>[];
  Object? _error;
  bool _loading = true;
  int _metric = 1;
  int _dateFilter = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _error = null;
        if (_report == null) _loading = true;
      });
    }
    try {
      final values = await Future.wait<Object>(<Future<Object>>[
        widget.reportLoader(type: _dateFilter, forceRefresh: forceRefresh),
        widget.chartLoader(kind: _metric, forceRefresh: forceRefresh),
      ]);
      if (!mounted) return;
      setState(() {
        _report = values[0] as CreatorDataReport;
        _chart = values[1] as List<CreatorChartPoint>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectMetric(int metric) async {
    if (_metric == metric) return;
    setState(() => _metric = metric);
    try {
      final chart = await widget.chartLoader(kind: metric, forceRefresh: true);
      if (mounted && _metric == metric) setState(() => _chart = chart);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _report == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _report == null) {
      return _RetryView(onRetry: () => _load(forceRefresh: true));
    }
    final report = _report ?? _emptyReport;
    final statistics = <(String, int)>[
      ('点赞', report.praiseCount),
      ('收藏', report.collectCount),
      ('投币', report.coinCount),
      ('评论', report.commentCount),
      ('弹幕', report.barrageCount),
    ];
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        key: const PageStorageKey<String>('creator_data_overview'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        children: <Widget>[
          const SizedBox(height: 20),
          _TimeDatePicker(
            name: '流量数据',
            hint: '中午12点更新',
            onSelected: (index) {
              setState(() => _dateFilter = index);
              unawaited(_load(forceRefresh: true));
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _MetricCard(
                    name: '播放量',
                    value: report.totalPlayCount,
                    selected: _metric == 1,
                    onTap: () => _selectMetric(1),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MetricCard(
                    name: '空间访客',
                    value: report.visitorCount,
                    selected: _metric == 2,
                    onTap: () => _selectMetric(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MetricCard(
                    name: '净增粉丝',
                    value: report.fanIncreaseCount,
                    selected: _metric == 3,
                    onTap: () => _selectMetric(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ChartPanel(points: _chart),
          const _SectionDivider(),
          const SizedBox(height: 20),
          const _TimeDatePicker(name: '流量数据', hint: '中午12点更新'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: statistics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 114 / 64,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  statistics[index].$1,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _compactCount(statistics[index].$2),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataEarningsPage extends StatefulWidget {
  const _DataEarningsPage({required this.chartLoader});

  final CreatorDataChartLoader chartLoader;

  @override
  State<_DataEarningsPage> createState() => _DataEarningsPageState();
}

class _DataEarningsPageState extends State<_DataEarningsPage>
    with AutomaticKeepAliveClientMixin<_DataEarningsPage> {
  List<CreatorChartPoint> _chart = const <CreatorChartPoint>[];
  Object? _error;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (mounted) setState(() => _error = null);
    try {
      final chart = await widget.chartLoader(
        kind: 6,
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() => _chart = chart);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _chart.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _chart.isEmpty) {
      return _RetryView(onRetry: () => _load(forceRefresh: true));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        key: const PageStorageKey<String>('creator_data_earnings'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 20),
          _TimeDatePicker(
            name: '流量数据',
            hint: '中午12点更新',
            onSelected: (_) => unawaited(_load(forceRefresh: true)),
          ),
          const SizedBox(height: 20),
          _ChartPanel(points: _chart),
          const _SectionDivider(),
        ],
      ),
    );
  }
}

class _FansAnalysisPage extends StatefulWidget {
  const _FansAnalysisPage({
    required this.reportLoader,
    required this.chartLoader,
  });

  final CreatorDataReportLoader reportLoader;
  final CreatorDataChartLoader chartLoader;

  @override
  State<_FansAnalysisPage> createState() => _FansAnalysisPageState();
}

class _FansAnalysisPageState extends State<_FansAnalysisPage>
    with AutomaticKeepAliveClientMixin<_FansAnalysisPage> {
  CreatorDataReport? _report;
  List<CreatorChartPoint> _chart = const <CreatorChartPoint>[];
  Object? _error;
  bool _loading = true;
  int _metric = 4;
  int _dateFilter = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (mounted) setState(() => _error = null);
    try {
      final values = await Future.wait<Object>(<Future<Object>>[
        widget.reportLoader(type: _dateFilter, forceRefresh: forceRefresh),
        widget.chartLoader(kind: _metric, forceRefresh: forceRefresh),
      ]);
      if (!mounted) return;
      setState(() {
        _report = values[0] as CreatorDataReport;
        _chart = values[1] as List<CreatorChartPoint>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectMetric(int metric) async {
    if (_metric == metric) return;
    setState(() => _metric = metric);
    try {
      final chart = await widget.chartLoader(kind: metric, forceRefresh: true);
      if (mounted && _metric == metric) setState(() => _chart = chart);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _report == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _report == null) {
      return _RetryView(onRetry: () => _load(forceRefresh: true));
    }
    final report = _report ?? _emptyReport;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        key: const PageStorageKey<String>('creator_data_fans'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 20),
          _TimeDatePicker(
            name: '粉丝变化',
            hint: '中午12点更新',
            onSelected: (index) {
              setState(() => _dateFilter = index);
              unawaited(_load(forceRefresh: true));
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _MetricCard(
                    name: '新增关注',
                    value: report.newFanCount,
                    selected: _metric == 4,
                    onTap: () => _selectMetric(4),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MetricCard(
                    name: '取消关注',
                    value: report.lostFanCount,
                    selected: _metric == 5,
                    onTap: () => _selectMetric(5),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MetricCard(
                    name: '粉丝总数',
                    value: report.totalFanCount,
                    selected: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ChartPanel(points: _chart),
          const _SectionDivider(),
        ],
      ),
    );
  }
}

class _TimeDatePicker extends StatefulWidget {
  const _TimeDatePicker({
    required this.name,
    required this.hint,
    this.onSelected,
  });

  final String name;
  final String hint;
  final ValueChanged<int>? onSelected;

  @override
  State<_TimeDatePicker> createState() => _TimeDatePickerState();
}

class _TimeDatePickerState extends State<_TimeDatePicker> {
  static const _labels = <String>['昨日', '近7天', '近30天', '近90天', '累计'];
  int _selected = 0;

  Future<void> _showPicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _labels.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 10, endIndent: 10),
            itemBuilder: (context, index) => InkWell(
              onTap: () => Navigator.of(context).pop(index),
              child: SizedBox(
                height: 41,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: <Widget>[
                      Text(
                        _labels[index],
                        style: TextStyle(
                          color: index == _selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (index == _selected)
                        const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: AppColors.primary,
                          size: 14,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null || selected == _selected) return;
    setState(() => _selected = selected);
    widget.onSelected?.call(selected);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Text(
              widget.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              widget.hint,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Spacer(),
            if (widget.onSelected != null)
              InkWell(
                onTap: _showPicker,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: <Widget>[
                      Text(
                        _labels[_selected],
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(CupertinoIcons.chevron_down, size: 14),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.name,
    required this.value,
    required this.selected,
    this.onTap,
  });

  final String name;
  final int value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color:
            selected ? AppColors.primary.withAlpha(60) : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('$value', style: const TextStyle(fontSize: 18)),
                  ],
                ),
                if (selected)
                  const Positioned(
                    top: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                      ),
                      child: SizedBox(width: 20, height: 4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.points});

  final List<CreatorChartPoint> points;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 180,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: points.isEmpty
              ? const Center(
                  child: Text(
                    '暂无数据',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                )
              : _DataLineChart(points: points),
        ),
      );
}

class _DataLineChart extends StatelessWidget {
  const _DataLineChart({required this.points});

  final List<CreatorChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final minValue = points.map((point) => point.value).reduce(math.min);
    final maxValue = points.map((point) => point.value).reduce(math.max);
    final minY = minValue.toDouble();
    final maxY = maxValue == minValue
        ? minY + math.max(5, maxValue.abs() * .1)
        : maxValue.toDouble();
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primary,
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    '${points[spot.x.toInt()].date}\n数量：'
                    '${_compactCount(points[spot.x.toInt()].value)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                .toList(growable: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 2,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final label = index >= 0 && index < points.length
                    ? points[index].date
                    : '';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, _) => value % 1000 == 0
                  ? Text(
                      _compactCount(value.toInt()),
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        minX: 0,
        maxX: math.max(1, points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: <FlSpot>[
              for (var index = 0; index < points.length; index++)
                FlSpot(index.toDouble(), points[index].value.toDouble()),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.primary.withAlpha(50),
                  AppColors.primary.withAlpha(100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 10,
        child: ColoredBox(color: AppColors.surfaceMuted),
      );
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(onPressed: onRetry, child: const Text('加载失败，点击重试')),
      );
}

const _emptyReport = CreatorDataReport(
  totalPlayCount: 0,
  visitorCount: 0,
  totalFanCount: 0,
  fanIncreaseCount: 0,
  newFanCount: 0,
  lostFanCount: 0,
  praiseCount: 0,
  collectCount: 0,
  coinCount: 0,
  commentCount: 0,
  barrageCount: 0,
  goldCount: 0,
);

String _compactCount(int value) {
  if (value < 10000) return '$value';
  final compact = value / 10000;
  return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}万';
}
