import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'package:b_flutter/api/bootstrap_api.dart';
import 'package:b_flutter/common/app_environment.dart';
import 'package:b_flutter/models/app_config.dart';
import 'package:b_flutter/routes/app_routes.dart';
import 'package:b_flutter/stores/app_config_store.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/stores/user_store.dart';
import 'package:b_flutter/utils/api_client.dart';
import 'package:b_flutter/utils/api_endpoint.dart';
import 'package:b_flutter/utils/logger_util.dart';

enum StartupStatus { idle, connecting, ready, error }

final class StartupController extends GetxController {
  final status = StartupStatus.idle.obs;
  final errorMessage = ''.obs;
  Future<void>? _initialization;

  Future<void> start({bool force = false}) {
    if (!force && _initialization != null) return _initialization!;
    return _initialization = _initialize();
  }

  Future<void> retry() => start(force: true);

  Future<void> _initialize() async {
    status.value = StartupStatus.connecting;
    errorMessage.value = '';
    try {
      await Future.wait(<Future<void>>[
        TokenManager.instance.initialize(),
        AppConfigStore.instance.initialize(),
      ]);

      // The legacy splash page enters home as soon as a saved appConfig exists,
      // then refreshes its line and config in the background.
      if (AppConfigStore.instance.config != null) {
        _enterHome();
        unawaited(_refreshCachedLineAndConfig());
        return;
      }

      await _refreshLineAndConfig();
      _enterHome();
    } catch (error, stackTrace) {
      logger.e('启动初始化失败', error: error, stackTrace: stackTrace);
      status.value = StartupStatus.error;
      errorMessage.value = '线路选择失败，请前往官网';
      EasyLoading.showError(errorMessage.value);
    }
  }

  void _enterHome() {
    status.value = StartupStatus.ready;
    Get.offAllNamed<void>(AppRoutes.home);
    Get.find<UserStore>().restoreSessionInBackground();
  }

  Future<void> _refreshCachedLineAndConfig() async {
    try {
      await _refreshLineAndConfig();
    } catch (error, stackTrace) {
      logger.e('启动线路后台刷新失败', error: error, stackTrace: stackTrace);
      errorMessage.value = '线路选择失败，请前往官网';
      EasyLoading.showError(errorMessage.value);
    }
  }

  Future<void> _refreshLineAndConfig() async {
    EasyLoading.show(maskType: EasyLoadingMaskType.clear);
    try {
      final configuredDomains = <String>{
        if (AppConfigStore.instance.domain.isNotEmpty)
          AppConfigStore.instance.domain,
        ...AppEnvironment.configuredApiDomains,
      }.toList(growable: false);
      if (configuredDomains.isEmpty) {
        throw StateError('API 域名未配置');
      }
      await _selectAvailableDomain(configuredDomains);
    } finally {
      if (EasyLoading.isShow) {
        EasyLoading.dismiss();
      }
    }
  }

  Future<void> _selectAvailableDomain(List<String> seedDomains) async {
    final cachedDomain = AppConfigStore.instance.domain;
    final orderedSeeds = <String>[
      if (cachedDomain.isNotEmpty) cachedDomain,
      ...seedDomains.where((domain) => domain != cachedDomain),
    ];

    Object? lastError;
    for (final seed in orderedSeeds) {
      try {
        ApiClient().configureBaseUrl(ApiEndpoint.normalizeBaseUrl(seed));
        final discoveredDomains = await BootstrapApi.getDomains();
        final candidates = <String>{
          ...discoveredDomains,
          seed,
        }.toList(growable: false);
        final result = await _loadConfigFromCandidates(candidates);
        await AppConfigStore.instance.save(
          domain: result.domain,
          config: result.config,
        );
        return;
      } catch (error) {
        lastError = error;
        logger.w('启动线路不可用: $seed', error: error);
      }
    }
    throw StateError('所有启动线路均不可用: $lastError');
  }

  Future<({String domain, AppConfig config})> _loadConfigFromCandidates(
    List<String> domains,
  ) async {
    Object? lastError;
    for (final domain in domains) {
      try {
        final normalizedDomain = ApiEndpoint.normalizeBaseUrl(domain);
        ApiClient().configureBaseUrl(normalizedDomain);
        final config = await BootstrapApi.getConfig();
        return (domain: normalizedDomain, config: config);
      } catch (error) {
        lastError = error;
        logger.w('配置线路不可用: $domain', error: error);
      }
    }
    throw StateError('配置加载失败: $lastError');
  }
}
