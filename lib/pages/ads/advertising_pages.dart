import 'dart:async';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:b_flutter/api/active_api.dart';
import 'package:b_flutter/api/advertising_api.dart';
import 'package:b_flutter/common/styles.dart';
import 'package:b_flutter/components/legacy_app_bar.dart';
import 'package:b_flutter/components/legacy_network_image.dart';
import 'package:b_flutter/models/advertising_models.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/submission_feedback.dart';
import 'package:b_flutter/utils/toast.dart';

class AdvertisingDashboardPage extends StatefulWidget {
  const AdvertisingDashboardPage({super.key});

  @override
  State<AdvertisingDashboardPage> createState() =>
      _AdvertisingDashboardPageState();
}

class _AdvertisingDashboardPageState extends State<AdvertisingDashboardPage> {
  final ScrollController _scrollController = ScrollController();
  AdvertisingSummary _summary = const AdvertisingSummary(
    successCount: 0,
    pendingCount: 0,
    failedCount: 0,
    expiredCount: 0,
  );
  final List<AdvertisingRecord> _records = <AdvertisingRecord>[];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreWhenNeeded() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 240 ||
        _loadingMore ||
        !_hasMore) {
      return;
    }
    unawaited(_load(page: _page + 1));
  }

  Future<void> _load({int page = 1, bool forceRefresh = false}) async {
    if (page > 1 && (_loadingMore || !_hasMore)) return;
    setState(() {
      if (page == 1) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final dashboard = await AdvertisingApi.getDashboard(
        page: page,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _summary = dashboard.summary;
        if (page == 1) _records.clear();
        _records.addAll(dashboard.records.items);
        _page = page;
        _hasMore = dashboard.records.hasMore;
      });
    } on ApiException catch (error) {
      if (mounted && page == 1) _error = error.message;
    } catch (_) {
      if (mounted && page == 1) _error = '加载失败，请稍后重试';
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
        appBar: const LegacyAppBar(title: '投放广告'),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: TextButton(
                      onPressed: () => unawaited(_load(forceRefresh: true)),
                      child: Text('$_error，点击重试'),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(forceRefresh: true),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: <Widget>[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                          sliver: SliverList.list(
                            children: <Widget>[
                              SizedBox(
                                height: 40,
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Get.toNamed<void>(
                                      AppRoutes.advertisingSubmit),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 15),
                                  label: const Text('广告投放'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '投放必看',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                  children: <InlineSpan>[
                                    TextSpan(
                                        text: '严禁投放幼女、童女、人兽等血腥、恐怖镜头的图片或视频！\n'),
                                    TextSpan(
                                      text: '违规严重',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                    TextSpan(text: '的封号处理，请珍惜你的账号。'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '我的广告',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => Get.toNamed<void>(
                                    AppRoutes.myAdvertisements),
                                borderRadius: BorderRadius.circular(4),
                                child: Ink(
                                  height: 63,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      _SummaryMetric(
                                          '投放成功', _summary.successCount),
                                      _summaryDivider(),
                                      _SummaryMetric(
                                          '待审核', _summary.pendingCount),
                                      _summaryDivider(),
                                      _SummaryMetric(
                                          '已过期', _summary.expiredCount),
                                      _summaryDivider(),
                                      _SummaryMetric(
                                          '审核失败', _summary.failedCount),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '我的广告',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                          child: Center(child: Text('日期'))),
                                      Expanded(
                                          child: Center(child: Text('展示位置'))),
                                      Expanded(
                                          child: Center(child: Text('点击量'))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_records.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                '暂无数据',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            sliver: SliverList.separated(
                              itemCount:
                                  _records.length + (_loadingMore ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const Divider(height: .5),
                              itemBuilder: (context, index) {
                                if (index == _records.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final record = _records[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          record.createdAt,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${_advertisingTypeName(record.type)}-${record.location.name}',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${record.clickCount}',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
      );
}

class AdvertisingSubmitPage extends StatefulWidget {
  const AdvertisingSubmitPage({super.key});

  @override
  State<AdvertisingSubmitPage> createState() => _AdvertisingSubmitPageState();
}

class _AdvertisingSubmitPageState extends State<AdvertisingSubmitPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _urlController = TextEditingController();
  List<AdvertisingPlacement> _placements = const <AdvertisingPlacement>[];
  List<AdvertisingPrice> _prices = const <AdvertisingPrice>[];
  AdvertisingPlacement? _placement;
  AdvertisingPrice? _price;
  XFile? _image;
  String _imageUrl = '';
  bool _loading = true;
  bool _uploading = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlacements());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPlacements({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final placements = await AdvertisingApi.getPlacements(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      _placements = placements;
      _placement = placements.isEmpty ? null : placements.first;
      await _loadPrices();
    } on ApiException catch (error) {
      if (mounted) _error = error.message;
    } catch (_) {
      if (mounted) _error = '加载失败，请稍后重试';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPrices() async {
    final placement = _placement;
    if (placement == null) {
      _prices = const <AdvertisingPrice>[];
      _price = null;
      return;
    }
    try {
      final prices = await AdvertisingApi.getPrices(placementId: placement.id);
      if (!mounted || _placement?.id != placement.id) return;
      _prices = prices;
      _price = prices.isEmpty ? null : prices.first;
    } on ApiException catch (error) {
      if (mounted) showToast(error.message, type: ToastType.error);
    } catch (_) {
      if (mounted) showToast('加载投放时间失败，请稍后重试', type: ToastType.error);
    }
  }

  Future<void> _choosePlacement() async {
    final selection = await _showOptionSheet<AdvertisingPlacement>(
      context: context,
      title: '广告位置',
      items: _placements,
      label: (item) => item.name,
      selected: _placement,
    );
    if (selection == null || selection.id == _placement?.id) return;
    setState(() {
      _placement = selection;
      _price = null;
      _prices = const <AdvertisingPrice>[];
    });
    await _loadPrices();
    if (mounted) setState(() {});
  }

  Future<void> _choosePrice() async {
    final selection = await _showOptionSheet<AdvertisingPrice>(
      context: context,
      title: '投放时间',
      items: _prices,
      label: (item) => '${item.months}个月',
      selected: _price,
    );
    if (selection != null && mounted) setState(() => _price = selection);
  }

  Future<void> _chooseImage() async {
    if (_uploading) return;
    final source = await showModalActionSheet<String>(
      context: context,
      title: '选择',
      actions: const <SheetAction<String>>[
        SheetAction<String>(label: '照片', key: 'photo'),
        SheetAction<String>(label: '拍照', key: 'camera'),
        SheetAction<String>(label: '取消', key: 'cancel'),
      ],
    );
    if (source != 'photo' && source != 'camera') return;
    final image = await _picker.pickImage(
      source: source == 'photo' ? ImageSource.gallery : ImageSource.camera,
    );
    if (image == null || !mounted) return;
    setState(() {
      _image = image;
      _imageUrl = '';
      _uploading = true;
    });
    try {
      final result = await SubmissionFeedback.run(
        action: () =>
            ActiveApi.uploadImage(filePath: image.path, fileName: image.name),
        loadingMessage: '正在上传图片...',
        successMessage: '上传成功',
        fallbackErrorMessage: '图片上传失败，请稍后重试',
      );
      if (result.url.trim().isEmpty) {
        throw const FormatException('Empty image url');
      }
      if (mounted) {
        setState(() => _imageUrl = result.url);
      }
    } catch (_) {
      // SubmissionFeedback has already shown the reason.
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    final placement = _placement;
    final price = _price;
    if (placement == null) {
      showToast('请选择广告位置', type: ToastType.warning);
      return;
    }
    if (price == null) {
      showToast('请选择时间', type: ToastType.warning);
      return;
    }
    if (_image == null || _imageUrl.isEmpty) {
      showToast(_uploading ? '封面图正在上传' : '请上传封面图', type: ToastType.warning);
      return;
    }
    final targetUrl = _urlController.text.trim();
    if (targetUrl.isEmpty) {
      showToast('请上传跳转链接', type: ToastType.warning);
      return;
    }
    final confirmed = await _showPaymentConfirmation(
      context,
      placement: placement,
      price: price,
    );
    if (!confirmed || !mounted || _submitting) return;
    setState(() => _submitting = true);
    try {
      await SubmissionFeedback.run(
        action: () => AdvertisingApi.submit(
          data: <String, Object?>{
            'location_id': placement.id,
            'advertising_location_id': price.months,
            'advertise_image': _imageUrl,
            'jump_url': targetUrl,
          },
        ),
        successMessage: '投放成功',
        fallbackErrorMessage: '投放失败，请稍后重试',
      );
      if (mounted) Get.back<void>();
    } catch (_) {
      // SubmissionFeedback has already shown the reason.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: LegacyAppBar(
          title: '广告投放',
          trailing: SizedBox(
            width: 60,
            height: 28,
            child: ElevatedButton(
              onPressed:
                  _submitting || _uploading ? null : () => unawaited(_submit()),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _submitting ? '投放中' : '投放',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: TextButton(
                      onPressed: () =>
                          unawaited(_loadPlacements(forceRefresh: true)),
                      child: Text('$_error，点击重试'),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _RequiredSelectRow(
                          label: '广告位置：',
                          value: _placement?.name ?? '请选择板块',
                          onTap: _choosePlacement,
                        ),
                        _RequiredSelectRow(
                          label: '投放时间：',
                          value:
                              _price == null ? '请选择时间' : '${_price!.months}个月',
                          onTap: _choosePrice,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                          child: Row(
                            children: <Widget>[
                              const Text(
                                '金额：',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 65),
                              Text(
                                '${_price?.amount ?? 0}金币',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: .5),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(fontSize: 14),
                                    children: <InlineSpan>[
                                      const TextSpan(
                                        text: '*',
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      ),
                                      const TextSpan(text: '封面图'),
                                      TextSpan(
                                        text: _placement?.coverImageTips ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_image != null)
                                TextButton.icon(
                                  onPressed: _uploading
                                      ? null
                                      : () => setState(() {
                                            _image = null;
                                            _imageUrl = '';
                                          }),
                                  icon: const Icon(CupertinoIcons.delete,
                                      size: 14),
                                  label: const Text('删除'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    textStyle: const TextStyle(fontSize: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Center(child: _buildImagePicker()),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(fontSize: 14),
                              children: <InlineSpan>[
                                TextSpan(
                                  text: '*',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                                TextSpan(text: '广告跳转链接'),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                          child: TextField(
                            controller: _urlController,
                            minLines: 1,
                            maxLines: 7,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              hintText: '请输入广告跳转链接',
                              hintStyle:
                                  TextStyle(color: AppColors.textTertiary),
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.divider),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.primary),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
                          child: Text('预览图', style: TextStyle(fontSize: 14)),
                        ),
                        _buildPreview(),
                      ],
                    ),
                  ),
      );

  Widget _buildImagePicker() {
    final size = _displaySize(
      _placement,
      MediaQuery.sizeOf(context).width - 20,
    );
    return InkWell(
      onTap: _chooseImage,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          image: _image == null
              ? null
              : DecorationImage(
                  image: FileImage(File(_image!.path)),
                  fit: BoxFit.cover,
                ),
        ),
        child: _image != null
            ? _uploading
                ? const Center(child: CircularProgressIndicator())
                : null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/images/ic_ads_upload_pic.svg',
                    width: 32,
                    height: 32,
                  ),
                  const Text(
                    '点击上传封面',
                    style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreview() {
    final canvasWidth = MediaQuery.sizeOf(context).width - 20;
    final imageSize = _displaySize(_placement, canvasWidth);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: canvasWidth,
      height: 800,
      color: AppColors.surfaceMuted,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LegacyNetworkImage(
              url: _placement?.previewImage ?? '',
              fit: BoxFit.fill,
            ),
          ),
          if (_image != null)
            Positioned(
              top: _previewTop(_placement),
              left: _placement?.id == 4 ? 10 : 0,
              child: SizedBox(
                width: imageSize.width,
                height: imageSize.height,
                child: Image.file(File(_image!.path), fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}

class MyAdvertisementsPage extends StatelessWidget {
  const MyAdvertisementsPage({super.key});

  @override
  Widget build(BuildContext context) => const DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: LegacyAppBar(title: '我的广告'),
          body: Column(
            children: <Widget>[
              SizedBox(
                height: 40,
                child: TabBar(
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelColor: AppColors.primary,
                  labelStyle:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelColor: AppColors.textPrimary,
                  unselectedLabelStyle: TextStyle(fontSize: 14),
                  tabs: <Tab>[
                    Tab(text: '投放成功'),
                    Tab(text: '待审核'),
                    Tab(text: '已过期'),
                    Tab(text: '审核失败'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _AdvertisingRecordsTab(status: 1),
                    _AdvertisingRecordsTab(status: 0),
                    _AdvertisingRecordsTab(status: 2),
                    _AdvertisingRecordsTab(status: -1),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _AdvertisingRecordsTab extends StatefulWidget {
  const _AdvertisingRecordsTab({required this.status});

  final int status;

  @override
  State<_AdvertisingRecordsTab> createState() => _AdvertisingRecordsTabState();
}

class _AdvertisingRecordsTabState extends State<_AdvertisingRecordsTab>
    with AutomaticKeepAliveClientMixin<_AdvertisingRecordsTab> {
  final ScrollController _scrollController = ScrollController();
  final List<AdvertisingRecord> _records = <AdvertisingRecord>[];
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNeeded);
    unawaited(_load());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreWhenNeeded() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter <= 240 &&
        _hasMore &&
        !_loadingMore) {
      unawaited(_load(page: _page + 1));
    }
  }

  Future<void> _load({int page = 1, bool forceRefresh = false}) async {
    if (page > 1 && (_loadingMore || !_hasMore)) return;
    setState(() {
      if (page == 1) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await AdvertisingApi.getMyAdvertisements(
        status: widget.status,
        page: page,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        if (page == 1) _records.clear();
        _records.addAll(result.items);
        _page = page;
        _hasMore = result.hasMore;
      });
    } on ApiException catch (error) {
      if (mounted && page == 1) _error = error.message;
    } catch (_) {
      if (mounted && page == 1) _error = '加载失败，请稍后重试';
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
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TextButton(
          onPressed: () => unawaited(_load(forceRefresh: true)),
          child: Text('$_error，点击重试'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: _records.isEmpty
          ? ListView(
              children: const <Widget>[
                SizedBox(height: 180),
                Center(
                  child: Text(
                    '暂无数据',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _records.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => index == _records.length
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _AdvertisingRecordCard(record: _records[index]),
            ),
    );
  }
}

class _AdvertisingRecordCard extends StatelessWidget {
  const _AdvertisingRecordCard({required this.record});

  final AdvertisingRecord record;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: <Widget>[
            if (record.status == 1)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                color: AppColors.primary.withOpacity(.1),
                alignment: Alignment.center,
                child: Row(
                  children: <Widget>[
                    const Text('广告到期时间：', style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text(record.deadlineAt,
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            _RecordDetailRow(
              label: '广告位置',
              value: record.location.name.isEmpty
                  ? record.location.nickname
                  : record.location.name,
            ),
            const SizedBox(height: 15),
            _RecordDetailRow(
                label: '投放时间', value: '${record.durationMonths}个月'),
            const SizedBox(height: 15),
            _RecordDetailRow(label: '广告跳转链接', value: record.targetUrl),
            const SizedBox(height: 15),
            SizedBox(
              width: 180,
              height: 170,
              child: LegacyNetworkImage(
                url: record.imageUrl,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _advertisingStatusName(record.status),
                style: TextStyle(
                  fontSize: 12,
                  color: _advertisingStatusColor(record.status),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: .5),
          ],
        ),
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric(this.label, this.count);

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$count',
              style: const TextStyle(color: AppColors.primary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
}

class _RequiredSelectRow extends StatelessWidget {
  const _RequiredSelectRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.only(left: 20, right: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: <Widget>[
              const Text(
                '*',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const Icon(
                CupertinoIcons.right_chevron,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      );
}

class _RecordDetailRow extends StatelessWidget {
  const _RecordDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
}

Widget _summaryDivider() =>
    Container(width: 1, height: 38, color: AppColors.divider);

String _advertisingTypeName(int type) => switch (type) {
      1 => '平台广告',
      2 => '板块广告',
      _ => 'UP主广告',
    };

String _advertisingStatusName(int status) => switch (status) {
      1 => '投放成功',
      0 => '待审核',
      2 => '已过期',
      _ => '审核失败',
    };

Color _advertisingStatusColor(int status) => switch (status) {
      1 => Colors.redAccent,
      0 => Colors.lightBlueAccent,
      2 => AppColors.textSecondary,
      _ => Colors.red,
    };

Size _displaySize(AdvertisingPlacement? placement, double canvasWidth) {
  switch (placement?.id) {
    case 4:
      return const Size(165, 98);
    case 3:
      return Size(canvasWidth, 80);
    case 1:
    default:
      return Size(canvasWidth, 165);
  }
}

double _previewTop(AdvertisingPlacement? placement) => switch (placement?.id) {
      1 => 137,
      3 => 398,
      4 => 415,
      _ => 0,
    };

Future<T?> _showOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) label,
  required T? selected,
}) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: 310,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(title, style: const TextStyle(fontSize: 14)),
              ),
              const Divider(height: .5),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: .5),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Center(
                        child: Text(
                          label(item),
                          style: TextStyle(
                            fontSize: 14,
                            color: identical(item, selected)
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

Future<bool> _showPaymentConfirmation(
  BuildContext context, {
  required AdvertisingPlacement placement,
  required AdvertisingPrice price,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 320,
          height: 290,
          child: Column(
            children: <Widget>[
              Container(
                height: 40,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: const Text(
                  '提示',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 28),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  children: <InlineSpan>[
                    const TextSpan(text: '确认支付'),
                    TextSpan(
                      text: '${price.amount}',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    const TextSpan(text: '金币发布广告'),
                  ],
                ),
              ),
              Container(
                height: 85,
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(15, 20, 15, 0),
                padding: const EdgeInsets.all(15),
                color: AppColors.primary.withOpacity(.1),
                child: Column(
                  children: <Widget>[
                    _RecordDetailRow(label: '广告位置', value: placement.name),
                    const Spacer(),
                    _RecordDetailRow(label: '投放时间', value: '${price.months}个月'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFFAAAAAA),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('确定'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;
