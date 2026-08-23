import 'dart:async';

import 'package:get/get.dart';

import 'package:b_flutter/api/user_api.dart';
import 'package:b_flutter/models/user_info.dart';
import 'package:b_flutter/models/user_session.dart';
import 'package:b_flutter/stores/token_manager.dart';
import 'package:b_flutter/utils/api_exception.dart';
import 'package:b_flutter/utils/logger_util.dart';
import 'package:b_flutter/utils/request_cache.dart';

final class UserStore extends GetxService {
  final user = Rxn<UserInfo>();

  bool get isLoggedIn => TokenManager.instance.hasToken && user.value != null;

  Future<void> activateSession(UserSession session) async {
    RequestCache.instance.clear();
    await TokenManager.instance.setToken(session.token);
    user.value = session.user;
  }

  Future<void> restoreSession() async {
    if (!TokenManager.instance.hasToken) return;
    try {
      user.value = await UserApi.getCurrentUser();
    } on ApiException catch (error, stackTrace) {
      if (error.type == ApiExceptionType.unauthorized) {
        await logout();
        return;
      }
      logger.w('后台恢复用户资料失败', error: error, stackTrace: stackTrace);
    } catch (error, stackTrace) {
      logger.w('后台恢复用户资料失败', error: error, stackTrace: stackTrace);
    }
  }

  void restoreSessionInBackground() {
    unawaited(restoreSession());
  }

  Future<void> logout() async {
    RequestCache.instance.clear();
    await TokenManager.instance.clear();
    user.value = null;
  }
}
